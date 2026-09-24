--depends_on: telemetry

{{
  config(
    materialized='incremental',
    incremental_strategy='append'
  )
}}

with section_durations as (
    select
        session_id,
        lap,
        section_number,
        max(timestamp) - min(timestamp) as section_duration_seconds,
        max(_ingested_at) as _ingested_at
    from {{ source('silver', 'telemetry') }}
    {% if is_incremental() %}
    where _ingested_at > (select coalesce(max(_silver_ingested_at), timestamp('1970-01-01')) from {{ this }})
    {% endif %}
    group by session_id, lap, section_number
)

select
    s.session_id,
    s.driver_id,
    s.vehicle_id,
    s.track_id,
    sd.lap,
    sd.section_number,
    sd.section_duration_seconds,
    concat(
        lpad(cast(floor(sd.section_duration_seconds / 60) as string), 2, '0'), ':',
        lpad(cast(floor(sd.section_duration_seconds % 60) as string), 2, '0'), '.',
        lpad(cast(round((sd.section_duration_seconds - floor(sd.section_duration_seconds)) * 1000) as string), 3, '0')
    ) as section_duration_display,
    sd._ingested_at as _silver_ingested_at,
    NOW() as _ingested_at
from section_durations sd
left join {{ ref('fct_sessions') }} s
    on sd.session_id = s.session_id