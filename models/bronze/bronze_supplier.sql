SELECT
    VALUE,
    CURRENT_TIMESTAMP() AS _loaded_at,
    METADATA$FILENAME AS _source_file,
    '{{ invocation_id }}' AS _batch_id
FROM {{ source('bronze','EX_SUPPLIER') }}

{% if is_incremental() %}
where source_file not in (
    select distinct _source_file
    from {{ this }}
)
{% endif %}