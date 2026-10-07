"""Profile untouched Olist CSV files and write reproducible profiling reports.

Run from any directory with: python src/01_inspect_raw_data.py
"""

import json
import sys

import pandas as pd

from common import DATASETS, RAW_DATA_PATH, REPORTS_PATH, STRING_COLUMNS


def main() -> int:
    REPORTS_PATH.mkdir(parents=True, exist_ok=True)
    summaries = []
    missing_files = []
    details = {}

    for filename, table_name in DATASETS.items():
        path = RAW_DATA_PATH / filename
        if not path.exists():
            missing_files.append(filename)
            continue

        df = pd.read_csv(path, dtype={c: "string" for c in STRING_COLUMNS.get(filename, [])})
        numeric_columns = df.select_dtypes(include=["number"])
        missing = df.isna().sum()
        summary = {
            "file": filename,
            "table": table_name,
            "rows": int(len(df)),
            "columns": int(len(df.columns)),
            "duplicate_rows": int(df.duplicated().sum()),
            "missing_cells": int(missing.sum()),
            "columns_with_missing": int((missing > 0).sum()),
        }
        summaries.append(summary)
        details[table_name] = {
            **summary,
            "column_names": list(df.columns),
            "dtypes": {str(k): str(v) for k, v in df.dtypes.items()},
            "missing_by_column": {str(k): int(v) for k, v in missing.items() if v},
            "numeric_describe": numeric_columns.describe().to_dict() if not numeric_columns.empty else {},
            "sample_unique_values": {
                str(column): [None if pd.isna(x) else str(x) for x in df[column].dropna().unique()[:10]]
                for column in df.select_dtypes(include=["object", "string"]).columns
            },
        }
        print(f"{filename}: {len(df):,} rows x {len(df.columns)} columns; "
              f"{summary['duplicate_rows']:,} duplicate rows; {summary['missing_cells']:,} missing cells")

    pd.DataFrame(summaries).to_csv(REPORTS_PATH / "raw_data_profile.csv", index=False)
    (REPORTS_PATH / "raw_data_profile.json").write_text(
        json.dumps({"tables": details, "missing_files": missing_files}, indent=2, default=str),
        encoding="utf-8",
    )

    if missing_files:
        print("\nMissing expected files in data/raw/: " + ", ".join(missing_files))
        print("Download the Olist dataset and extract its CSV files into data/raw/ before continuing.")
        return 1
    print(f"\nProfiling reports written to {REPORTS_PATH.relative_to(RAW_DATA_PATH.parent.parent)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
