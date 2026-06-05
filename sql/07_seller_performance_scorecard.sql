-- =============================================================
-- File: 07_seller_performance_scorecard.sql
-- Purpose: Build seller-level performance scoring using revenue,
--          cancellation rate, reviews, delivery delay, and estimated
--          profit contribution.
--
-- Profit is estimated. Actual cost is not available in public data.
-- Assumption: cost = 60% of item price.
--
-- Output table for Power BI:
--     seller_scorecard_clean
-- =============================================================

USE ecommerce_analysis;

-- The imported Olist data can contain zero datetime placeholders.
-- Relax this session so MySQL can read those rows while the query
-- explicitly excludes zero dates from delay calculations.
SET SESSION sql_mode = '';

DROP TABLE IF EXISTS seller_scorecard_clean;

CREATE TABLE seller_scorecard_clean AS
WITH seller_base AS (
    SELECT
        oi.seller_id,
        COALESCE(s.seller_city, 'unknown') AS seller_city,
        COALESCE(s.seller_state, 'unknown') AS seller_state,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        ROUND(
            COALESCE(
                SUM(CASE
                    WHEN o.order_status = 'delivered' THEN oi.price
                    ELSE 0
                END),
                0
            ),
            2
        ) AS total_revenue,
        ROUND(
            COALESCE(
                COUNT(DISTINCT CASE
                    WHEN o.order_status IN ('canceled', 'unavailable') THEN oi.order_id
                END) / NULLIF(COUNT(DISTINCT oi.order_id), 0) * 100,
                0
            ),
            2
        ) AS cancellation_rate_pct,
        ROUND(COALESCE(AVG(r.review_score), 0), 2) AS avg_review_score,
        ROUND(
            COALESCE(
                AVG(CASE
                    WHEN o.order_status = 'delivered'
                         AND o.order_delivered_customer_date IS NOT NULL
                         AND o.order_estimated_delivery_date IS NOT NULL
                         AND o.order_delivered_customer_date <> '0000-00-00 00:00:00'
                         AND o.order_estimated_delivery_date <> '0000-00-00 00:00:00'
                    THEN DATEDIFF(
                        o.order_delivered_customer_date,
                        o.order_estimated_delivery_date
                    )
                END),
                0
            ),
            2
        ) AS avg_delay_days,
        ROUND(
            COALESCE(
                SUM(CASE
                    WHEN o.order_status = 'delivered'
                    THEN oi.price - (oi.price * 0.60) - oi.freight_value
                    ELSE 0
                END),
                0
            ),
            2
        ) AS estimated_profit_contribution
    FROM stg_order_items oi
    LEFT JOIN stg_orders o
        ON oi.order_id = o.order_id
    LEFT JOIN stg_sellers s
        ON oi.seller_id = s.seller_id
    LEFT JOIN stg_order_reviews r
        ON oi.order_id = r.order_id
    WHERE oi.seller_id IS NOT NULL
    GROUP BY oi.seller_id, s.seller_city, s.seller_state
),
seller_tiers AS (
    SELECT
        *,
        CASE
            WHEN cancellation_rate_pct > 20
                 OR avg_review_score < 3
                 OR avg_delay_days > 7
                THEN 'Poor'
            WHEN cancellation_rate_pct < 10
                 AND avg_review_score > 4
                 AND avg_delay_days <= 3
                THEN 'Good'
            ELSE 'Average'
        END AS performance_tier,
        PERCENT_RANK() OVER (ORDER BY total_revenue) AS revenue_percent_rank
    FROM seller_base
)
SELECT
    CAST(seller_id AS CHAR(50)) AS seller_id,
    CAST(seller_city AS CHAR(100)) AS seller_city,
    CAST(seller_state AS CHAR(10)) AS seller_state,
    CAST(total_revenue AS DECIMAL(12,2)) AS total_revenue,
    CAST(total_orders AS UNSIGNED) AS total_orders,
    CAST(cancellation_rate_pct AS DECIMAL(12,2)) AS cancellation_rate_pct,
    CAST(avg_review_score AS DECIMAL(12,2)) AS avg_review_score,
    CAST(avg_delay_days AS DECIMAL(12,2)) AS avg_delay_days,
    CAST(estimated_profit_contribution AS DECIMAL(12,2)) AS estimated_profit_contribution,
    TRIM(CAST(performance_tier AS CHAR(20))) AS performance_tier,
    CAST(
        RANK() OVER (
            PARTITION BY performance_tier
            ORDER BY total_revenue DESC
        ) AS UNSIGNED
    ) AS tier_revenue_rank,
    CAST(
        CASE
            WHEN revenue_percent_rank <= 0.10 THEN 'At Risk'
            ELSE 'Normal'
        END AS CHAR(20)
    ) AS revenue_risk_flag
FROM seller_tiers;

-- Export this result to Power BI as seller_scorecard.csv.
SELECT *
FROM seller_scorecard_clean
ORDER BY performance_tier, tier_revenue_rank;

-- Validation check: Poor should not be blank if this returns a Poor count.
SELECT
    performance_tier,
    COUNT(*) AS seller_count
FROM seller_scorecard_clean
GROUP BY performance_tier
ORDER BY performance_tier;
