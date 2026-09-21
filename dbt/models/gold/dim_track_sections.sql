select
    section_id,
    section_number,
    track_id,
    section_type,
    start_coordinate.x as section_longitude,
    start_coordinate.y as section_latitude
from {{ source('silver', 'track_sections') }}