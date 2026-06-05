-- =============================================================
-- File: 04_revenue_leakage_analysis.sql
-- Purpose: Estimate category-level revenue leakage from cancellation
--          loss, freight burden, and low-margin categories.
--
-- Profit is estimated. Actual cost not available in public dataset.
-- Assumption: cost = 60% of item price.
-- =============================================================

USE ecommerce_analysis;

WITH cancellation_loss AS (
    -- CTE 1: Revenue lost from canceled and unavailable orders by category.
    -- This is not return loss because Olist has no return data.
    SELECT
        product_category,
        ROUND(SUM(price), 2) AS cancellation_loss
    FROM canceled_orders
    GROUP BY product_category
),

freight_burden AS (
    -- CTE 2: Real freight cost and freight as percentage of revenue by category.
    SELECT
        product_category,
        ROUND(SUM(freight_value), 2) AS freight_burden_amount,
        ROUND((SUM(freight_value) / NULLIF(SUM(price), 0)) * 100, 2) AS freight_burden_pct
    FROM delivered_orders
    GROUP BY product_category
),

low_margin_loss AS (
    -- CTE 3: Categories where estimated profit margin is below 10%.
    -- low_margin_impact represents delivered revenue at risk in weak-margin categories.
    -- Assumption: estimated_cost = 60% of price.
    SELECT
        product_category,
        ROUND(SUM(price), 2) AS low_margin_revenue,
        ROUND(SUM(price - (price * 0.60) - freight_value), 2) AS estimated_profit,
        ROUND((SUM(price - (price * 0.60) - freight_value) / NULLIF(SUM(price), 0)) * 100, 2) AS estimated_profit_margin_pct,
        ROUND(SUM(price), 2) AS low_margin_impact
    FROM delivered_orders
    GROUP BY product_category
    HAVING (SUM(price - (price * 0.60) - freight_value) / NULLIF(SUM(price), 0)) * 100 < 10
)

-- Final: Join all 3 leakage sources and rank categories by total leakage.
SELECT
    product_category,
    cancellation_loss,
    freight_burden_amount,
    freight_burden_pct,
    low_margin_impact,
    total_leakage,
    RANK() OVER (ORDER BY total_leakage DESC) AS leakage_rank
FROM (
    SELECT
        categories.product_category,
        COALESCE(cl.cancellation_loss, 0) AS cancellation_loss,
        COALESCE(fb.freight_burden_amount, 0) AS freight_burden_amount,
        COALESCE(fb.freight_burden_pct, 0) AS freight_burden_pct,
        COALESCE(lm.low_margin_impact, 0) AS low_margin_impact,
        ROUND(
            COALESCE(cl.cancellation_loss, 0)
            + COALESCE(fb.freight_burden_amount, 0)
            + COALESCE(lm.low_margin_impact, 0),
            2
        ) AS total_leakage
    FROM (
        SELECT product_category FROM cancellation_loss
        UNION
        SELECT product_category FROM freight_burden
        UNION
        SELECT product_category FROM low_margin_loss
    ) categories
    LEFT JOIN cancellation_loss cl
        ON categories.product_category = cl.product_category
    LEFT JOIN freight_burden fb
        ON categories.product_category = fb.product_category
    LEFT JOIN low_margin_loss lm
        ON categories.product_category = lm.product_category
) AS leakage_summary
ORDER BY total_leakage DESC;
