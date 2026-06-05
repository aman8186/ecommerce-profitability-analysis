-- =============================================================
-- File: 06_delivery_delay_analysis.sql
-- Purpose: Measure delivery delay patterns for delivered orders only.
-- Positive delay_days = late, negative = early, zero = on time.
-- =============================================================

USE ecommerce_analysis;

-- State-level delivery delay summary ranked by average delay.
SELECT
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)), 2) AS avg_delay_days,
    COUNT(DISTINCT CASE WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) > 0 THEN order_id END) AS delayed_orders,
    COUNT(DISTINCT CASE WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) < 0 THEN order_id END) AS early_orders,
    ROUND(
        COUNT(DISTINCT CASE WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) > 0 THEN order_id END)
        / NULLIF(COUNT(DISTINCT order_id), 0) * 100,
        2
    ) AS delayed_order_pct,
    RANK() OVER (
        ORDER BY AVG(DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)) DESC
    ) AS delay_rank
FROM delivered_orders
GROUP BY customer_state
ORDER BY delay_rank
LIMIT 10;

-- Overall on-time versus delayed order count.
SELECT
    CASE
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) > 0 THEN 'Delayed'
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) = 0 THEN 'On Time'
        ELSE 'Early'
    END AS delivery_status,
    COUNT(DISTINCT order_id) AS order_count
FROM delivered_orders
GROUP BY
    CASE
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) > 0 THEN 'Delayed'
        WHEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) = 0 THEN 'On Time'
        ELSE 'Early'
    END
ORDER BY order_count DESC;
