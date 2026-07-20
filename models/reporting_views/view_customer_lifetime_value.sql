{{ config(
    materialized='view',
    schema='REPORT_VIEWS'
) }}
SELECT
    c.customer_id,
    c.full_name,
    c.customer_segment,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.total_sales_amount) AS customer_lifetime_value,
    AVG(f.total_sales_amount) AS average_order_value,
    MIN(d.full_date) AS first_purchase_date,
    MAX(d.full_date) AS last_purchase_date
FROM {{ ref('fact_sales') }} f
JOIN {{ ref('dim_customer') }} c
    ON f.customer_key = c.customer_key
JOIN {{ ref('dim_date') }} d
    ON f.date_key = d.date_key
GROUP BY
    c.customer_id,
    c.full_name,
    c.customer_segment