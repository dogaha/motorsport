{{
  config(
    liquid_clustering = ['session_id']
  )
}}

--depends_on: {{ ref('fct_sessions') }}
{{ generate_sensor_warnings() }}