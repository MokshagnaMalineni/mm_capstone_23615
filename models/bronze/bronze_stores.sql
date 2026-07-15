{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='store_id'
) }}

SELECT
    VALUE,
    CURRENT_TIMESTAMP() AS _loaded_at,
    METADATA$FILENAME AS _source_file
FROM {{ source('bronze','EXT_STORE') }}