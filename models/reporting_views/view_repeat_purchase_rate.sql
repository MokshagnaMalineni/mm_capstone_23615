{{ config(
    materialized='view',
    schema='REPORT_VIEWS'
) }}
WITH customer_orders AS (
    SELECT
        c.customer_id,
        COUNT(DISTINCT f.order_id) AS total_orders
    FROM {{ ref('fact_sales') }} f
    JOIN {{ ref('dim_customer') }} c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_id
)
SELECT
    COUNT(CASE WHEN total_orders > 1 THEN 1 END)
        AS repeat_customers,
    COUNT(*) AS total_customers,
    ROUND(COUNT(CASE WHEN total_orders > 1 THEN 1 END)* 100.0/ COUNT(*),2) AS repeat_purchase_rate_percentage
FROM customer_orders