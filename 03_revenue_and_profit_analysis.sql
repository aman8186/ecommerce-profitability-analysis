-- =============================================================
-- File: 03_revenue_and_profit_analysis.sql
-- Purpose: Analyze revenue, estimated profit, category profitability,
--          month-over-month revenue, and running revenue.
--
-- Profit is estimated. Actual cost not available in public dataset.
-- Assumption: cost = 60% of item price.
-- =============================================================

USE ecommerce_analysis;

-- Total revenue from delivered item prices.
SELECT
    ROUND(SUM(price), 2) AS total_revenue
FROM delivered_orders;

-- Total delivered orders based on distinct order IDs.
SELECT
    COUNT(DISTINCT order_id) AS total_orders
FROM delivered_orders;

-- Average order value calculated at order level to avoid item-count bias.
SELECT
    ROUND(AVG(order_revenue), 2) AS average_order_value
FROM (
    SELECT order_id, SUM(price) AS order_revenue
    FROM delivered_orders
    GROUP BY order_id
) order_totals;

-- Top 10 product categories by delivered revenue.
SELECT
    product_category,
    ROUND(SUM(price), 2) AS total_revenue
FROM delivered_orders
GROUP BY product_category
ORDER BY total_revenue DESC
LIMIT 10;

-- Bottom 10 product categories by delivered revenue.
SELECT
    product_category,
    ROUND(SUM(price), 2) AS total_revenue
FROM delivered_orders
GROUP BY product_category
ORDER BY total_revenue ASC
LIMIT 10;

-- Estimated profit and profit margin by product category.
SELECT
    product_category,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(SUM(price * 0.60), 2) AS estimated_cost,
    ROUND(SUM(price - (price * 0.60) - freight_value), 2) AS estimated_profit,
    ROUND((SUM(price - (price * 0.60) - freight_value) / NULLIF(SUM(price), 0)) * 100, 2) AS estimated_profit_margin_pct
FROM delivered_orders
GROUP BY product_category
ORDER BY estimated_profit_margin_pct DESC;

-- Month-over-month revenue trend using DATE_FORMAT.
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    ROUND(SUM(price), 2) AS monthly_revenue
FROM delivered_orders
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;

-- Running total revenue by month using a window function.
SELECT
    order_month,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY order_month), 2) AS running_total_revenue
FROM (
    SELECT
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
        SUM(price) AS monthly_revenue
    FROM delivered_orders
    GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
) monthly_revenue_summary
ORDER BY order_month;
