select
    session_id,
    driver_id,
    vehicle_id,
    track_id,
    cast(start_time as date) as session_date,
    start_time as session_start_ts,
    end_time as session_end_ts,
    end_time is null as is_in_progress,
    timestampdiff(SECOND, start_time, end_time) as session_duration_seconds
from {{ source('silver', 'sessions') }}