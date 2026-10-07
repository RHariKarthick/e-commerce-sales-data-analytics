-- Run this script in MySQL Workbench before running src/03_load_mysql.py.
-- Keep table grain intact. Revenue is calculated from order_items (price + freight).
CREATE DATABASE IF NOT EXISTS ecommerce_olist
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE ecommerce_olist;

CREATE TABLE IF NOT EXISTS customers (
  customer_id VARCHAR(32) NOT NULL PRIMARY KEY,
  customer_unique_id VARCHAR(32) NOT NULL,
  customer_zip_code_prefix VARCHAR(5),
  customer_city VARCHAR(100), customer_state CHAR(2),
  INDEX ix_customers_unique_id (customer_unique_id), INDEX ix_customers_state (customer_state)
);
CREATE TABLE IF NOT EXISTS sellers (
  seller_id VARCHAR(32) NOT NULL PRIMARY KEY,
  seller_zip_code_prefix VARCHAR(5), seller_city VARCHAR(100), seller_state CHAR(2)
);
CREATE TABLE IF NOT EXISTS products (
  product_id VARCHAR(32) NOT NULL PRIMARY KEY,
  product_category_name VARCHAR(100), product_name_length INT,
  product_description_length INT, product_photos_qty INT,
  product_weight_g DOUBLE, product_length_cm DOUBLE, product_height_cm DOUBLE, product_width_cm DOUBLE
);
CREATE TABLE IF NOT EXISTS category_translation (
  product_category_name VARCHAR(100) NOT NULL PRIMARY KEY,
  product_category_name_english VARCHAR(100)
);
CREATE TABLE IF NOT EXISTS orders (
  order_id VARCHAR(32) NOT NULL PRIMARY KEY,
  customer_id VARCHAR(32) NOT NULL,
  order_status VARCHAR(30),
  order_purchase_timestamp DATETIME, order_approved_at DATETIME,
  order_delivered_carrier_date DATETIME, order_delivered_customer_date DATETIME,
  order_estimated_delivery_date DATETIME,
  INDEX ix_orders_purchase (order_purchase_timestamp), INDEX ix_orders_status (order_status),
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
CREATE TABLE IF NOT EXISTS order_items (
  order_id VARCHAR(32) NOT NULL,
  order_item_id INT NOT NULL,
  product_id VARCHAR(32) NOT NULL, seller_id VARCHAR(32) NOT NULL,
  shipping_limit_date DATETIME, price DECIMAL(12,2), freight_value DECIMAL(12,2),
  PRIMARY KEY (order_id, order_item_id),
  INDEX ix_items_product (product_id), INDEX ix_items_seller (seller_id),
  CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
  CONSTRAINT fk_items_product FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT fk_items_seller FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);
CREATE TABLE IF NOT EXISTS order_payments (
  order_id VARCHAR(32) NOT NULL, payment_sequential INT NOT NULL,
  payment_type VARCHAR(40), payment_installments INT, payment_value DECIMAL(12,2),
  PRIMARY KEY (order_id, payment_sequential), INDEX ix_payments_type (payment_type),
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
CREATE TABLE IF NOT EXISTS order_reviews (
  review_id VARCHAR(32) NOT NULL,
  order_id VARCHAR(32) NOT NULL,
  review_score INT, review_comment_title TEXT, review_comment_message TEXT,
  review_creation_date DATETIME, review_answer_timestamp DATETIME,
  PRIMARY KEY (review_id, order_id), INDEX ix_reviews_order (order_id),
  CONSTRAINT fk_reviews_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
CREATE TABLE IF NOT EXISTS geolocation (
  geolocation_zip_code_prefix VARCHAR(5),
  geolocation_lat DOUBLE, geolocation_lng DOUBLE,
  geolocation_city VARCHAR(100), geolocation_state CHAR(2),
  INDEX ix_geo_zip (geolocation_zip_code_prefix), INDEX ix_geo_state (geolocation_state)
);
