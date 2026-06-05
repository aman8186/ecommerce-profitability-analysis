-- =============================================================
-- File: 05_freight_trap_analysis.sql
-- Purpose: Identify categories where real freight cost creates a
--          profitability trap. This replaces discount trap analysis
--          because the Olist dataset has no discount column.
--
-- Profit is estimated. Actual cost not available in public dataset.
-- Assumption: cost = 60% of item price.
-- =============================================================

USE ecommerce_analysis;

-- Category-level freight and estimated profitability classification.
SELECT
    product_category,
    ROUND(AVG(freight_value), 2) AS average_freight_value,
    ROUND(AVG(price), 2) AS average_price,
    ROUND((SUM(freight_value) / NULLIF(SUM(price), 0)) * 100, 2) AS freight_percentage,
    ROUND((SUM(price - (price * 0.60) - freight_value) / NULLIF(SUM(price), 0)) * 100, 2) AS estimated_profit_margin,
    ROUND(SUM(price), 2) AS total_revenue,
    CASE
        WHEN (SUM(freight_value) / NULLIF(SUM(price), 0)) * 100 > 15
             AND (SUM(price - (price * 0.60) - freight_value) / NULLIF(SUM(price), 0)) * 100 < 10
            THEN 'Freight Trap'
        WHEN (SUM(freight_value) / NULLIF(SUM(price), 0)) * 100 < 10
             AND (SUM(price - (price * 0.60) - freight_value) / NULLIF(SUM(price), 0)) * 100 > 20
            THEN 'Healthy'
        ELSE 'Monitor'
    END AS freight_trap_flag
FROM delivered_orders
GROUP BY product_category
ORDER BY freight_percentage DESC;
