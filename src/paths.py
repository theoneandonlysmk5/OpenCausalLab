"""Path helpers for OpenCausalLab data directories."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
RAW = DATA / "raw"
INTERMEDIATE = DATA / "intermediate"
FINAL = DATA / "final"
VENDOR_DO = ROOT / "vendor" / "stata_dofiles"


def _first_existing(candidates: list[Path], label: str) -> Path:
    for path in candidates:
        if path.exists():
            return path
    raise FileNotFoundError(
        f"No {label} .dta found. Tried: {[str(p) for p in candidates]}"
    )


def raw_household_persona(year: int) -> Path:
    """Resolve raw Persona .dta (filenames vary in case across years)."""
    year_dir = RAW / "household" / str(year)
    candidates = [
        year_dir / f"EH{year}_Persona.dta",
        year_dir / f"eh{year}_persona.dta",
        year_dir / f"EH{year}_persona.dta",
        year_dir / f"eh{year}_Persona.dta",
    ]
    return _first_existing(candidates, f"Persona for {year}")


def raw_household_vivienda(year: int) -> Path:
    """Resolve raw Vivienda .dta (filenames vary in case across years)."""
    year_dir = RAW / "household" / str(year)
    candidates = [
        year_dir / f"EH{year}_Vivienda.dta",
        year_dir / f"eh{year}_vivienda.dta",
        year_dir / f"EH{year}_vivienda.dta",
        year_dir / f"eh{year}_Vivienda.dta",
    ]
    return _first_existing(candidates, f"Vivienda for {year}")
