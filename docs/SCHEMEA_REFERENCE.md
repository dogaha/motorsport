# Schema Reference

Derived directly from sample rows. Types are inferred from the values
shown; verify against actual DDL/model `config` blocks for anything
marked `?`.

---

## Bronze

### `bronze.cdc_*` (one per CDC topic)

| Column      | Type      | Notes |
|-------------|-----------|-------|
| topic       | string    | e.g. `motorsport.public.track_sections` |
| partition   | int       | |
| offset      | long      | |
| kafka_ts    | timestamp | Kafka message timestamp |
| key         | string    | Raw Debezium key envelope (JSON) |
| value       | string    | Raw Debezium value envelope (JSON) — `payload.before/after/op/source`, PostGIS geometry columns arrive as `{x, y, wkb, srid}` structs |
| _ingested_at| timestamp | Bronze ingestion time |

### `bronze.telemetry`

| Column | Type | Notes |
|--------|------|-------|
| session_id | string (uuid) | |
| timestamp | double | Seconds from session start |
| latitude, longitude | double | |
| *(74 sensor columns)* | double | throttle_position, brake_position, steering_wheel_angle, steering_torque, gear_position, toe_angle, rpm, driveshaft_rpm, speed, brake_pressure, engine_oil_pressure, manifold_air_pressure, boost_pressure, fuel_pressure, engine_oil_temperature, manifold_air_temperature, exhaust_gas_temperature, coolant_temperature, transmission_fluid_temperature, cam_position, crank_position, knock_sensor, lambda_sensor, wastegate_position, fuel_flow, fuel_level, battery_voltage, battery_temperature, alternator_output, g_force_longitude, g_force_latitude, g_force_lateral, fl/fr/rl/rr_wheel_speed, fl/fr/rl/rr_wheel_load, fl/fr/rl/rr_shock_travel, fl/fr/rl/rr_ride_height, fl/fr/rl/rr_tire_pressure, fl/fr/rl/rr_tire_temperature, fl/fr/rl/rr_brake_temperature, pitot_tube, pressure_tap_front_wing/rear_wing/diffuser/splitter, kiel_probe_front_wing/rear_wing/diffuser, strain_rollcage/subframe/fl_suspension/fr_suspension/rl_suspension/rr_suspension, driver_heart_rate, driver_blood_oxygen, driver_core_body_temperature, driver_respiratory_rate |
| _rescued_data | string | Auto Loader rescued-data column (null in samples) |
| _source_file | string | `s3://motorsport-data-lake/landing/<session_id>.parquet` |
| _ingested_at | timestamp | |

---

## Silver

### `silver.drivers` (SCD1)

| Column | Type | Notes |
|--------|------|-------|
| driver_id | int | |
| first_name | string | |
| last_name | string | |
| dob | date | |
| weight | int | |

### `silver.tracks` (SCD1)

| Column | Type | Notes |
|--------|------|-------|
| track_id | int | |
| name | string | |
| state | string | |
| city | string | |
| lap_length | int | |

### `silver.track_sections` (SCD1)

| Column | Type | Notes |
|--------|------|-------|
| section_id | int | |
| section_number | int | |
| track_id | int | |
| section_type | string | |
| start_coordinate | struct\<x: double, y: double, srid: int\> | PostGIS `wkb` field dropped between bronze and silver |

### `silver.sessions` (SCD1)

| Column | Type | Notes |
|--------|------|-------|
| session_id | string (uuid) | |
| track_id | int | |
| vehicle_id | int | |
| driver_id | int | |
| start_time | timestamptz | |
| end_time | timestamptz | Null while in progress |

### `silver.vehicles` (SCD2)

| Column | Type | Notes |
|--------|------|-------|
| vehicle_id | int | Natural key — not unique alone |
| version_id | int | Per-vehicle sequence |
| valid_from | timestamptz | |
| valid_to | timestamptz | Null = current version (shown as `-` in export) |
| owner_id | int | FK to drivers |
| make, model | string | |
| horsepower, torque, redline | int | |
| engine_layout | string | |
| engine_cylinders, engine_displacement | int | |
| force_induction | string | |
| boost_pressure | int | |
| gearbox_type | string | |
| gear_count | int | |
| drivetrain | string | |
| length, width, height, wheelbase | int | |
| wheel_diameter, wheel_width, wheel_weight | int | |
| curb_weight | int | |
| tires | string | |

### `silver.telemetry` (append-only)

Same 74 sensor columns as bronze, plus:

| Column | Type | Notes |
|--------|------|-------|
| track_id | int | Joined from silver.sessions |
| section_number | int | Derived from GPS match to track_sections |
| lap | int | Derived |

---

## Gold (`motorsport.gold`, dbt incremental)

### `dim_drivers`

| Column | Type | Tests |
|--------|------|-------|
| driver_id | int | unique, not_null |
| driver_first_name | string | |
| driver_last_name | string | |
| driver_full_name | string | not_null |
| driver_dob | date | |
| driver_weight_lbs | int | |

### `dim_tracks`

| Column | Type | Tests |
|--------|------|-------|
| track_id | int | unique, not_null |
| track_name | string | |
| track_city | string | |
| track_state | string | |
| track_location | string | Derived: `city, state` |
| track_length_miles | int | not_null, > 0 |

### `dim_track_sections`

| Column | Type | Tests | Notes |
|--------|------|-------|-------|
| section_id | int | unique, not_null | |
| section_number | int | (track_id, section_number) unique | |
| track_id | int | not_null, → dim_tracks | |
| section_type | string | | **See open issue #1 below — casing inconsistent with silver** |
| section_longitude | int | | **See open issue #2 — likely swapped with latitude, and lossy vs. silver's double** |
| section_latitude | int | | Same |

### `dim_vehicles` (SCD2)

| Column | Type | Tests |
|--------|------|-------|
| vehicle_id | int | not_null; (vehicle_id, version_number) unique |
| version_number | int | |
| driver_id | int | → dim_drivers |
| vehicle_make, vehicle_model | string | |
| horsepower, torque, redline_rpm | int | |
| engine_layout | string | |
| engine_cylinders, engine_displacement | int | |
| force_induction | string | |
| boost_pressure | int | |
| gearbox_type, gear_count | string, int | |
| drivetrain | string | |
| vehicle_length, vehicle_width, vehicle_height, vehicle_wheelbase | int | |
| wheel_diameter, wheel_width, wheel_weight | int | |
| curb_weight | int | |
| tires | string | |
| valid_from | timestamptz | |
| valid_to | timestamptz | No overlapping versions; ≤1 open version per vehicle |

### `sensors` (dbt seed)

| Column | Type | Tests | Notes |
|--------|------|-------|-------|
| sensor_name | string | unique, not_null | |
| min_valid | double | | Physical limit |
| max_valid | double | | Physical limit |
| normal_min | double | | "Dangerous"-range floor — this answers the earlier open question; it lives on the seed itself |
| normal_max | double | | "Dangerous"-range ceiling |

### `fct_sessions`

| Column | Type | Tests |
|--------|------|-------|
| session_id | string (uuid) | unique, not_null |
| driver_id | int | → dim_drivers |
| vehicle_id | int | → dim_vehicles |
| track_id | int | not_null, → dim_tracks |
| session_date | date | |
| session_start_ts | timestamptz | |
| session_end_ts | timestamptz | Not null (closed-only) |
| session_duration_seconds | int | See open issue #3 — naming vs. earlier "approximate" column |

### `fct_section_times`

Grain: session, lap, section.

| Column | Type | Tests |
|--------|------|-------|
| session_id | string (uuid) | not_null, → fct_sessions; (session_id, lap, section_number) unique |
| driver_id | int | → dim_drivers |
| vehicle_id | int | → dim_vehicles |
| track_id | int | not_null, → dim_tracks |
| lap | int | |
| section_number | int | |
| section_duration_seconds | double | |
| section_duration_display | string | Formatted `MM:SS.mmm` |
| _silver_ingested_at | timestamp | Lineage |
| _ingested_at | timestamp | Lineage |

### `fct_warning`

Grain: session, sensor, reading — event fact (only out-of-range readings).

| Column | Type | Tests |
|--------|------|-------|
| session_id | string (uuid) | not_null, → fct_sessions; (session_id, sensor_name, reading_ts) unique |
| driver_id | int | → dim_drivers |
| vehicle_id | int | → dim_vehicles |
| track_id | int | not_null, → dim_tracks |
| reading_ts | timestamptz | |
| sensor_name | string | not_null, → sensors |
| value | double | The out-of-range reading |
| min_valid, max_valid | double | Denormalized from sensors, physical limit |
| normal_min, normal_max | double | Denormalized from sensors, "dangerous" threshold |
| _silver_ingested_at | timestamp | |
| _ingested_at | timestamp | |