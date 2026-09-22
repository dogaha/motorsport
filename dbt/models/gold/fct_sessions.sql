with telemetry_laps as (
    select
        session_id,
        max(lap) as max_laps
    from {{ source('silver', 'telemetry') }}
    group by session_id
)

select
    session_id,
    driver_id,
    vehicle_id,
    track_id,
    cast(start_time as date) as session_date,
    start_time as session_start_ts,
    end_time as session_end_ts,
    end_time is null as is_in_progress,
    timestampdiff(SECOND, start_time, end_time) as session_duration_seconds,
    tl.max_laps as laps_completed
from {{ source('silver', 'sessions') }} s
left join telemetry_laps tl
    on s.session_id = tl.session_id