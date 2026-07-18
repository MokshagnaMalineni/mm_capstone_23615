{{ config(
    materialized='view',
    schema='REPORT_VIEWS'
) }}

SELECT
    c.customer_id,
    c.full_name,
    c.customer_segment,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.total_sales_amount) AS total_spent,
    AVG(f.total_sales_amount) AS average_order_value,
    SUM(f.quantity_sold) AS total_items_purchased
FROM {{ ref('fact_sales') }} f
JOIN {{ ref('dim_customer') }} c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_id,
    c.full_name,
    c.customer_segment