-- =============================================================
-- Project: E-commerce Profitability & Revenue Leakage Analysis
-- File: 01_database_setup.sql
-- Purpose: Create MySQL database, raw staging tables, and cleaned
--          analytical views for the Olist Brazilian E-commerce data.
--
-- Important profit assumption:
-- Profit is estimated. Actual cost is not available in the public
-- Olist dataset. Assumption: estimated_cost = 60% of item price.
--
-- Raw staging tables intentionally do not use strict foreign keys.
-- This keeps CSV import flexible; quality checks and analytical
-- relationships are handled in later cleaning and analysis steps.
-- =============================================================

CREATE DATABASE IF NOT EXISTS ecommerce_analysis;
USE ecommerce_analysis;

-- Staging table for customer-level location data.
CREATE TABLE IF NOT EXISTS stg_customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

-- Staging table for order header data, including status and dates.
CREATE TABLE IF NOT EXISTS stg_orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

-- Staging table for item-level sales, price, and real freight values.
CREATE TABLE IF NOT EXISTS stg_order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(12,2),
    freight_value DECIMAL(12,2)
);

-- Staging table for payment transactions by order.
CREATE TABLE IF NOT EXISTS stg_order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(12,2)
);

-- Staging table for customer review scores by order.
CREATE TABLE IF NOT EXISTS stg_order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

-- Staging table for product attributes and Portuguese category names.
CREATE TABLE IF NOT EXISTS stg_products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- Staging table for seller location. State fields are used directly.
CREATE TABLE IF NOT EXISTS stg_sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

-- Staging table translating Portuguese product categories into English.
CREATE TABLE IF NOT EXISTS stg_product_category_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

-- Analytical view combining item-level revenue, freight, category,
-- customer location, seller location, and order status.
CREATE OR REPLACE VIEW vw_order_item_analysis AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS product_category,
    oi.seller_id,
    s.seller_city,
    s.seller_state,
    o.customer_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    oi.price,
    oi.freight_value,
    oi.price * 0.60 AS estimated_cost,
    oi.price - (oi.price * 0.60) - oi.freight_value AS estimated_profit,
    CASE
        WHEN oi.price > 0 THEN ((oi.price - (oi.price * 0.60) - oi.freight_value) / oi.price) * 100
        ELSE NULL
    END AS estimated_profit_margin_pct
FROM stg_order_items oi
LEFT JOIN stg_orders o
    ON oi.order_id = o.order_id
LEFT JOIN stg_products p
    ON oi.product_id = p.product_id
LEFT JOIN stg_product_category_translation t
    ON p.product_category_name = t.product_category_name
LEFT JOIN stg_sellers s
    ON oi.seller_id = s.seller_id
LEFT JOIN stg_customers c
    ON o.customer_id = c.customer_id;

-- Analytical view restricted to delivered item-level orders for core analysis.
CREATE OR REPLACE VIEW vw_delivered_order_items AS
SELECT *
FROM vw_order_item_analysis
WHERE order_status = 'delivered';

-- Analytical view restricted to canceled or unavailable orders for loss analysis.
CREATE OR REPLACE VIEW vw_canceled_unavailable_order_items AS
SELECT *
FROM vw_order_item_analysis
WHERE order_status IN ('canceled', 'unavailable');
