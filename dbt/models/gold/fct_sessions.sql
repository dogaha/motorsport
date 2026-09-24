{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='session_id',
    merge_update_columns=['session_end_ts', 'session_duration_seconds']
  )
}}

WITH vehicles AS (
  SELECT vehicle_id, version_number, valid_from, valid_to
  FROM {{ ref('dim_vehicles') }}
)
{% if is_incremental() %}
, current_state AS (
  SELECT session_id, session_end_ts FROM {{ this }}
)
{% endif %}

SELECT
    s.session_id,
    s.driver_id,
    s.vehicle_id,
    v.version_number as vehicle_version_number,
    s.track_id,
    CAST(s.start_time AS DATE) AS session_date,
    s.start_time AS session_start_ts,
    s.end_time AS session_end_ts,
    TIMESTAMPDIFF(SECOND, s.start_time, s.end_time) AS session_duration_seconds
FROM {{ source('silver', 'sessions') }} s
LEFT JOIN vehicles v
  ON s.vehicle_id = v.vehicle_id
 AND s.start_time BETWEEN v.valid_from AND COALESCE(v.valid_to, NOW())
{% if is_incremental() %}
WHERE s.session_id NOT IN (SELECT session_id FROM current_state)
   OR s.session_id IN (SELECT session_id FROM current_state WHERE session_end_ts IS NULL)
{% endif %}