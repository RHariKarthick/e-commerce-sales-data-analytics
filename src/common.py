"""Shared project paths and Olist dataset configuration."""

from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_PATH = PROJECT_ROOT / "data" / "raw"
CLEANED_DATA_PATH = PROJECT_ROOT / "data" / "cleaned"
REPORTS_PATH = PROJECT_ROOT / "reports" / "generated"

DATASETS = {
    "olist_customers_dataset.csv": "customers",
    "olist_orders_dataset.csv": "orders",
    "olist_order_items_dataset.csv": "order_items",
    "olist_order_payments_dataset.csv": "order_payments",
    "olist_order_reviews_dataset.csv": "order_reviews",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "olist_geolocation_dataset.csv": "geolocation",
    "product_category_name_translation.csv": "category_translation",
}

# Keep postal prefixes as text so leading zeroes are not lost during CSV import.
STRING_COLUMNS = {
    "olist_customers_dataset.csv": ["customer_zip_code_prefix"],
    "olist_sellers_dataset.csv": ["seller_zip_code_prefix"],
    "olist_geolocation_dataset.csv": ["geolocation_zip_code_prefix"],
}

DATE_COLUMNS = {
    "olist_orders_dataset.csv": [
        "order_purchase_timestamp", "order_approved_at",
        "order_delivered_carrier_date", "order_delivered_customer_date",
        "order_estimated_delivery_date",
    ],
    "olist_order_items_dataset.csv": ["shipping_limit_date"],
    "olist_order_reviews_dataset.csv": ["review_creation_date", "review_answer_timestamp"],
}

