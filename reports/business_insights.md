# Business findings

These findings summarize the MySQL validation and analysis results supplied for this project. The source data covers orders purchased from 4 September 2016 through 17 October 2018. Monetary figures are in the dataset's currency (Brazilian reais, R$).

## Sales and products

- Across order items, item price plus freight totaled **R$15,843,553.24** across **112,650 units** and **98,666 orders with items**. The resulting average item revenue per order with items was **R$160.58**. This is item revenue, not the separately recorded payment total.
- **Health and beauty** led category revenue at **R$1,441,248.07 (9.10%)**, followed by **watches and gifts** at R$1,305,541.61 (8.24%), **bed, bath and table** at R$1,241,681.72 (7.84%), **sports and leisure** at R$1,156,656.48 (7.30%), and **computers and accessories** at R$1,059,272.40 (6.69%). Together the top five contributed **39.16%** of item revenue (calculated from unrounded totals; displayed category shares are rounded).
- The category query includes all order statuses. The state, monthly, and delivery comparisons below use delivered orders as specified by their SQL sections; treat these populations separately.

## Customers and geography

- The delivered-order repeat-customer analysis found **93,358** distinct customer identities (`customer_unique_id`), of which **2,801 (3.00%)** placed more than one delivered order. Average delivered orders per identity were **1.03**. This is based on customers with delivered orders that have item rows, as the query joins `order_items`.
- São Paulo (SP) led delivered item revenue at **R$5,769,703.15**, followed by Rio de Janeiro (RJ) at R$2,055,401.57 and Minas Gerais (MG) at R$1,818,891.67. These are customer recorded states, not seller locations.

## Payments and delivery

- Credit cards accounted for **R$12,542,084.19**, or approximately **78.34%** of the R$16,008,872.12 total payment value shown across payment types. The payment table is at payment-record grain: orders can have multiple payment records. Credit-card payments averaged **3.51 installments**; boleto averaged one.
- Of delivered orders classified by actual delivery date, **88,649** were on time and **7,827** were late. That is **91.89% on time** among the 96,476 delivered orders with an on-time/late classification. The on-time group averaged **10.82 days** from purchase to delivery and arrived **13.71 days before** the estimated date on average. Late orders averaged **31.48 days** and arrived **8.87 days after** the estimate. A further **2,965** orders were not delivered and have no delivery duration.
- Average review score was **4.29** for on-time deliveries (88,168 reviewed orders), **2.57** for late deliveries (7,662), and **1.75** for orders not delivered (2,843). This is a descriptive association; it does not establish that delivery timing alone caused a score difference. Reviews are averaged per order before the group averages are calculated.

## Interpretation and reporting notes

- The monthly result screenshot omitted months without delivered revenue. Its displayed month-over-month percentages therefore compared adjacent returned rows rather than necessarily adjacent calendar months. `sql/analysis.sql` now creates a complete month calendar, fills absent months with zero, and calculates month-over-month change across calendar months. Rerun section 2 before publishing monthly growth figures; this report does not repeat the earlier percentages.
- The earlier review-score distribution used distinct orders per score, which can count one order in more than one score group when multiple reviews exist. Section 10 now reports review-record counts and excludes null scores. Rerun it before quoting a score distribution.
- Item revenue is calculated as item price plus freight at order-item grain. Payment value comes from the payment table and is analyzed separately. Do not add them together or join both raw grains before aggregation.
- Results are based on the loaded/cleaned Olist data and SQL outputs shared for the project. Validate refreshed results against the database before using them in a presentation or portfolio.

