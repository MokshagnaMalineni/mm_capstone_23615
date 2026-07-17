SELECT
    {{ dbt_utils.generate_surrogate_key(['product_id']) }} AS product_key,
    product_id,
    product_name,
    category,
    subcategory,
    brand,
    color,
    size,
    TRY_TO_DECIMAL(
        REGEXP_SUBSTR(weight, '[0-9]+(\.[0-9]+)?'),
        10,
        2
    ) AS weight_kg,
    unit_price,
    cost_price,
    supplier_id,
    stock_quantity,
    low_stock_flag
FROM {{ ref('silver_products') }}