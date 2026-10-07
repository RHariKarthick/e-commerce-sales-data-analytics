"""Load cleaned CSV tables into a local MySQL database.

Prerequisite: run sql/database_setup.sql in MySQL Workbench first, then set
MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, and MYSQL_DATABASE.
"""

import os
import sys

import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

from common import CLEANED_DATA_PATH, DATASETS


POSTAL_COLUMNS = {
    "olist_customers_dataset.csv": ["customer_zip_code_prefix"],
    "olist_sellers_dataset.csv": ["seller_zip_code_prefix"],
    "olist_geolocation_dataset.csv": ["geolocation_zip_code_prefix"],
}


def main() -> int:
    required = ["MYSQL_USER", "MYSQL_PASSWORD", "MYSQL_DATABASE"]
    missing_env = [name for name in required if os.getenv(name) is None]
    if missing_env:
        print("Set these environment variables before loading: " + ", ".join(missing_env), file=sys.stderr)
        return 2

    url = URL.create(
        "mysql+mysqlconnector",
        username=os.environ["MYSQL_USER"],
        password=os.environ["MYSQL_PASSWORD"],
        host=os.getenv("MYSQL_HOST", "localhost"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        database=os.environ["MYSQL_DATABASE"],
    )
    engine = create_engine(url, pool_pre_ping=True)
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        # Parent tables must exist before child rows are inserted because the schema
        # enforces foreign keys. Payments and reviews also reference orders.
        load_order = [
            "olist_customers_dataset.csv", "olist_sellers_dataset.csv",
            "olist_products_dataset.csv", "product_category_name_translation.csv",
            "olist_orders_dataset.csv", "olist_order_items_dataset.csv",
            "olist_order_payments_dataset.csv", "olist_order_reviews_dataset.csv",
            "olist_geolocation_dataset.csv",
        ]
        for filename in load_order:
            table_name = DATASETS[filename]
            path = CLEANED_DATA_PATH / filename
            if not path.exists():
                raise FileNotFoundError(f"Run the cleaning stage first; missing {path}")
            postal = POSTAL_COLUMNS.get(filename, [])
            total = 0
            for chunk in pd.read_csv(path, chunksize=20_000, dtype={c: "string" for c in postal}):
                chunk.to_sql(table_name, engine, if_exists="append", index=False, method="multi", chunksize=1000)
                total += len(chunk)
            print(f"Loaded {total:,} rows into {table_name}")
    except Exception as exc:
        print(f"MySQL load failed: {exc}", file=sys.stderr)
        return 1
    finally:
        engine.dispose()
    return 0


if __name__ == "__main__":
    sys.exit(main())
