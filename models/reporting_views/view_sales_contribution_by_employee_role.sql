{{ config(
    materialized='view',
    schema='REPORT_VIEWS'
) }}
SELECT
    e.role,
    COUNT(DISTINCT e.employee_id) AS total_employees,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.total_sales_amount) AS total_sales,
    SUM(f.profit_amount) AS total_profit,
    AVG(f.total_sales_amount) AS avg_sales_per_order
FROM {{ ref('fact_sales') }} f
JOIN {{ ref('dim_employee') }} e
    ON f.employee_key = e.employee_key
GROUP BY
    e.role
ORDER BY
    total_sales DESC