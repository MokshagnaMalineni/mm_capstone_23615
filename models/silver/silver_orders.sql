with orders as (
 
    select
 
        o.value:order_id::string as order_id,
        o.value:customer_id::string as customer_id,
        o.value:store_id::string as store_id,
        o.value:employee_id::string as employee_id,
        o.value:campaign_id::string as campaign_id,
        initcap(trim(o.value:order_source::string))as order_source,
        initcap(trim(o.value:order_status::string))as order_status,
        initcap(trim(o.value:payment_method::string))as payment_method,
        initcap(trim(o.value:shipping_method::string))as shipping_method,
        try_to_timestamp(o.value:created_at::string)as created_at,
        try_to_timestamp(o.value:order_date::string)as order_date,
        try_to_timestamp(o.value:shipping_date::string)as shipping_date,
        try_to_timestamp(o.value:delivery_date::string)as delivery_date,
        try_to_timestamp(o.value:estimated_delivery_date::string) as estimated_delivery_date,
        round(o.value:discount_amount::number(18,2),2)as order_discount_amount,
        round(o.value:shipping_cost::number(18,2),2)as shipping_cost,
        round(o.value:tax_amount::number(18,2),2)as tax_amount,
        round(o.value:total_amount::number(18,2),2)as total_amount,
        o.value:order_items as order_items,
        _loaded_at,
        _source_file,
        _batch_id
    from {{ ref('bronze_orders') }},
 
    lateral flatten(
        input => value:orders_data
    ) o
),
 
items as (
    select
        ord.*,
        i.value:product_id::string as product_id,
        i.value:quantity::number
            as quantity,
        round(
            i.value:unit_price::number(18,2),
            2
        ) as unit_price,
        round(
            i.value:cost_price::number(18,2),
            2
        ) as cost_price,
        round(
            i.value:discount_amount::number(18,2),
            2
        ) as item_discount_amount
 
    from orders ord,
 
    lateral flatten(
        input => ord.order_items
    ) i
 
),
aggregated as (
 
    select
        order_id,
        customer_id,
        store_id,
        employee_id,
        campaign_id,
        product_id,  
        order_source,
        order_status,
        payment_method,
        shipping_method,
        created_at,
        order_date,
        shipping_date,
        delivery_date,
        estimated_delivery_date,
        quantity,
        unit_price,
        cost_price,
        item_discount_amount
        order_discount_amount,
        shipping_cost,
        tax_amount,
        total_amount,
        count(product_id)as total_items,
        sum(quantity)as total_quantity,
        round( sum(quantity * unit_price), 2) as gross_line_revenue,
        round(sum(quantity * cost_price), 2) as gross_line_cost,
        round(sum(item_discount_amount),2) as item_discount_total,
        round( sum( quantity* unit_price* (1 - (item_discount_amount / 100))),2) as line_revenue,
        round(sum(quantity * cost_price),2) as line_cost,
        _loaded_at,
        _source_file,
        _batch_id
    from items
    group by all
),
 
final as (
    select
    *,
    round(((line_revenue* (1 - (order_discount_amount / 100)))
                - line_cost
                - shipping_cost
                - tax_amount
            ),2) as profit_amount,
    round(case
                when line_revenue > 0
                then((
                            ( line_revenue
                             * (1 - (order_discount_amount / 100))
                            )
                            - line_cost
                            - shipping_cost
                            - tax_amount
                        ) / line_revenue
                    ) * 100
                else null
            end,2) as profit_margin_percentage,
        date_part(
            hour,
            order_date
        ) as order_hour,
        case
            when date_part(hour, order_date) >= 5
             and date_part(hour, order_date) < 12
                then 'Morning'
            when date_part(hour, order_date) >= 12
             and date_part(hour, order_date) < 17
                then 'Afternoon'
            when date_part(hour, order_date) >= 17
             and date_part(hour, order_date) < 22
                then 'Evening'
            else 'Night'
        end as order_time_of_day,
        week(order_date)
            as order_week,
        month(order_date)
            as order_month,
        quarter(order_date)
            as order_quarter,
        year(order_date)
            as order_year,
        datediff(
            day,
            order_date,
            shipping_date
        ) as processing_days,
        datediff(
            day,
            shipping_date,
            delivery_date
        ) as shipping_days,
        case
            when delivery_date is not null
                 and delivery_date <= estimated_delivery_date
 
                then 'On Time'
 
            when delivery_date is not null
                 and delivery_date > estimated_delivery_date
 
                then 'Delayed'
 
            when delivery_date is null
                 and current_date() > estimated_delivery_date
 
                then 'Potentially Delayed'
 
            else 'In Transit'
 
        end as delivery_status
    from aggregated
)
select *
 
from final
qualify row_number() over (
    partition by order_id
    order by created_at desc
) = 1