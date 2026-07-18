{{ config(
    materialized='view',
    schema='REPORT_VIEWS'
) }}

SELECT
    s.region,
    e.employee_id,
    e.full_name,
    e.role,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.total_sales_amount) AS total_sales,
    SUM(f.profit_amount) AS total_profit,
    RANK() OVER (
        PARTITION BY s.region
        ORDER BY SUM(f.total_sales_amount) DESC
    ) AS employee_rank
FROM {{ ref('fact_sales') }} f
JOIN {{ ref('dim_employee') }} e
    ON f.employee_key = e.employee_key
JOIN {{ ref('dim_store') }} s
    ON f.store_key = s.store_key
GROUP BY
    s.region,
    e.employee_id,
    e.full_name,
    e.role