from datetime import date, datetime

from sqlalchemy import Date, DateTime, DECIMAL, ForeignKey, Integer, SmallInteger, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .database import Base


class Store(Base):
    __tablename__ = "stores"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(120))
    address: Mapped[str] = mapped_column(Text)
    phone: Mapped[str] = mapped_column(String(30))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    username: Mapped[str] = mapped_column(String(120), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    role: Mapped[str] = mapped_column(String(20), default="staff")
    store_id: Mapped[int] = mapped_column(ForeignKey("stores.id"), index=True)
    email: Mapped[str] = mapped_column(String(120), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    sku: Mapped[str] = mapped_column(String(80), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(120))
    category: Mapped[str] = mapped_column(String(80))
    description: Mapped[str] = mapped_column(Text)
    image_url: Mapped[str] = mapped_column(String(255))


class AuditSession(Base):
    __tablename__ = "audit_sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    store_id: Mapped[int] = mapped_column(ForeignKey("stores.id"), index=True)
    session_date: Mapped[date] = mapped_column(Date)
    status: Mapped[str] = mapped_column(String(20))
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)


class AuditResult(Base):
    __tablename__ = "audit_results"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    session_id: Mapped[int] = mapped_column(ForeignKey("audit_sessions.id"), index=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), index=True)
    detected_count: Mapped[int] = mapped_column(Integer, default=1)
    expected_count: Mapped[int] = mapped_column(Integer, default=0)
    image_path: Mapped[str] = mapped_column(String(255))
    algorithm_used: Mapped[str] = mapped_column(String(80))


class StockReport(Base):
    __tablename__ = "stock_reports"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    session_id: Mapped[int] = mapped_column(ForeignKey("audit_sessions.id"), index=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), index=True)
    on_shelf: Mapped[int] = mapped_column(Integer, default=0)
    shortage_flag: Mapped[int] = mapped_column(SmallInteger, default=0)
    generated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class DetectionLog(Base):
    __tablename__ = "detection_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    result_id: Mapped[int] = mapped_column(ForeignKey("audit_results.id"), index=True)
    bbox_x: Mapped[float] = mapped_column(DECIMAL(10, 2))
    bbox_y: Mapped[float] = mapped_column(DECIMAL(10, 2))
    bbox_w: Mapped[float] = mapped_column(DECIMAL(10, 2))
    bbox_h: Mapped[float] = mapped_column(DECIMAL(10, 2))
    confidence: Mapped[float] = mapped_column(DECIMAL(5, 4))
    label: Mapped[str] = mapped_column(String(120))
