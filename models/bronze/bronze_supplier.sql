SELECT
    VALUE,
    CURRENT_TIMESTAMP() AS _loaded_at,
    METADATA$FILENAME AS _source_file,
    '{{ invocation_id }}' AS _batch_id
FROM {{ source('bronze','EX_SUPPLIER') }}