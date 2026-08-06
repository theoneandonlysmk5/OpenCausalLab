#!/usr/bin/env python3
"""Run main Tables 1–6 (HHsurvey parts) and compare to manuscript."""
from __future__ import annotations
import sys
from pathlib import Path
from pathlib import Path
import sys

CASE_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = CASE_ROOT.parents[1]
sys.path.insert(0, str(REPO_ROOT))
sys.path.insert(0, str(CASE_ROOT))

from src.main_tables import build_main_tables_ledger, write_main_table_outputs
from src.table3 import load_hhsurvey

def main():
    hh = load_hhsurvey()
    ledger, artifacts = build_main_tables_ledger(hh)
    out = write_main_table_outputs(artifacts, ledger)
    print(ledger.groupby(['table','status']).size().unstack(fill_value=0))
    print('\nOPEN / NEAR:')
    show = ledger.loc[ledger.status.isin(['open','near'])].sort_values(['table','result'])
    print(show.to_string(index=False))
    print(f'\nWrote → {out}')

if __name__ == '__main__':
    main()
