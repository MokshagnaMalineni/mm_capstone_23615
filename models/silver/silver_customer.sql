WITH customer_flattened AS (
    SELECT
        f.value:customer_id::STRING AS customer_id,
        f.value:first_name::STRING AS first_name,
        f.value:last_name::STRING AS last_name,
        f.value:email::STRING AS email,
        f.value:phone::STRING AS phone,
        f.value:birth_date::STRING AS birth_date,
        f.value:registration_date::STRING AS registration_date,
        f.value:last_purchase_date::STRING AS last_purchase_date,
        f.value:last_modified_date::STRING AS last_modified_date,
        f.value:income_bracket::STRING AS income_bracket,
        f.value:loyalty_tier::STRING AS loyalty_tier,
        f.value:occupation::STRING AS occupation,
        f.value:preferred_communication::STRING AS preferred_communication,
        f.value:preferred_payment_method::STRING AS preferred_payment_method,
        f.value:marketing_opt_in::BOOLEAN AS marketing_opt_in,
        f.value:total_purchases::NUMBER AS total_purchases,
        f.value:total_spend::NUMBER(18,2) AS total_spend,
        f.value:address.street::STRING AS street,
        f.value:address.city::STRING AS city,
        f.value:address.state::STRING AS state,
        f.value:address.country::STRING AS country,
        f.value:address.zip_code::STRING AS zip_code,
        _loaded_at,
        _source_file,
        _batch_id
    FROM {{ ref('bronze_customer') }},
    LATERAL FLATTEN(input => VALUE:customers_data) f
),

cleaned_data AS (

    SELECT
        TRIM(customer_id) AS customer_id,
        INITCAP(TRIM(first_name)) AS first_name,
        INITCAP(TRIM(last_name)) AS last_name,
        LOWER(TRIM(email)) AS email,
        REGEXP_REPLACE(
            REGEXP_REPLACE(UPPER(TRIM(phone)),'^\\+1\\s*',''),'[(). -]','') AS phone,
        COALESCE(
            TRY_TO_DATE(birth_date,'YYYY-MM-DD'),
            TRY_TO_DATE(birth_date,'MM/DD/YYYY'),
            TRY_TO_DATE(birth_date,'DD-MM-YYYY')
        ) AS birth_date,
        COALESCE(
            TRY_TO_DATE(registration_date,'YYYY-MM-DD'),
            TRY_TO_DATE(registration_date,'MM/DD/YYYY'),
            TRY_TO_DATE(registration_date,'DD-MM-YYYY')
        ) AS registration_date,
        COALESCE(
            TRY_TO_DATE(last_modified_date,'YYYY-MM-DD'),
            TRY_TO_DATE(last_modified_date,'MM/DD/YYYY'),
            TRY_TO_DATE(last_modified_date,'DD-MM-YYYY')
        ) AS last_modified_date,
        COALESCE(
            TRY_TO_DATE(last_purchase_date,'YYYY-MM-DD'),
            TRY_TO_DATE(last_purchase_date,'MM/DD/YYYY'),
            TRY_TO_DATE(last_purchase_date,'DD-MM-YYYY')
        ) AS last_purchase_date,
        UPPER(TRIM(income_bracket)) AS income_bracket,
        UPPER(TRIM(loyalty_tier)) AS loyalty_tier,
        INITCAP(TRIM(occupation)) AS occupation,
        INITCAP(TRIM(preferred_communication)) AS preferred_communication,
        INITCAP(TRIM(preferred_payment_method)) AS preferred_payment_method,
        COALESCE(marketing_opt_in,FALSE) AS marketing_opt_in,
        COALESCE(total_purchases,0) AS total_purchases,
        COALESCE(total_spend,0) AS total_spend,
        INITCAP(TRIM(street)) AS street,
        INITCAP(TRIM(city)) AS city,
        UPPER(TRIM(state)) AS state,
        UPPER(TRIM(country)) AS country,
        TRIM(zip_code) AS zip_code,
        _source_file,
        _loaded_at,
        _batch_id
    FROM customer_flattened
),
enriched_data AS (
    SELECT
        *,
        CONCAT(first_name,' ',last_name) AS full_name,
        DATEDIFF(
            YEAR,
            birth_date,
            CURRENT_DATE()
        ) AS customer_age,
        CASE
            WHEN DATEDIFF(YEAR,birth_date,CURRENT_DATE()) BETWEEN 18 AND 35
                THEN 'Young'
            WHEN DATEDIFF(YEAR,birth_date,CURRENT_DATE()) BETWEEN 36 AND 55
                THEN 'Middle-aged'
            WHEN DATEDIFF(YEAR,birth_date,CURRENT_DATE()) >= 56
                THEN 'Senior'
            ELSE 'Unknown'
        END AS customer_segment,
        CONCAT_WS(
            ', ',
            street,
            city,
            state,
            country,
            zip_code
        ) AS full_address
    FROM cleaned_data
),
latest_customer AS (

    SELECT *
    FROM enriched_data
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY
            last_modified_date DESC,
            _loaded_at DESC,
            _source_file DESC
    ) = 1
)
SELECT *
FROM latest_customer
WHERE customer_id IS NOT NULL