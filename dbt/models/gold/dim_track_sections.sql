{{
  config(
    materialized='incremental',
    incremental_strategy='append'
  )
}}

SELECT
  section_id,
  section_number,
  track_id,
  section_type,
  start_coordinate.x AS section_longitude,
  start_coordinate.y AS section_latitude
FROM {{ source('silver', 'track_sections') }}
{% if is_incremental() %}
WHERE section_id NOT IN (SELECT section_id FROM {{ this }})
{% endif %}