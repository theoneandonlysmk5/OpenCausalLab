"""Bolivian Child Labor Survey pipeline (ETI 2008 + ENNA 2016).

Translates ``vendor/stata_dofiles/data_cleaning/Child Labor Survey/*.do``
(9 files) into modular Python, ending in ``data/final/RW_child_labor_survey.parquet``.
"""

from .build import build_rw_child_labor_survey

__all__ = ["build_rw_child_labor_survey"]
