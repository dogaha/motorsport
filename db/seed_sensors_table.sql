-- Sensor validity ranges (mirrors source/constants.py LOG_FIELDS min/max).
-- Idempotent: safe to run on every start.
INSERT INTO sensors (sensor_name, min_valid, max_valid) VALUES
    -- 1. Driver Inputs
    ('throttle_position', 0.0, 100.0),
    ('brake_position', 0.0, 100.0),
    ('steering_wheel_angle', -180.0, 180.0),
    ('steering_torque', -25.0, 25.0),
    ('gear_position', 0.0, 8.0),
    ('toe_angle', -3.0, 3.0),

    -- 2. Powertrain & Vitals
    ('rpm', 800.0, 15000.0),
    ('driveshaft_rpm', 800.0, 15000.0),
    ('speed', 0.0, 360.0),

    -- 3. Pressures
    ('brake_pressure', 0.0, 120.0),
    ('engine_oil_pressure', 1.5, 7.0),
    ('manifold_air_pressure', 0.5, 3.5),
    ('boost_pressure', 0.5, 3.5),
    ('fuel_pressure', 3.0, 6.0),

    -- 4. Temperatures (Cooling & Exhaust)
    ('engine_oil_temperature', 70.0, 130.0),
    ('manifold_air_temperature', 20.0, 70.0),
    ('exhaust_gas_temperature', 400.0, 1050.0),
    ('coolant_temperature', 70.0, 110.0),
    ('transmission_fluid_temperature', 80.0, 140.0),

    -- 5. Engine Peripherals
    ('cam_position', 0.0, 360.0),
    ('crank_position', 0.0, 360.0),
    ('knock_sensor', 0.0, 5.0),
    ('lambda_sensor', 0.70, 1.10),
    ('wastegate_position', 0.0, 100.0),
    ('fuel_flow', 0.0, 100.0),
    ('fuel_level', 0.0, 110.0),

    -- 6. Electrical
    ('battery_voltage', 11.5, 14.8),
    ('battery_temperature', 20.0, 60.0),
    ('alternator_output', 0.0, 150.0),

    -- 7. Chassis Dynamics (G-Forces & Position)
    ('g_force_longitude', -5.0, 2.0),
    ('g_force_latitude', -4.0, 4.0),
    ('g_force_lateral', -4.0, 4.0),
    ('latitude', -90.0, 90.0),
    ('longitude', -180.0, 180.0),

    -- 8. Corner Assemblies
    ('fl_wheel_speed', 0.0, 370.0),
    ('fr_wheel_speed', 0.0, 370.0),
    ('rl_wheel_speed', 0.0, 370.0),
    ('rr_wheel_speed', 0.0, 370.0),

    ('fl_wheel_load', 100.0, 1500.0),
    ('fr_wheel_load', 100.0, 1500.0),
    ('rl_wheel_load', 100.0, 1500.0),
    ('rr_wheel_load', 100.0, 1500.0),

    ('fl_shock_travel', 0.0, 75.0),
    ('fr_shock_travel', 0.0, 75.0),
    ('rl_shock_travel', 0.0, 75.0),
    ('rr_shock_travel', 0.0, 75.0),

    ('fl_ride_height', 15.0, 80.0),
    ('fr_ride_height', 15.0, 80.0),
    ('rl_ride_height', 15.0, 80.0),
    ('rr_ride_height', 15.0, 80.0),

    ('fl_tire_pressure', 1.2, 2.5),
    ('fr_tire_pressure', 1.2, 2.5),
    ('rl_tire_pressure', 1.2, 2.5),
    ('rr_tire_pressure', 1.2, 2.5),

    ('fl_tire_temperature', 60.0, 120.0),
    ('fr_tire_temperature', 60.0, 120.0),
    ('rl_tire_temperature', 60.0, 120.0),
    ('rr_tire_temperature', 60.0, 120.0),

    ('fl_brake_temperature', 200.0, 1000.0),
    ('fr_brake_temperature', 200.0, 1000.0),
    ('rl_brake_temperature', 200.0, 1000.0),
    ('rr_brake_temperature', 200.0, 1000.0),

    -- 9. Aerodynamics
    ('pitot_tube', 0.0, 150.0),
    ('pressure_tap_front_wing', -50.0, 100.0),
    ('pressure_tap_rear_wing', -50.0, 100.0),
    ('pressure_tap_diffuser', -50.0, 100.0),
    ('pressure_tap_splitter', -50.0, 100.0),

    ('kiel_probe_front_wing', -50.0, 100.0),
    ('kiel_probe_rear_wing', -50.0, 100.0),
    ('kiel_probe_diffuser', -50.0, 100.0),

    -- 10. Structural Integrity
    ('strain_rollcage', -2000.0, 2000.0),
    ('strain_subframe', -2000.0, 2000.0),
    ('strain_fl_suspension', -2000.0, 2000.0),
    ('strain_fr_suspension', -2000.0, 2000.0),
    ('strain_rl_suspension', -2000.0, 2000.0),
    ('strain_rr_suspension', -2000.0, 2000.0),

    -- 11. Biometrics
    ('driver_heart_rate', 80.0, 190.0),
    ('driver_blood_oxygen', 90.0, 100.0),
    ('driver_core_body_temperature', 36.5, 39.5),
    ('driver_respiratory_rate', 15.0, 50.0)
ON CONFLICT (sensor_name) DO UPDATE
SET min_valid = EXCLUDED.min_valid,
    max_valid = EXCLUDED.max_valid;