{{
  config(
    materialized='incremental',
    incremental_strategy='append'
  )
}}

SELECT
  track_id,
  name AS track_name,
  city AS track_city,
  state AS track_state,
  CONCAT(city,', ',state) AS track_location,
  lap_length AS track_length_miles
FROM {{ source('silver','tracks') }}
{% if is_incremental() %}
WHERE track_id NOT IN (SELECT track_id FROM {{ this }})
{% endif %}