SELECT
    track_id,
    name as track_name,
    city as track_city,
    state as track_state,
    CONCAT(city,', ',state) AS track_location,
    lap_length AS track_length_miles
FROM {{ source('silver','tracks') }}