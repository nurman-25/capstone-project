from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User
from ..schemas.auth import AuthResponse, LoginRequest, RegisterRequest, GoogleAuthRequest
from ..services.auth_service import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/register", response_model=AuthResponse)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.username == payload.username).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Username already exists")

    try:
        user = User(
            username=payload.username,
            role=payload.role,
            store_id=payload.store_id,
            email=payload.email,
            password_hash=hash_password(payload.password),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Internal error: {str(e)}")

    token = create_access_token(user.id, user.username, user.role)
    return {"token": token, "user": user}


@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == payload.username).first()
    password_ok = False
    needs_rehash = False
    if user is not None:
        try:
            password_ok = verify_password(payload.password, user.password_hash)
        except Exception:
            password_ok = payload.password == user.password_hash
            needs_rehash = password_ok

    if user is None or not password_ok:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Username atau password salah",
        )

    if needs_rehash:
        user.password_hash = hash_password(payload.password)
        db.commit()
        db.refresh(user)

    token = create_access_token(user.id, user.username, user.role)
    return {"token": token, "user": user}


@router.post("/google", response_model=AuthResponse)
def google_auth(payload: GoogleAuthRequest, db: Session = Depends(get_db)):
    # Check if user with this Gmail already exists
    user = db.query(User).filter(User.username == payload.email).first()
    
    if not user:
        # If user does not exist, auto-register them
        try:
            # Hash a unique dummy password since the authentication is handled via Google SSO
            dummy_pass_hash = hash_password("google_sso_verified_account_no_password_access")
            user = User(
                username=payload.email,
                role=payload.role,
                store_id=payload.store_id,
                password_hash=dummy_pass_hash,
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        except SQLAlchemyError as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Internal error: {str(e)}")

    token = create_access_token(user.id, user.username, user.role)
    return {"token": token, "user": user}

