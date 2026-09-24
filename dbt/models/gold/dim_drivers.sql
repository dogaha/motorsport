{{
  config(
    materialized='incremental',
    incremental_strategy='append'
  )
}}

SELECT
  driver_id,
  first_name AS driver_first_name,
  last_name AS driver_last_name,
  concat_ws(' ', first_name, last_name) AS driver_full_name,
  dob AS driver_dob,
  weight AS driver_weight_lbs
FROM {{ source('silver', 'drivers') }}
{% if is_incremental() %}
WHERE driver_id NOT IN (SELECT driver_id FROM {{ this }})
{% endif %}