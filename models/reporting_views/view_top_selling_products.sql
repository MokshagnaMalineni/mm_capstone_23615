{{ config(
    materialized='view',
    schema='REPORT_VIEWS'
) }}

SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(f.quantity_sold) AS quantity_sold,
    SUM(f.total_sales_amount) AS total_sales,
    RANK() OVER (
        ORDER BY SUM(f.quantity_sold) DESC
    ) AS product_rank
FROM {{ ref('fact_sales') }} f
JOIN {{ ref('dim_product') }} p
    ON f.product_key = p.product_key
GROUP BY
    p.product_id,
    p.product_name,
    p.category