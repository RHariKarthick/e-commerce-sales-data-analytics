# Power BI dashboard build guide

The `.pbix` dashboard is created in Power BI Desktop after the source tables exist in MySQL. It is intentionally not included as a fabricated binary file. Use **Get data → MySQL database**, connect to `localhost:3306` (or your configured server) and database `ecommerce_olist`, then import these tables:

- `orders`, `order_items`, `customers`, `products`, `category_translation`
- `order_payments`, `order_reviews`, `sellers`

Do not import `geolocation` into the first version unless a map visual needs it; it contains many postal-prefix rows and is not unique by prefix. Avoid creating a many-to-many relationship from it to orders.

## Model relationships

Use single-direction, one-to-many relationships where the dimension key is unique:

| One side | Many side | Key |
| --- | --- | --- |
| customers | orders | customer_id |
| orders | order_items | order_id |
| products | order_items | product_id |
| sellers | order_items | seller_id |
| orders | order_payments | order_id |
| orders | order_reviews | order_id |
| category_translation | products | product_category_name |

The last relationship may have unmatched product categories; keep the product category field usable and display missing translations as the original category or `unknown`. A date table should relate to `orders[order_purchase_timestamp]` as the active date relationship. Keep order items, payments, and reviews as separate facts. Never sum payments in the same unaggregated join with item rows.

## Three-page report layout

1. **Executive Overview:** KPI cards for item revenue, delivered orders, unique customers, average order value and average review score; monthly revenue line; category revenue bar; order status column; state revenue map/bar.
2. **Product & Sales:** category revenue and order count; top products by revenue; units and average item price; category contribution; date and category slicers.
3. **Customer & Operations:** repeat-customer percentage; payment type distribution; on-time/late/not-delivered order counts; delivery days; average review score by delivery group; state and date slicers.

Add slicers for date, customer state, category, payment type, and order status. Validate totals against `sql/validation.sql` and `sql/analysis.sql` before publishing.

## Measures

Copy the measures from [`measures.dax`](measures.dax). The total revenue measure follows the defined item-level metric (`price + freight_value`), not payment value.

