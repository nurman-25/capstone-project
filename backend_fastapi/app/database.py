from sqlalchemy import create_engine, text
from sqlalchemy.orm import declarative_base, sessionmaker

DATABASE_URL = "mysql+pymysql://root:@127.0.0.1:3306/db_capstone"


def _ensure_database_exists():
    bootstrap_engine = create_engine("mysql+pymysql://root:@127.0.0.1:3306", pool_pre_ping=True)
    with bootstrap_engine.connect() as conn:
        conn.execute(text("CREATE DATABASE IF NOT EXISTS db_capstone"))
        conn.commit()
    bootstrap_engine.dispose()


_ensure_database_exists()
engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
