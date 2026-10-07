# E-Commerce Sales Data Cleaning & Analytics

An end-to-end, reproducible analytics project using the Brazilian E-Commerce Public Dataset by Olist. It demonstrates raw-data profiling, careful multi-table cleaning, data-quality validation, relational MySQL loading, business-focused SQL, and a Power BI dashboard plan with DAX measures.

## Project structure

```text
ECommerce-Sales-Analytics/
├── data/
│   ├── raw/                 # Original source CSVs; never edited or committed
│   └── cleaned/             # Generated cleaned CSVs; ignored by Git
├── src/
│   ├── common.py            # Paths, table names, date and type configuration
│   ├── 01_inspect_raw_data.py
│   ├── 02_clean_data.py
│   └── 03_load_mysql.py
├── sql/
│   ├── database_setup.sql
│   ├── validation.sql
│   └── analysis.sql
├── powerbi/
│   ├── README.md             # Data model and three-page dashboard build guide
│   └── measures.dax
├── reports/
│   ├── README.md
│   └── insights_template.md
├── requirements.txt
└── .gitignore
```

## Requirements

- Python 3.10 or newer
- MySQL Community Server 8.0 or newer (the analysis SQL uses CTEs and window functions)
- MySQL Workbench, VS Code, and Power BI Desktop for the corresponding project stages
- The nine Olist CSV files listed below

## 1. Set up Python

Open a terminal in the repository root:

```powershell
python -m venv venv
venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

If PowerShell blocks activation, use the Python executable directly: `venv\Scripts\python.exe`.

## 2. Acquire the source data

Download the Brazilian E-Commerce Public Dataset by Olist from its Kaggle dataset page (`olistbr/brazilian-ecommerce`) and extract the original CSV files into `data/raw/`. The expected filenames are:

```text
olist_customers_dataset.csv
olist_orders_dataset.csv
olist_order_items_dataset.csv
olist_order_payments_dataset.csv
olist_order_reviews_dataset.csv
olist_products_dataset.csv
olist_sellers_dataset.csv
olist_geolocation_dataset.csv
product_category_name_translation.csv
```

Keep the original files unchanged. They are excluded from Git by `.gitignore`; follow the dataset publisher's terms when downloading, using, or sharing the data. This repository contains no fabricated sample data.

## 3. Profile before cleaning

From the project root, run:

```powershell
python src/01_inspect_raw_data.py
```

Expected outputs are `reports/generated/raw_data_profile.csv` and `raw_data_profile.json`. The script summarizes each source table's row and column counts, dtypes, missing cells, duplicate rows, numerical description, and example categorical values. It exits with a helpful message if expected files are missing.

## 4. Clean and validate

```powershell
python src/02_clean_data.py
```

The script writes cleaned copies under `data/cleaned/`; it never edits `data/raw/`. Cleaning removes exact duplicate rows, trims text whitespace, standardizes `not_defined` payment types to `unknown`, labels missing product categories `unknown`, corrects the two misspelled product-length field names, parses configured dates, and converts selected numeric fields. Postal prefixes are kept as text to preserve leading zeroes. Other missing values are not indiscriminately filled.

Generated evidence is written to `reports/generated/`:

- `cleaning_validation_summary.csv/json`: rows before/after, duplicates removed, and missing-cell counts before/after
- `cleaned_data_types.csv`: resulting dtype for each field
- `invalid_values_handled.csv`: field-specific conversions such as invalid dates becoming `NaT`

Review these reports before proceeding. Cleaning rules are transparent and should be changed only when a documented data issue justifies it.

## 5. Create the MySQL schema and load tables

In MySQL Workbench, open and run `sql/database_setup.sql`. It creates the `ecommerce_olist` database and relational tables with primary keys, foreign keys, and useful indexes.

Set connection values in the terminal. Replace the example password locally; do not put credentials in a committed file:

```powershell
$env:MYSQL_HOST = "localhost"
$env:MYSQL_PORT = "3306"
$env:MYSQL_USER = "root"
$env:MYSQL_PASSWORD = "your-local-password"
$env:MYSQL_DATABASE = "ecommerce_olist"
python src/03_load_mysql.py
```

The loader sends cleaned data in chunks and loads parent tables before dependent tables. It appends rows, so **do not run it twice against populated tables** unless you first clear/recreate the schema. The password is read from the process environment, not stored in the source files.

## 6. Validate in SQL and answer business questions

Run `sql/validation.sql` in Workbench first. Compare table counts with the Python report, inspect the date range, and confirm the referential-integrity and negative-value checks return no unexpected rows. Then run sections of `sql/analysis.sql` for:

- Total item revenue, average order value, units, and orders
- Monthly revenue and month-over-month movement
- Category and product rankings and category contribution
- Customer-state sales and repeat buyers (using `customer_unique_id`)
- Payment type and installment patterns
- Delivery timeliness and review scores by delivery bucket

**Metric grain:** item revenue is `SUM(order_items.price + order_items.freight_value)`. Payments live at payment-record grain and are analyzed separately. Do not join unaggregated item, payment, and review rows together: that can multiply values. SQL analysis filters delivered orders for several comparisons; check each query's stated population before comparing metrics.

## 7. Build the Power BI report

Follow [`powerbi/README.md`](powerbi/README.md) to connect Power BI Desktop to the MySQL tables, create the star-like relationships, add the DAX measures in [`powerbi/measures.dax`](powerbi/measures.dax), and build the three report pages: Executive Overview, Product & Sales, and Customer & Operations. Validate dashboard totals against SQL before using them in a portfolio or resume.

The `.pbix` is not supplied because it must be created and checked in Power BI Desktop after the MySQL database is populated. Likewise, no business insight or numeric result is claimed until it has been calculated from the downloaded data; record verified findings in `reports/insights_template.md`.

## Reproducible run order

```text
Download source CSVs -> profile -> clean and review validation -> create MySQL schema -> load -> run SQL validation -> analyze -> build and reconcile Power BI -> write evidence-based insights
```

