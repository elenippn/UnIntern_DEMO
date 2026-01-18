from __future__ import annotations

import os
from pathlib import Path


def uploads_root() -> Path:
    """Return the filesystem directory where uploads are stored.

    - If UPLOADS_DIR is set (recommended on Render with a Persistent Disk), use it.
    - Otherwise default to <repo>/uploads for local dev.
    """

    configured = (os.getenv("UPLOADS_DIR") or "").strip()
    if configured:
        return Path(configured)

    return Path(__file__).resolve().parents[1] / "uploads"
