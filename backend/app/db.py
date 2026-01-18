import os

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase


def _normalize_database_url(raw: str) -> str:
    raw = raw.strip()
    # Render commonly provides postgres://... which SQLAlchemy expects as postgresql://
    if raw.startswith("postgres://"):
        raw = "postgresql://" + raw[len("postgres://"):]

    # Prefer explicit driver for sync SQLAlchemy
    if raw.startswith("postgresql://") and "+" not in raw.split("://", 1)[0]:
        raw = raw.replace("postgresql://", "postgresql+psycopg2://", 1)

    return raw


DATABASE_URL = _normalize_database_url(
    os.getenv("DATABASE_URL")
    or os.getenv("RENDER_DATABASE_URL")
    or "sqlite:///./unintend.db"
)

connect_args = {}
if DATABASE_URL.startswith("sqlite"):
    # SQLite requirement
    connect_args = {"check_same_thread": False}

engine = create_engine(DATABASE_URL, connect_args=connect_args)

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


class Base(DeclarativeBase):
    pass
