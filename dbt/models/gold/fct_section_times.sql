{{
  config(
    liquid_clustering = ['session_id','lap']
  )
}}

with section_durations as (
    select
        session_id,
        lap,
        section_number,
        max(timestamp) - min(timestamp) as section_duration_seconds
    from {{ source('silver', 'telemetry') }}
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
        lpad(cast(round((sd.section_duration_seconds - floor(sd.section_duration_seconds)) * 1000) as string), 2, '0')
    ) as section_duration_display
from section_durations sd
left join {{ source('silver', 'sessions') }} s
    on sd.session_id = s.session_id