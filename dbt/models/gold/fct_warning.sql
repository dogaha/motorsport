{{
  config(
    materialized='incremental',
    incremental_strategy='append'
  )
}}

--depends_on: {{ ref('fct_sessions') }}
{{ generate_sensor_warnings() }}