select
    s.session_id,
    s.driver_id,
    s.vehicle_id,
    s.track_id,
    t.lap,
    t.section_number,
    max(t.elapsed_seconds) - min(t.elapsed_seconds) as section_duration_seconds
from {{ source('silver', 'telemetry') }} t
left join {{ source('silver', 'sessions') }} s
    on t.session_id = s.session_id
group by s.session_id, s.driver_id, s.vehicle_id, s.track_id, t.lap, t.section_number