SELECT
    {{ dbt_utils.generate_surrogate_key(['customer_id','dbt_valid_from']) }} AS customer_key,
    customer_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    email,
    phone,
    street,
    city,
    state,
    country,
    zip_code,
    birth_date,
    income_bracket,
    occupation,
    loyalty_tier,
    preferred_communication,
    preferred_payment_method,
    marketing_opt_in,
    customer_segment,
    registration_date,
    dbt_valid_from AS valid_from,
    dbt_valid_to AS valid_to,
    CASE
        WHEN dbt_valid_to IS NULL THEN TRUE
        ELSE FALSE
    END AS is_current
FROM {{ ref('customer_snapshot') }}