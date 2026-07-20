{{ config(
    materialized='view',
    schema='REPORT_VIEWS'
) }}

SELECT
    p.category,
    p.subcategory,
    SUM(f.quantity_sold) AS total_quantity_sold,
    SUM(f.total_sales_amount) AS total_sales,
    SUM(f.profit_amount) AS total_profit
FROM {{ ref('fact_sales') }} f
JOIN {{ ref('dim_product') }} p
    ON f.product_key = p.product_key
GROUP BY
    p.category,
    p.subcategory