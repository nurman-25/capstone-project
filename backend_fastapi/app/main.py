import io
import json
import csv
from datetime import date, datetime
from pathlib import Path

import torch
import torchvision
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from PIL import Image
from sqlalchemy import func
from torchvision.transforms import functional as F
from torchvision.ops import nms

from .database import Base, SessionLocal, engine
from .models import AuditResult, AuditSession, DetectionLog, Product, StockReport, Store, User
from .routers.auth import router as auth_router

app = FastAPI(title="Inventory Audit API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

def _ensure_user_email_column():
    from sqlalchemy import text
    with engine.connect() as conn:
        try:
            result = conn.execute(text("SHOW COLUMNS FROM users LIKE 'email'"))
            if not result.fetchone():
                conn.execute(text("ALTER TABLE users ADD COLUMN email VARCHAR(120) NULL"))
                conn.commit()
                print("[DATABASE] Column 'email' added to 'users' table successfully.")
            else:
                print("[DATABASE] Column 'email' already exists in 'users' table.")
        except Exception as e:
            print(f"[DATABASE] Error ensuring email column: {e}")

Base.metadata.create_all(bind=engine)
_ensure_user_email_column()
app.include_router(auth_router)

BASE_DIR = Path(__file__).resolve().parents[2]
MODEL_DIR_CANDIDATES = [
    BASE_DIR / "model_bahan_real_specific",
    BASE_DIR / "model_fasterrcnn_specific",
    BASE_DIR / "model_fasterrcnn_fixed",
    BASE_DIR / "model_fasterrcnn",
]
MODEL_DIR = next((p for p in MODEL_DIR_CANDIDATES if (p / "best_fasterrcnn.pth").exists() and (p / "classes.json").exists()), MODEL_DIR_CANDIDATES[-1])
MODEL_PATH = MODEL_DIR / "best_fasterrcnn.pth"
CLASSES_PATH = MODEL_DIR / "classes.json"

SCORE_THR = 0.35
NMS_IOU_THR = 0.40
MAX_DETECTIONS = 100
MIN_BOX_AREA_RATIO = 0.001
IGNORED_DETECTION_LABELS: set[str] = set()

CONF_HIGH = 0.80
CONF_MEDIUM = 0.50


def build_model(num_classes: int):
    model = torchvision.models.detection.fasterrcnn_resnet50_fpn(weights=None, box_score_thresh=SCORE_THR)
    in_features = model.roi_heads.box_predictor.cls_score.in_features
    model.roi_heads.box_predictor = torchvision.models.detection.faster_rcnn.FastRCNNPredictor(
        in_features, num_classes
    )
    return model


def load_classes(classes_path: Path) -> dict[int, str]:
    data = json.loads(classes_path.read_text(encoding="utf-8"))
    return {int(k): v for k, v in data.items()}


def is_image_upload(file: UploadFile) -> bool:
    content_type = (file.content_type or "").lower()
    if content_type.startswith("image/"):
        return True
    suffix = Path(file.filename or "").suffix.lower()
    return suffix in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


model = None
idx_to_class: dict[int, str] = {}
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

if MODEL_PATH.exists() and CLASSES_PATH.exists():
    idx_to_class = load_classes(CLASSES_PATH)
    num_classes = max(idx_to_class.keys()) + 1
    model = build_model(num_classes)
    ckpt = torch.load(MODEL_PATH, map_location=device)
    model.load_state_dict(ckpt["model_state_dict"])
    model.to(device).eval()
    print(f"[OK] Model loaded: {MODEL_PATH.name} | {num_classes} classes | device={device}")
    print(f"[OK] Classes: {list(idx_to_class.values())}")
else:
    print("[WARN] Model NOT loaded. Check paths:")
    print(f"  MODEL_PATH = {MODEL_PATH} (exists={MODEL_PATH.exists()})")
    print(f"  CLASSES_PATH = {CLASSES_PATH} (exists={CLASSES_PATH.exists()})")


class DashboardOut(BaseModel):
    total_products: int
    total_users: int
    total_audits: int
    audits_today: int
    low_stock: int
    latest_session_date: str
    latest_user: str


class TrendPointOut(BaseModel):
    date: str
    count: int


class AuditSaveIn(BaseModel):
    user_id: int | None = None
    store_id: int | None = None
    session_date: str | None = None
    image_path: str = ""
    algorithm_used: str = "fasterrcnn_resnet50_fpn"
    status: str = "AMAN"
    notes: str = ""
    raw_json: dict | list | None = None


class AuditSaveOut(BaseModel):
    ok: bool
    session_id: int
    result_count: int
    detection_count: int


class AdminProductOut(BaseModel):
    id: int
    sku: str
    name: str
    category: str
    description: str
    image_url: str


class AdminUserOut(BaseModel):
    id: int
    username: str
    role: str
    store_id: int
    email: str | None = None


class AdminSessionDetailOut(BaseModel):
    session_id: int
    date: str
    store_id: int
    user_id: int
    user_name: str
    status: str
    notes: str
    items: list[dict]


class ProductUpdateIn(BaseModel):
    sku: str
    name: str
    category: str
    description: str = ""
    image_url: str = ""


class ReportSummaryOut(BaseModel):
    total_aman: int
    total_tidak_aman: int
    total_sessions: int


class StoreOut(BaseModel):
    id: int
    name: str
    address: str
    phone: str


class StoreIn(BaseModel):
    name: str
    address: str = ""
    phone: str = ""


@app.get("/health")
def health():
    return {
        "ok": True,
        "model_loaded": model is not None,
        "device": str(device),
        "num_classes": len(idx_to_class),
    }


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    if model is None:
        raise HTTPException(
            status_code=503,
            detail="Model belum dimuat. Pastikan file .pth dan .json ada di model_fasterrcnn/",
        )
    if not is_image_upload(file):
        raise HTTPException(status_code=400, detail="File harus berupa image.")

    content = await file.read()
    image = Image.open(io.BytesIO(content)).convert("RGB")
    width, height = image.size
    tensor = F.to_tensor(image).to(device)

    with torch.inference_mode():
        pred = model([tensor])[0]

    boxes = pred["boxes"]
    labels = pred["labels"]
    scores = pred["scores"]

    keep_fg = labels > 0
    boxes = boxes[keep_fg]
    labels = labels[keep_fg]
    scores = scores[keep_fg]

    if len(boxes) > 0:
        image_area = float(width * height)
        box_areas = (boxes[:, 2] - boxes[:, 0]) * (boxes[:, 3] - boxes[:, 1])
        min_area = image_area * MIN_BOX_AREA_RATIO
        keep_area = box_areas >= min_area
        boxes = boxes[keep_area]
        labels = labels[keep_area]
        scores = scores[keep_area]

    if len(boxes) > 0:
        keep_nms = nms(boxes, scores, NMS_IOU_THR)
        boxes = boxes[keep_nms]
        labels = labels[keep_nms]
        scores = scores[keep_nms]

    boxes_list = boxes.cpu().tolist()
    labels_list = labels.cpu().tolist()
    scores_list = scores.cpu().tolist()

    detections = []
    for box, label, score in sorted(
        zip(boxes_list, labels_list, scores_list),
        key=lambda x: x[2],
        reverse=True,
    ):
        class_name = idx_to_class.get(int(label), f"class_{label}")
        if class_name == "__background__" or class_name in IGNORED_DETECTION_LABELS:
            continue
        if score < SCORE_THR:
            continue
            
        if score >= CONF_HIGH:
            tier = "high"
        elif score >= CONF_MEDIUM:
            tier = "medium"
        else:
            tier = "low"

        detections.append(
            {
                "label": class_name,
                "score": round(float(score), 4),
                "bbox_xyxy": [round(float(x), 1) for x in box],
                "confidence_tier": tier,
                "is_valid": True,
            }
        )

    detections = detections[:MAX_DETECTIONS]

    if len(detections) == 0:
        quality = "NO_DETECTION"
    elif sum(1 for d in detections if d["confidence_tier"] == "high") >= max(len(detections) * 0.5, 1):
        quality = "GOOD"
    else:
        quality = "NEEDS_REVIEW"

    print(f"[PREDICT] {file.filename} ({width}x{height}) -> {len(detections)} detections (quality={quality})")

    return {
        "detections": detections,
        "image_width": width,
        "image_height": height,
        "quality": quality,
        "threshold": SCORE_THR,
        "count": len(detections),
    }


@app.get("/dashboard", response_model=DashboardOut)
def dashboard():
    db = SessionLocal()
    try:
        today = date.today()
        total_products = db.query(AuditResult).count()
        total_users = db.query(User).count()
        total_audits = db.query(AuditSession).count()
        audits_today = db.query(AuditSession).filter(AuditSession.session_date == today).count()
        low_stock = db.query(StockReport).filter(StockReport.shortage_flag == 1).count()
        latest = (
            db.query(AuditSession, User.username)
            .join(User, User.id == AuditSession.user_id)
            .order_by(AuditSession.session_date.desc(), AuditSession.id.desc())
            .first()
        )
        latest_session_date = latest[0].session_date.strftime("%d %b %Y") if latest else "-"
        latest_user = latest[1] if latest else "-"
        return {
            "total_products": total_products,
            "total_users": total_users,
            "total_audits": total_audits,
            "audits_today": audits_today,
            "low_stock": low_stock,
            "latest_session_date": latest_session_date,
            "latest_user": latest_user,
        }
    except Exception:
        return {
            "total_products": 0,
            "total_users": 0,
            "total_audits": 0,
            "audits_today": 0,
            "low_stock": 0,
            "latest_session_date": "-",
            "latest_user": "-",
        }
    finally:
        db.close()


@app.get("/dashboard/trend", response_model=list[TrendPointOut])
def dashboard_trend():
    db = SessionLocal()
    try:
        rows = (
            db.query(AuditSession.session_date, func.count(AuditSession.id))
            .group_by(AuditSession.session_date)
            .order_by(AuditSession.session_date.desc())
            .limit(7)
            .all()
        )
        rows = list(reversed(rows))
        return [{"date": row[0].strftime("%d %b"), "count": int(row[1])} for row in rows]
    finally:
        db.close()


@app.get("/history")
def history():
    db = SessionLocal()
    try:
        sessions = (
            db.query(AuditSession)
            .order_by(AuditSession.session_date.desc(), AuditSession.id.desc())
            .limit(25)
            .all()
        )
        out = []
        for session in sessions:
            total = db.query(AuditResult.detected_count).filter(AuditResult.session_id == session.id).all()
            result_total = sum(int(row[0]) for row in total) if total else 0
            out.append(
                {
                    "session_id": session.id,
                    "date": session.session_date.strftime("%d %b %Y"),
                    "total": result_total,
                    "status": session.status,
                    "item_name": f"Session #{session.id}",
                    "confidence": "",
                }
            )
        return out
    finally:
        db.close()


@app.get("/admin/products", response_model=list[AdminProductOut])
def admin_products():
    db = SessionLocal()
    try:
        return db.query(Product).order_by(Product.id.desc()).all()
    finally:
        db.close()


@app.put("/admin/products/{product_id}", response_model=AdminProductOut)
def admin_update_product(product_id: int, payload: ProductUpdateIn):
    db = SessionLocal()
    try:
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        duplicate = db.query(Product).filter(Product.sku == payload.sku, Product.id != product_id).first()
        if duplicate:
            raise HTTPException(status_code=409, detail="SKU already exists")
        product.sku = payload.sku
        product.name = payload.name
        product.category = payload.category
        product.description = payload.description
        product.image_url = payload.image_url
        db.commit()
        db.refresh(product)
        return product
    finally:
        db.close()


@app.delete("/admin/products/{product_id}")
def admin_delete_product(product_id: int):
    db = SessionLocal()
    try:
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        db.query(DetectionLog).filter(
            DetectionLog.result_id.in_(db.query(AuditResult.id).filter(AuditResult.product_id == product_id))
        ).delete(synchronize_session=False)
        db.query(StockReport).filter(StockReport.product_id == product_id).delete(synchronize_session=False)
        db.query(AuditResult).filter(AuditResult.product_id == product_id).delete(synchronize_session=False)
        db.delete(product)
        db.commit()
        return {"ok": True}
    finally:
        db.close()


@app.get("/admin/users", response_model=list[AdminUserOut])
def admin_users():
    db = SessionLocal()
    try:
        return db.query(User).order_by(User.id.desc()).all()
    finally:
        db.close()


from .services.auth_service import hash_password

class AdminUserIn(BaseModel):
    username: str
    password: str
    role: str = "staff"
    store_id: int = 1
    email: str | None = None

@app.post("/admin/users", response_model=AdminUserOut)
def admin_create_user(payload: AdminUserIn):
    db = SessionLocal()
    try:
        db_user = db.query(User).filter(User.username == payload.username).first()
        if db_user:
            raise HTTPException(status_code=409, detail="Username already exists")
        user = User(
            username=payload.username,
            password_hash=hash_password(payload.password),
            role=payload.role,
            store_id=payload.store_id,
            email=payload.email,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        return user
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

@app.put("/admin/users/{user_id}", response_model=AdminUserOut)
def admin_update_user(user_id: int, payload: AdminUserOut):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        duplicate = db.query(User).filter(User.username == payload.username, User.id != user_id).first()
        if duplicate:
            raise HTTPException(status_code=409, detail="Username already exists")
        user.username = payload.username
        user.role = payload.role
        user.store_id = payload.store_id
        user.email = payload.email
        db.commit()
        db.refresh(user)
        return user
    finally:
        db.close()


@app.delete("/admin/users/{user_id}")
def admin_delete_user(user_id: int):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        if user.username == "admin":
            raise HTTPException(status_code=400, detail="User super admin tidak dapat dihapus")

        # Cascade delete: hapus semua data audit terkait user
        session_ids = [
            s.id for s in db.query(AuditSession).filter(AuditSession.user_id == user_id).all()
        ]
        if session_ids:
            result_ids = [
                r.id for r in db.query(AuditResult).filter(AuditResult.session_id.in_(session_ids)).all()
            ]
            if result_ids:
                db.query(DetectionLog).filter(DetectionLog.result_id.in_(result_ids)).delete(synchronize_session=False)
            db.query(AuditResult).filter(AuditResult.session_id.in_(session_ids)).delete(synchronize_session=False)
            db.query(StockReport).filter(StockReport.session_id.in_(session_ids)).delete(synchronize_session=False)
            db.query(AuditSession).filter(AuditSession.user_id == user_id).delete(synchronize_session=False)

        db.delete(user)
        db.commit()
        return {"ok": True}
    finally:
        db.close()


@app.get("/admin/sessions/{session_id}", response_model=AdminSessionDetailOut)
def admin_session_detail(session_id: int):
    db = SessionLocal()
    try:
        session = db.query(AuditSession).filter(AuditSession.id == session_id).first()
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
        user = db.query(User).filter(User.id == session.user_id).first()
        results = (
            db.query(AuditResult, Product)
            .join(Product, Product.id == AuditResult.product_id)
            .filter(AuditResult.session_id == session.id)
            .all()
        )
        items = []
        for result, product in results:
            logs = db.query(DetectionLog).filter(DetectionLog.result_id == result.id).all()
            items.append(
                {
                    "result_id": result.id,
                    "sku": product.sku,
                    "name": product.name,
                    "expected": result.expected_count,
                    "detected": result.detected_count,
                    "status": "MATCH" if result.expected_count == result.detected_count else "MISMATCH",
                    "logs": [
                        {
                            "bbox_x": float(log.bbox_x),
                            "bbox_y": float(log.bbox_y),
                            "bbox_w": float(log.bbox_w),
                            "bbox_h": float(log.bbox_h),
                            "confidence": float(log.confidence),
                            "label": log.label,
                        }
                        for log in logs
                    ],
                }
            )
        return {
            "session_id": session.id,
            "date": session.session_date.strftime("%d %b %Y"),
            "store_id": session.store_id,
            "user_id": session.user_id,
            "user_name": user.username if user else "-",
            "status": session.status,
            "notes": session.notes or "",
            "items": items,
        }
    finally:
        db.close()


@app.get("/admin/report-summary", response_model=ReportSummaryOut)
def admin_report_summary():
    db = SessionLocal()
    try:
        total_sessions = db.query(AuditSession).count()
        total_aman = db.query(AuditSession).filter(AuditSession.status == "AMAN").count()
        total_tidak_aman = db.query(AuditSession).filter(AuditSession.status != "AMAN").count()
        return {
            "total_aman": total_aman,
            "total_tidak_aman": total_tidak_aman,
            "total_sessions": total_sessions,
        }
    finally:
        db.close()


@app.get("/admin/stores", response_model=list[StoreOut])
def admin_stores():
    db = SessionLocal()
    try:
        return db.query(Store).order_by(Store.id.desc()).all()
    finally:
        db.close()


@app.post("/admin/stores", response_model=StoreOut)
def admin_create_store(payload: StoreIn):
    db = SessionLocal()
    try:
        store = Store(
            name=payload.name,
            address=payload.address or "-",
            phone=payload.phone or "-",
        )
        db.add(store)
        db.commit()
        db.refresh(store)
        return store
    finally:
        db.close()


@app.delete("/admin/stores/{store_id}")
def admin_delete_store(store_id: int):
    db = SessionLocal()
    try:
        store = db.query(Store).filter(Store.id == store_id).first()
        if not store:
            raise HTTPException(status_code=404, detail="Store not found")
        if db.query(User).filter(User.store_id == store_id).first():
            raise HTTPException(status_code=409, detail="Store masih dipakai user")
        if db.query(AuditSession).filter(AuditSession.store_id == store_id).first():
            raise HTTPException(status_code=409, detail="Store masih dipakai sesi audit")
        db.delete(store)
        db.commit()
        return {"ok": True}
    finally:
        db.close()


@app.get("/admin/export-report")
def admin_export_report():
    db = SessionLocal()
    try:
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["session_id", "date", "status", "user", "store_id", "product_count"])
        rows = (
            db.query(AuditSession, User.username)
            .join(User, User.id == AuditSession.user_id)
            .order_by(AuditSession.session_date.desc(), AuditSession.id.desc())
            .all()
        )
        for session, username in rows:
            product_count = db.query(AuditResult).filter(AuditResult.session_id == session.id).count()
            writer.writerow(
                [
                    session.id,
                    session.session_date.strftime("%d %b %Y"),
                    session.status,
                    username,
                    session.store_id,
                    product_count,
                ]
            )
        return Response(
            content=output.getvalue(),
            media_type="text/csv",
            headers={"Content-Disposition": 'attachment; filename="report_audit.csv"'},
        )
    finally:
        db.close()


@app.post("/audit/save", response_model=AuditSaveOut)
def save_audit(payload: AuditSaveIn):
    import traceback
    db = SessionLocal()
    try:
        detections = []
        raw = payload.raw_json or {}
        if isinstance(raw, dict):
            detections = list(raw.get("detections") or [])

        if not detections:
            raise HTTPException(status_code=400, detail="Tidak ada detections untuk disimpan")

        valid_detections = [
            d
            for d in detections
            if float(d.get("score") or 0) >= SCORE_THR and str(d.get("label") or "") not in IGNORED_DETECTION_LABELS
        ]
        if not valid_detections:
            raise HTTPException(
                status_code=422,
                detail=f"Semua deteksi memiliki confidence di bawah {SCORE_THR:.0%}. Hasil tidak valid untuk disimpan.",
            )

        detections = valid_detections

        store_id = payload.store_id or 1
        user_id = payload.user_id or 1

        store = db.query(Store).filter(Store.id == store_id).first()
        user = db.query(User).filter(User.id == user_id).first()
        if store is None:
            store = db.query(Store).first()
            if store is None:
                store = Store(name="Default Store", address="-", phone="-")
                db.add(store)
                db.flush()
            store_id = store.id
        if user is None:
            user = db.query(User).filter(User.username == "default").first()
            if user is None:
                user = User(username="default", password_hash="x", role="staff", store_id=store_id)
                db.add(user)
                db.flush()
            user_id = user.id

        session_date = date.today()
        if payload.session_date:
            try:
                session_date = datetime.fromisoformat(payload.session_date).date()
            except ValueError:
                try:
                    session_date = date.fromisoformat(payload.session_date)
                except ValueError:
                    session_date = date.today()

        session = AuditSession(
            user_id=user_id,
            store_id=store_id,
            session_date=session_date,
            status=payload.status,
            notes=payload.notes,
        )
        db.add(session)
        db.flush()

        counts: dict[str, int] = {}
        product_map: dict[str, Product] = {}

        for det in detections:
            label = str(det.get("label") or "unknown")
            counts[label] = counts.get(label, 0) + 1
            product = db.query(Product).filter(Product.sku == label).first()
            if product is None:
                product = Product(
                    sku=label,
                    name=label,
                    category="uncategorized",
                    description="-",
                    image_url="",
                )
                db.add(product)
                db.flush()
            product_map[label] = product

        result_ids: list[int] = []
        for label, count in counts.items():
            product = product_map[label]
            result = AuditResult(
                session_id=session.id,
                product_id=product.id,
                detected_count=count,
                expected_count=0,
                image_path=payload.image_path or "",
                algorithm_used=payload.algorithm_used,
            )
            db.add(result)
            db.flush()
            result_ids.append(result.id)

            report = StockReport(
                session_id=session.id,
                product_id=product.id,
                on_shelf=count,
                shortage_flag=0,
            )
            db.add(report)

        for det in detections:
            label = str(det.get("label") or "unknown")
            product = product_map[label]
            result = (
                db.query(AuditResult)
                .filter(AuditResult.session_id == session.id, AuditResult.product_id == product.id)
                .first()
            )
            bbox = det.get("bbox_xyxy") or [0, 0, 0, 0]
            if not isinstance(bbox, list) or len(bbox) != 4:
                bbox = [0, 0, 0, 0]
            xmin, ymin, xmax, ymax = [float(x) for x in bbox]
            db.add(
                DetectionLog(
                    result_id=result.id,
                    bbox_x=xmin,
                    bbox_y=ymin,
                    bbox_w=max(xmax - xmin, 0.0),
                    bbox_h=max(ymax - ymin, 0.0),
                    confidence=float(det.get("score") or 0),
                    label=label,
                )
            )

        db.commit()
        return {
            "ok": True,
            "session_id": session.id,
            "result_count": len(result_ids),
            "detection_count": len(detections),
        }
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        tb = traceback.format_exc()
        print(f"[SAVE_AUDIT ERROR] {e}\n{tb}")
        raise HTTPException(status_code=500, detail=f"Gagal simpan: {str(e)}")
    finally:
        db.close()

