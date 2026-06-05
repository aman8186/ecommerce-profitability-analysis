-- =============================================================
-- File: 02_data_cleaning.sql
-- Purpose: Validate imported Olist staging data and create cleaned
--          tables for delivered orders and cancellation loss analysis.
--
-- Profit assumption for later analysis:
-- estimated_cost = 60% of item price because actual product cost is
-- not available in the public Olist dataset.
-- =============================================================

USE ecommerce_analysis;

-- Imported CSV date blanks can become zero datetime placeholders in MySQL.
-- Keep this session permissive and explicitly filter zero dates where needed.
SET SESSION sql_mode = '';

-- Check NULL counts for key columns in the orders table.
SELECT
    SUM(order_id IS NULL) AS null_order_id,
    SUM(customer_id IS NULL) AS null_customer_id,
    SUM(order_status IS NULL) AS null_order_status,
    SUM(order_purchase_timestamp IS NULL) AS null_purchase_timestamp,
    SUM(order_delivered_customer_date IS NULL) AS null_delivered_customer_date,
    SUM(order_estimated_delivery_date IS NULL) AS null_estimated_delivery_date
FROM stg_orders;

-- Check NULL counts for key columns in the order items table.
SELECT
    SUM(order_id IS NULL) AS null_order_id,
    SUM(product_id IS NULL) AS null_product_id,
    SUM(seller_id IS NULL) AS null_seller_id,
    SUM(price IS NULL) AS null_price,
    SUM(freight_value IS NULL) AS null_freight_value
FROM stg_order_items;

-- Check NULL counts for key columns in supporting dimension tables.
SELECT
    (SELECT SUM(product_id IS NULL) FROM stg_products) AS null_product_id,
    (SELECT SUM(product_category_name IS NULL) FROM stg_products) AS null_product_category,
    (SELECT SUM(seller_id IS NULL) FROM stg_sellers) AS null_seller_id,
    (SELECT SUM(customer_id IS NULL) FROM stg_customers) AS null_customer_id,
    (SELECT SUM(review_score IS NULL) FROM stg_order_reviews) AS null_review_score,
    (SELECT SUM(payment_value IS NULL) FROM stg_order_payments) AS null_payment_value;

-- Check duplicate order IDs in the order header table.
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM stg_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Validate delivered date completeness by status. Canceled and unavailable
-- records may not have delivery dates, so they are analyzed separately.
SELECT
    order_status,
    COUNT(*) AS total_orders,
    SUM(order_delivered_customer_date IS NULL) AS missing_delivered_date_orders
FROM stg_orders
GROUP BY order_status
ORDER BY missing_delivered_date_orders DESC;

-- Flag records where delivered date is NULL for review before analysis.
CREATE OR REPLACE VIEW vw_orders_with_delivery_date_flags AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    CASE
        WHEN order_delivered_customer_date IS NULL THEN 'Missing Delivered Date'
        ELSE 'Delivered Date Available'
    END AS delivery_date_flag
FROM stg_orders;

-- Create canceled_orders as the cancellation loss proxy table.
-- Olist has no return table, so canceled/unavailable status is treated
-- only as cancellation loss, not return loss.
DROP TABLE IF EXISTS canceled_orders;
CREATE TABLE canceled_orders AS
SELECT *
FROM vw_order_item_analysis
WHERE order_status IN ('canceled', 'unavailable');

-- Create delivered_orders as the main analysis table using only delivered orders.
DROP TABLE IF EXISTS delivered_orders;
CREATE TABLE delivered_orders AS
SELECT *
FROM vw_order_item_analysis
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date <> '0000-00-00 00:00:00'
  AND order_estimated_delivery_date IS NOT NULL
  AND order_estimated_delivery_date <> '0000-00-00 00:00:00';

-- Confirm cleaned table record counts for analyst validation.
SELECT 'delivered_orders' AS table_name, COUNT(*) AS row_count FROM delivered_orders
UNION ALL
SELECT 'canceled_orders' AS table_name, COUNT(*) AS row_count FROM canceled_orders;
