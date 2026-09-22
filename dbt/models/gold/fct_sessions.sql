{{
  config(
    liquid_clustering = ['session_id','lap']
  )
}}

with telemetry_laps as (
    select
        session_id,
        max(lap) as max_laps
    from {{ source('silver', 'telemetry') }}
    group by session_id
)

select
    s.session_id,
    s.driver_id,
    s.vehicle_id,
    s.track_id,
    cast(s.start_time as date) as session_date,
    s.start_time as session_start_ts,
    s.end_time as session_end_ts,
    s.end_time is null as is_in_progress,
    timestampdiff(SECOND, s.start_time, s.end_time) as session_duration_seconds,
    tl.max_laps as laps_completed
from {{ source('silver', 'sessions') }} s
left join telemetry_laps tl
    on s.session_id = tl.session_id