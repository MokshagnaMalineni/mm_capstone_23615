{{ config(
    materialized='view',
    schema='REPORT_VIEWS'
) }}

SELECT
    employee_id,
    full_name,
    role,
    work_location,
    tenure_years,
    performance_rating,
    sales_target,
    current_sales,
    target_achievement_percentage,
    total_orders_processed,
    total_sales_amount,
    CASE
        WHEN tenure_years < 2 THEN '0-2 Years'
        WHEN tenure_years < 5 THEN '2-5 Years'
        WHEN tenure_years < 10 THEN '5-10 Years'
        ELSE '10+ Years'
    END AS tenure_group
FROM {{ ref('dim_employee') }}