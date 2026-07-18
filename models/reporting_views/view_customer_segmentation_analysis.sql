{{ config(
    materialized='view',
    schema='REPORT_VIEWS'
) }}

SELECT
    c.customer_segment,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    SUM(f.total_sales_amount) AS total_sales,
    AVG(f.total_sales_amount) AS average_sales,
    SUM(f.profit_amount) AS total_profit
FROM {{ ref('fact_sales') }} f
JOIN {{ ref('dim_customer') }} c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_segment
ORDER BY total_sales DESC