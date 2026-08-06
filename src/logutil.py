"""Central logging setup for OpenCausalLab scripts."""

from __future__ import annotations

import logging
import os
import sys


def setup_logging(name: str = "opencausallab", level: int | None = None) -> logging.Logger:
    """Configure root logging once; return a named logger."""
    if level is None:
        level_name = os.environ.get("OPENCAUSAL_LOG", "INFO").upper()
        level = getattr(logging, level_name, logging.INFO)

    root = logging.getLogger("opencausallab")
    if not root.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(
            logging.Formatter("%(asctime)s %(levelname)s [%(name)s] %(message)s", "%H:%M:%S")
        )
        root.addHandler(handler)
        root.setLevel(level)
        root.propagate = False
    return logging.getLogger(f"opencausallab.{name}")
