{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['vehicle_id','version_number'],
    merge_update_columns=['valid_to']
  )
}}

select
    vehicle_id,
    version_id AS version_number,
    owner_id AS driver_id,
    make AS vehicle_make,
    model AS vehicle_model,
    horsepower,
    torque,
    redline AS redline_rpm,
    engine_layout,
    engine_cylinders,
    engine_displacement,
    force_induction,
    boost_pressure,
    gearbox_type,
    gear_count,
    drivetrain,
    length AS vehicle_length,
    width AS vehicle_width,
    height AS vehicle_height,
    wheelbase AS vehicle_wheelbase,
    wheel_diameter,
    wheel_width,
    wheel_weight,
    curb_weight,
    tires,
    valid_from,
    valid_to
FROM {{ source('silver', 'vehicles') }}
{% if is_incremental() %}
WHERE (vehicle_id,version_id) NOT IN (SELECT DISTINCT vehicle_id, version_number FROM {{ this }})
{% endif %}