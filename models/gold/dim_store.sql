SELECT
    {{ dbt_utils.generate_surrogate_key(['store_id']) }} AS store_key,
    store_id,
    store_name,
    street,
    city, 
    state, 
    country, 
    zip_code,
    CONCAT(
        street, ', ',
        city, ', ',
        state, ', ',
        country, ' - ',
        zip_code
    ) AS address,
    region,
    store_type,
    opening_date,
    store_size_category,
    is_active

FROM {{ ref('silver_stores') }}