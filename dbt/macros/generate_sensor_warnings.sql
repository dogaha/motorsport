{% macro generate_sensor_warnings() %}

{% set sensor_query %}
    select sensor_name, min_valid, max_valid, normal_min, normal_max
    from {{ ref('sensors') }}
{% endset %}

{% set results = run_query(sensor_query) %}

{% if execute %}
    {% set sensor_rows = results.rows %}
{% else %}
    {% set sensor_rows = [] %}
{% endif %}

with base as (
    select
        t.session_id,
        t.timestamp,
        t._ingested_at,
        s.driver_id,
        s.vehicle_id,
        s.track_id,
        s.session_start_ts,
        stack(
            {{ sensor_rows | length }},
            {% for row in sensor_rows %}
            '{{ row.sensor_name }}', t.{{ row.sensor_name }}, cast({{ row.min_valid }} as double), cast({{ row.max_valid }} as double), cast({{ row.normal_min }} as double), cast({{ row.normal_max }} as double){% if not loop.last %},{% endif %}
            {% endfor %}
        ) as (sensor_name, value, min_valid, max_valid, normal_min, normal_max)
    from {{ source('silver', 'telemetry') }} t
    left join {{ ref('fct_sessions') }} s
        on t.session_id = s.session_id
    {% if is_incremental() %}
    and s.session_id in (
        select distinct session_id
        from {{ source('silver', 'telemetry') }}
        where _ingested_at > (select coalesce(max(_silver_ingested_at), timestamp('1970-01-01')) from {{ this }})
    )
    {% endif %}
)

select
    session_id,
    driver_id,
    vehicle_id,
    track_id,
    timestamp * interval 1 second + session_start_ts as reading_ts,
    sensor_name,
    value,
    min_valid,
    max_valid,
    normal_min,
    normal_max,
    _ingested_at AS _silver_ingested_at,
    NOW() AS _ingested_at
from base
where (value < normal_min or value > normal_max)
  and (value <= max_valid and value >= min_valid)

{% endmacro %}