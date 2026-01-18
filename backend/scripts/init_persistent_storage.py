from __future__ import annotations

import os
import shutil
import sys
import tempfile
import urllib.request
from pathlib import Path


def _sqlite_path_from_database_url(database_url: str) -> Path | None:
    database_url = (database_url or "").strip()
    if not database_url.startswith("sqlite:"):
        return None

    # Handles:
    # - sqlite:///./unintend.db
    # - sqlite:////var/data/unintend.db
    prefix = "sqlite:///"
    if prefix not in database_url:
        return None

    raw_path = database_url.split(prefix, 1)[1]
    if not raw_path:
        return None

    return Path(raw_path)


def _download_to(url: str, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp_path = Path(tmp.name)

    try:
        with urllib.request.urlopen(url) as resp, tmp_path.open("wb") as f:
            shutil.copyfileobj(resp, f)
        tmp_path.replace(target)
    finally:
        if tmp_path.exists() and tmp_path != target:
            try:
                tmp_path.unlink()
            except OSError:
                pass


def main() -> int:
    database_url = os.getenv("DATABASE_URL", "").strip()
    sqlite_path = _sqlite_path_from_database_url(database_url)

    # Allow explicit override.
    if os.getenv("SQLITE_DB_PATH"):
        sqlite_path = Path(os.environ["SQLITE_DB_PATH"].strip())

    if sqlite_path is None:
        print("[init] DATABASE_URL is not sqlite; nothing to init")
        return 0

    # If DATABASE_URL used a relative path, anchor it at project root.
    if not sqlite_path.is_absolute():
        sqlite_path = (Path.cwd() / sqlite_path).resolve()

    uploads_dir = (os.getenv("UPLOADS_DIR") or "").strip()
    if uploads_dir:
        Path(uploads_dir).mkdir(parents=True, exist_ok=True)

    force = (os.getenv("FORCE_DB_INIT") or "").strip().lower() in {"1", "true", "yes"}

    if sqlite_path.exists() and not force:
        print(f"[init] SQLite DB already exists: {sqlite_path} (set FORCE_DB_INIT=1 to overwrite)")
        return 0

    initial_db_url = (os.getenv("INITIAL_DB_URL") or "").strip()
    initial_db_path = (os.getenv("INITIAL_DB_PATH") or "").strip()

    if initial_db_url:
        if sqlite_path.exists() and force:
            print(f"[init] FORCE_DB_INIT=1: overwriting existing SQLite DB at {sqlite_path}")
        print(f"[init] Downloading initial DB from INITIAL_DB_URL -> {sqlite_path}")
        _download_to(initial_db_url, sqlite_path)
        return 0

    if initial_db_path:
        src = Path(initial_db_path)
        if not src.is_absolute():
            src = (Path.cwd() / src).resolve()
        if not src.exists():
            print(f"[init] INITIAL_DB_PATH does not exist: {src}", file=sys.stderr)
            return 1
        if sqlite_path.exists() and force:
            print(f"[init] FORCE_DB_INIT=1: overwriting existing SQLite DB at {sqlite_path}")
        print(f"[init] Copying initial DB from {src} -> {sqlite_path}")
        sqlite_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, sqlite_path)
        return 0

    print(
        "[init] No existing SQLite DB found and no INITIAL_DB_URL/INITIAL_DB_PATH provided. "
        "The app will start with an empty DB.",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
