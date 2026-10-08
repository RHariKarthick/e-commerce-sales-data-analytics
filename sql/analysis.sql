USE ecommerce_olist;

-- Metric contract: item revenue = item price + freight, at order-item grain.
-- Payments are a separate order-payment grain and should not be added to item revenue.

-- 1. Core KPIs
SELECT ROUND(SUM(price + freight_value), 2) AS total_item_revenue,
       COUNT(DISTINCT order_id) AS orders_with_items,
       SUM(1) AS units_sold,
       ROUND(SUM(price + freight_value) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS average_order_value
FROM order_items;

-- 2. Monthly revenue and month-over-month change (MySQL 8+)
WITH RECURSIVE months AS (
  SELECT CAST(DATE_FORMAT(MIN(order_purchase_timestamp), '%Y-%m-01') AS DATE) AS month_start
  FROM orders
  UNION ALL
  SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
  FROM months
  WHERE month_start < (
    SELECT CAST(DATE_FORMAT(MAX(order_purchase_timestamp), '%Y-%m-01') AS DATE)
    FROM orders
  )
), monthly_sales AS (
  SELECT CAST(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS DATE) AS month_start,
         SUM(oi.price + oi.freight_value) AS revenue
  FROM orders o JOIN order_items oi USING (order_id)
  WHERE o.order_status = 'delivered'
  GROUP BY CAST(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS DATE)
), monthly AS (
  SELECT m.month_start, COALESCE(s.revenue, 0) AS revenue
  FROM months m LEFT JOIN monthly_sales s USING (month_start)
)
SELECT DATE_FORMAT(month_start, '%Y-%m-01') AS month_start, ROUND(revenue, 2) AS revenue,
       ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY month_start)) /
         NULLIF(LAG(revenue) OVER (ORDER BY month_start), 0), 2) AS mom_change_pct
FROM monthly ORDER BY month_start;

-- 3. Revenue, order volume and category contribution
WITH category_sales AS (
  SELECT COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown') AS category,
         SUM(oi.price + oi.freight_value) AS revenue,
         COUNT(DISTINCT oi.order_id) AS orders,
         COUNT(*) AS units
  FROM order_items oi JOIN products p USING (product_id)
  LEFT JOIN category_translation ct USING (product_category_name)
  GROUP BY COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown')
)
SELECT category, ROUND(revenue, 2) AS revenue, orders, units,
       ROUND(100 * revenue / NULLIF(SUM(revenue) OVER (), 0), 2) AS revenue_share_pct,
       DENSE_RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM category_sales ORDER BY revenue DESC;

-- 4. Top 10 products by item revenue
SELECT oi.product_id, COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown') AS category,
       COUNT(*) AS units, ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue
FROM order_items oi JOIN products p USING (product_id)
LEFT JOIN category_translation ct USING (product_category_name)
GROUP BY oi.product_id, category ORDER BY revenue DESC LIMIT 10;

-- 5. State performance. Customer state is the customer's recorded state.
SELECT c.customer_state AS state, COUNT(DISTINCT o.order_id) AS orders,
       COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS item_revenue
FROM orders o JOIN customers c USING (customer_id)
JOIN order_items oi USING (order_id)
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state ORDER BY item_revenue DESC;

-- 6. Repeat customers use customer_unique_id, not customer_id.
WITH customer_orders AS (
  SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS order_count,
         SUM(oi.price + oi.freight_value) AS item_revenue
  FROM customers c JOIN orders o USING (customer_id)
  JOIN order_items oi USING (order_id)
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id
)
SELECT COUNT(*) AS unique_customers,
       SUM(order_count > 1) AS repeat_customers,
       ROUND(100 * SUM(order_count > 1) / NULLIF(COUNT(*), 0), 2) AS repeat_customer_pct,
       ROUND(AVG(order_count), 2) AS avg_orders_per_customer
FROM customer_orders;

-- 7. Payment method mix at payment grain (do not join item rows here).
SELECT payment_type, COUNT(*) AS payment_records, COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(payment_value), 2) AS payment_value,
       ROUND(AVG(payment_installments), 2) AS avg_installments
FROM order_payments GROUP BY payment_type ORDER BY payment_value DESC;

-- 8. Delivery timeliness and delay. Positive days late means delivered after estimate.
WITH delivery AS (
  SELECT order_id,
    DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) AS delivery_days,
    DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) AS days_late,
    CASE WHEN order_delivered_customer_date IS NULL THEN 'Not Delivered'
         WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
         ELSE 'Late' END AS delivery_bucket
  FROM orders
)
SELECT delivery_bucket, COUNT(*) AS orders,
       ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
       ROUND(AVG(days_late), 2) AS avg_days_vs_estimate
FROM delivery GROUP BY delivery_bucket ORDER BY orders DESC;

-- 9. Review score by delivery performance, one row per reviewed order (aggregate reviews first).
WITH review_by_order AS (
  SELECT order_id, AVG(review_score) AS avg_review_score FROM order_reviews GROUP BY order_id
), delivery AS (
  SELECT order_id,
    CASE WHEN order_delivered_customer_date IS NULL THEN 'Not Delivered'
         WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
         ELSE 'Late' END AS delivery_bucket
  FROM orders
)
SELECT d.delivery_bucket, COUNT(*) AS reviewed_orders,
       ROUND(AVG(r.avg_review_score), 2) AS avg_review_score
FROM delivery d JOIN review_by_order r USING (order_id)
GROUP BY d.delivery_bucket ORDER BY reviewed_orders DESC;

-- 10. Review score distribution at review-record grain. An order can have multiple reviews.
SELECT review_score, COUNT(*) AS review_records
FROM order_reviews
WHERE review_score IS NOT NULL
GROUP BY review_score ORDER BY review_score;

-- 11. Ranking states by revenue (window function)
WITH state_sales AS (
  SELECT c.customer_state, SUM(oi.price + oi.freight_value) AS revenue
  FROM orders o JOIN customers c USING (customer_id) JOIN order_items oi USING (order_id)
  WHERE o.order_status = 'delivered' GROUP BY c.customer_state
)
SELECT customer_state, ROUND(revenue, 2) AS revenue,
       RANK() OVER (ORDER BY revenue DESC) AS state_rank
FROM state_sales ORDER BY state_rank;

