USE ecommerce_olist;

-- Table counts. Compare these with reports/cleaning_validation_summary.csv.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation;

-- Referential integrity checks should return zero rows for the primary relationships.
SELECT oi.order_id, oi.order_item_id FROM order_items oi LEFT JOIN orders o USING (order_id) WHERE o.order_id IS NULL LIMIT 20;
SELECT o.order_id FROM orders o LEFT JOIN customers c USING (customer_id) WHERE c.customer_id IS NULL LIMIT 20;
SELECT oi.product_id FROM order_items oi LEFT JOIN products p USING (product_id) WHERE p.product_id IS NULL LIMIT 20;
SELECT oi.seller_id FROM order_items oi LEFT JOIN sellers s USING (seller_id) WHERE s.seller_id IS NULL LIMIT 20;

-- Check date range, status distribution, impossible negative sales values, and key uniqueness.
SELECT MIN(order_purchase_timestamp) AS first_order, MAX(order_purchase_timestamp) AS last_order FROM orders;
SELECT order_status, COUNT(*) AS orders FROM orders GROUP BY order_status ORDER BY orders DESC;
SELECT COUNT(*) AS negative_item_values FROM order_items WHERE price < 0 OR freight_value < 0;
SELECT COUNT(DISTINCT customer_id) AS customer_records,
       COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;

-- Revenue computed at item grain; do not join raw payments/reviews before aggregation.
SELECT ROUND(SUM(price + freight_value), 2) AS item_revenue FROM order_items;
SELECT COUNT(DISTINCT order_id) AS orders_with_items FROM order_items;
