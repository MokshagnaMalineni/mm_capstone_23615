WITH order_lines AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.product_id,
        o.store_id,
        o.employee_id,
        o.order_date,
        o.quantity,
        o.unit_price,
        o.cost_price,
        o.item_discount_amount,
        o.shipping_cost,
        o.order_source,
        COUNT(*) OVER (PARTITION BY o.order_id) AS line_count
    FROM {{ ref('silver_orders') }} o
)

SELECT
    {{ dbt_utils.generate_surrogate_key([
        'ol.order_id',
        'ol.product_id'
    ]) }} AS sales_key,
    ol.order_id,

    c.customer_key,
    p.product_key,
    s.store_key,
    d.date_key,
    e.employee_key,

    ol.quantity AS quantity_sold,
    ol.unit_price,

    ROUND(ol.quantity * ol.unit_price,2) AS total_sales_amount,
    ROUND(ol.quantity * p.cost_price,2) AS cost_amount,
    ROUND(COALESCE(ol.item_discount_amount,0)/ NULLIF(ol.line_count,0),2) AS discount_amount,
    ROUND(COALESCE(ol.shipping_cost,0)/ NULLIF(ol.line_count,0),2) AS shipping_cost,
    ROUND(((ol.quantity * ol.unit_price)-(ol.quantity * p.cost_price)-
                    (COALESCE(ol.item_discount_amount,0)/ NULLIF(ol.line_count,0))-
                    (COALESCE(ol.shipping_cost,0)/ NULLIF(ol.line_count,0))),2) AS profit_amount,
    s.region,
    CASE
        WHEN LOWER(ol.order_source) IN
            ('website','online','mobile app','app')
        THEN 'Online'
        ELSE 'In-Store'
    END AS sales_channel,
    c.customer_segment AS customer_segment_impact
FROM order_lines ol

LEFT JOIN {{ ref('dim_customer') }} c
    ON ol.customer_id = c.customer_id
    AND c.is_current = TRUE

LEFT JOIN {{ ref('dim_product') }} p
    ON ol.product_id = p.product_id

LEFT JOIN {{ ref('dim_store') }} s
    ON ol.store_id = s.store_id

LEFT JOIN {{ ref('dim_employee') }} e
    ON ol.employee_id = e.employee_id

LEFT JOIN {{ ref('dim_date') }} d
    ON CAST(ol.order_date AS DATE) = d.full_date