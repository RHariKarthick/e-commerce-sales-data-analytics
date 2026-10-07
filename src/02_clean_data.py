"""Clean Olist tables without modifying the original CSV files."""

import json
import sys

import pandas as pd

from common import DATASETS, DATE_COLUMNS, RAW_DATA_PATH, CLEANED_DATA_PATH, REPORTS_PATH, STRING_COLUMNS


def clean_one(filename: str, table_name: str) -> tuple[pd.DataFrame, dict, list[dict], list[dict]]:
    path = RAW_DATA_PATH / filename
    if not path.exists():
        raise FileNotFoundError(f"Required source file not found: {path}")

    df = pd.read_csv(path, dtype={c: "string" for c in STRING_COLUMNS.get(filename, [])})
    rows_before = len(df)
    missing_before = int(df.isna().sum().sum())
    duplicates_removed = int(df.duplicated().sum())
    df = df.drop_duplicates().copy()
    invalid_events = []

    # Trim text columns; missing values remain missing unless a field-specific rule applies.
    for column in df.select_dtypes(include=["object", "string"]).columns:
        df[column] = df[column].str.strip()

    if filename == "olist_order_payments_dataset.csv" and "payment_type" in df:
        before = int(df["payment_type"].eq("not_defined").sum())
        df["payment_type"] = df["payment_type"].replace("not_defined", "unknown")
        invalid_events.append({"column": "payment_type", "rule": "not_defined -> unknown", "values_handled": before})

    if filename == "olist_products_dataset.csv":
        rename = {
            "product_name_lenght": "product_name_length",
            "product_description_lenght": "product_description_length",
        }
        df = df.rename(columns={old: new for old, new in rename.items() if old in df.columns})
        if "product_category_name" in df:
            missing_categories = int(df["product_category_name"].isna().sum())
            df["product_category_name"] = df["product_category_name"].fillna("unknown")
            invalid_events.append({"column": "product_category_name", "rule": "missing -> unknown", "values_handled": missing_categories})

    for column in DATE_COLUMNS.get(filename, []):
        if column not in df:
            continue
        old_nonmissing = int(df[column].notna().sum())
        parsed = pd.to_datetime(df[column], errors="coerce")
        coerced = max(0, old_nonmissing - int(parsed.notna().sum()))
        if coerced:
            invalid_events.append({"column": column, "rule": "unparseable date -> NaT", "values_handled": coerced})
        df[column] = parsed

    # Numeric business columns should stay numeric even when source CSVs contain bad tokens.
    numeric_candidates = {
        "olist_order_items_dataset.csv": ["order_item_id", "price", "freight_value"],
        "olist_order_payments_dataset.csv": ["payment_sequential", "payment_installments", "payment_value"],
        "olist_order_reviews_dataset.csv": ["review_score"],
        "olist_products_dataset.csv": ["product_name_length", "product_description_length", "product_photos_qty", "product_weight_g", "product_length_cm", "product_height_cm", "product_width_cm"],
        "olist_geolocation_dataset.csv": ["geolocation_lat", "geolocation_lng"],
    }.get(filename, [])
    for column in numeric_candidates:
        if column in df:
            before_bad = int(df[column].notna().sum())
            parsed = pd.to_numeric(df[column], errors="coerce")
            coerced = max(0, before_bad - int(parsed.notna().sum()))
            if coerced:
                invalid_events.append({"column": column, "rule": "non-numeric value -> NaN", "values_handled": coerced})
            df[column] = parsed

    output_path = CLEANED_DATA_PATH / filename
    df.to_csv(output_path, index=False, date_format="%Y-%m-%d %H:%M:%S")
    summary = {
        "file": filename,
        "table": table_name,
        "rows_before": int(rows_before),
        "rows_after": int(len(df)),
        "duplicate_rows_removed": duplicates_removed,
        "missing_values_before": missing_before,
        "missing_values_after": int(df.isna().sum().sum()),
        "output": str(output_path.relative_to(CLEANED_DATA_PATH.parent.parent)),
    }
    type_rows = [{"table": table_name, "column": c, "dtype_after_cleaning": str(t)} for c, t in df.dtypes.items()]
    return df, summary, type_rows, invalid_events


def main() -> int:
    CLEANED_DATA_PATH.mkdir(parents=True, exist_ok=True)
    REPORTS_PATH.mkdir(parents=True, exist_ok=True)
    summaries, dtypes, invalids = [], [], []
    try:
        for filename, table_name in DATASETS.items():
            _, summary, type_rows, events = clean_one(filename, table_name)
            summaries.append(summary)
            dtypes.extend(type_rows)
            invalids.extend({"table": table_name, **event} for event in events)
            print(f"{table_name}: {summary['rows_before']:,} -> {summary['rows_after']:,} rows; "
                  f"{summary['duplicate_rows_removed']:,} duplicates removed")
    except (FileNotFoundError, pd.errors.EmptyDataError, pd.errors.ParserError) as exc:
        print(f"Cleaning stopped: {exc}", file=sys.stderr)
        return 1

    pd.DataFrame(summaries).to_csv(REPORTS_PATH / "cleaning_validation_summary.csv", index=False)
    pd.DataFrame(dtypes).to_csv(REPORTS_PATH / "cleaned_data_types.csv", index=False)
    pd.DataFrame(invalids, columns=["table", "column", "rule", "values_handled"]).to_csv(
        REPORTS_PATH / "invalid_values_handled.csv", index=False
    )
    (REPORTS_PATH / "cleaning_validation_summary.json").write_text(
        json.dumps({"tables": summaries, "invalid_values_handled": invalids}, indent=2), encoding="utf-8"
    )
    print(f"\nCleaned CSV files: {CLEANED_DATA_PATH}")
    print(f"Validation reports: {REPORTS_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
