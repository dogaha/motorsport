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

{% for row in sensor_rows %}
select
    s.session_id,
    s.driver_id,
    s.vehicle_id,
    s.track_id,
    t.timestamp * interval 1 second + s.session_start_ts as reading_ts,
    '{{ row.sensor_name }}' as sensor_name,
    t.{{ row.sensor_name }} as value,
    {{ row.min_valid }} as min_valid,
    {{ row.max_valid }} as max_valid,
    {{ row.normal_min }} as normal_min,
    {{ row.normal_max }} as normal_max
from {{ source('silver', 'telemetry') }} t
left join {{ ref('fct_sessions') }} s
    on t.session_id = s.session_id
where t.{{ row.sensor_name }} < {{ row.normal_min }}
   or t.{{ row.sensor_name }} > {{ row.normal_max }}
{% if not loop.last %} union all {% endif %}
{% endfor %}

{% endmacro %}