with telemetry_laps as (
    select
        session_id,
        max(lap) as max_laps
    from {{ source('silver', 'telemetry') }}
    group by session_id
),

sessions_base as (
    select
        *,
        timestampdiff(SECOND, start_time, end_time) as session_duration_seconds
    from {{ source('silver', 'sessions') }}
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
    concat(
        lpad(cast(floor(s.session_duration_seconds / 3600) as string), 2, '0'), ':',
        lpad(cast(floor((s.session_duration_seconds % 3600) / 60) as string), 2, '0'), ':',
        lpad(cast(floor(s.session_duration_seconds % 60) as string), 2, '0'), '.',
        lpad(cast(round((s.session_duration_seconds - floor(s.session_duration_seconds)) * 1000) as string), 3, '0')
    ) as session_duration_display,
    tl.max_laps as laps_completed
from sessions_base s
left join telemetry_laps tl
    on s.session_id = tl.session_id