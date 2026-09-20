LOG_HZ = 20
LIVE_HZ = 5

LIVE_FIELDS = [
    "session_id",
    "timestamp",
    "throttle_position",
    "brake_position",
    "toe_angle",
    "steering_wheel_angle",
    "gear_position",
    "rpm",
    "speed",
    "brake_pressure",
    "engine_oil_pressure",
    "engine_oil_temperature",
    "manifold_air_pressure",
    "exhaust_gas_temperature",
    "knock_sensor",
    "lambda_sensor",
    "boost_pressure",
    "fuel_pressure",
    "fuel_flow",
    "fuel_level",
    "coolant_temperature",
    "transmission_fluid_temperature",
    "battery_voltage",
    "battery_temperature",
    "g_force_longitude",
    "g_force_latitude",
    "g_force_lateral",
    "latitude",
    "longitude",
    "fl_wheel_speed",
    "fl_shock_travel",
    "fl_ride_height",
    "fl_tire_pressure",
    "fr_wheel_speed",
    "fr_shock_travel",
    "fr_ride_height",
    "fr_tire_pressure",
    "rl_wheel_speed",
    "rl_shock_travel",
    "rl_tire_pressure",
    "rl_ride_height",
    "rr_wheel_speed",
    "rr_shock_travel",
    "rr_ride_height",
    "rr_tire_pressure",
    "driver_heart_rate",
    "driver_blood_oxygen",
    "driver_core_body_temperature",
    "driver_respiratory_rate",
]
 
LOG_FIELDS = {
    # 1. Driver Inputs
    "throttle_position": {"min": 0.0, "max": 100.0, "spike_val": 255.0},
    "brake_position": {"min": 0.0, "max": 100.0, "spike_val": -1.0},
    "steering_wheel_angle": {"min": -180.0, "max": 180.0, "spike_val": 999.0},
    "steering_torque": {"min": -25.0, "max": 25.0, "spike_val": 99.0},
    "gear_position": {"min": 0.0, "max": 8.0, "spike_val": 99.0}, # Float to support np.nan
    "toe_angle": {"min": -3.0, "max": 3.0, "spike_val": 99.0},

    # 2. Powertrain & Vitals
    "rpm": {"min": 800.0, "max": 15000.0, "spike_val": -1000.0},
    "driveshaft_rpm": {"min": 800.0, "max": 15000.0, "spike_val": -1000.0},
    "speed": {"min": 0.0, "max": 360.0, "spike_val": -50.0},
    
    # 3. Pressures
    "brake_pressure": {"min": 0.0, "max": 120.0, "spike_val": -99.0},
    "engine_oil_pressure": {"min": 1.5, "max": 7.0, "spike_val": -10.0},
    "manifold_air_pressure": {"min": 0.5, "max": 3.5, "spike_val": -5.0},
    "boost_pressure": {"min": 0.5, "max": 3.5, "spike_val": -5.0},
    "fuel_pressure": {"min": 3.0, "max": 6.0, "spike_val": -5.0},

    # 4. Temperatures (Cooling & Exhaust)
    "engine_oil_temperature": {"min": 70.0, "max": 130.0, "spike_val": 999.0},
    "manifold_air_temperature": {"min": 20.0, "max": 70.0, "spike_val": 999.0},
    "exhaust_gas_temperature": {"min": 400.0, "max": 1050.0, "spike_val": 2000.0},
    "coolant_temperature": {"min": 70.0, "max": 110.0, "spike_val": 999.0},
    "transmission_fluid_temperature": {"min": 80.0, "max": 140.0, "spike_val": 999.0},

    # 5. Engine Peripherals
    "cam_position": {"min": 0.0, "max": 360.0, "spike_val": 999.0},
    "crank_position": {"min": 0.0, "max": 360.0, "spike_val": 999.0},
    "knock_sensor": {"min": 0.0, "max": 5.0, "spike_val": 99.0},
    "lambda_sensor": {"min": 0.70, "max": 1.10, "spike_val": 5.0},
    "wastegate_position": {"min": 0.0, "max": 100.0, "spike_val": -1.0},
    "fuel_flow": {"min": 0.0, "max": 100.0, "spike_val": -10.0},
    "fuel_level": {"min": 0.0, "max": 110.0, "spike_val": -10.0},

    # 6. Electrical
    "battery_voltage": {"min": 11.5, "max": 14.8, "spike_val": 0.0},
    "battery_temperature": {"min": 20.0, "max": 60.0, "spike_val": 999.0},
    "alternator_output": {"min": 0.0, "max": 150.0, "spike_val": -10.0},

    # 7. Chassis Dynamics (G-Forces & Position)
    "g_force_longitude": {"min": -5.0, "max": 2.0, "spike_val": 99.0},
    "g_force_latitude": {"min": -4.0, "max": 4.0, "spike_val": 99.0},
    "g_force_lateral": {"min": -4.0, "max": 4.0, "spike_val": 99.0},
    "latitude": {"min": -100, "max": 100, "spike_val": 999.0},
    "longitude": {"min": -100, "max": 100, "spike_val": 999.0},

    # 8. Corner Assemblies (Front Left, Front Right, Rear Left, Rear Right)
    "fl_wheel_speed": {"min": 0.0, "max": 370.0, "spike_val": -50.0},
    "fr_wheel_speed": {"min": 0.0, "max": 370.0, "spike_val": -50.0},
    "rl_wheel_speed": {"min": 0.0, "max": 370.0, "spike_val": -50.0},
    "rr_wheel_speed": {"min": 0.0, "max": 370.0, "spike_val": -50.0},

    "fl_wheel_load": {"min": 100.0, "max": 1500.0, "spike_val": -500.0},
    "fr_wheel_load": {"min": 100.0, "max": 1500.0, "spike_val": -500.0},
    "rl_wheel_load": {"min": 100.0, "max": 1500.0, "spike_val": -500.0},
    "rr_wheel_load": {"min": 100.0, "max": 1500.0, "spike_val": -500.0},

    "fl_shock_travel": {"min": 0.0, "max": 75.0, "spike_val": -100.0},
    "fr_shock_travel": {"min": 0.0, "max": 75.0, "spike_val": -100.0},
    "rl_shock_travel": {"min": 0.0, "max": 75.0, "spike_val": -100.0},
    "rr_shock_travel": {"min": 0.0, "max": 75.0, "spike_val": -100.0},

    "fl_ride_height": {"min": 15.0, "max": 80.0, "spike_val": -10.0},
    "fr_ride_height": {"min": 15.0, "max": 80.0, "spike_val": -10.0},
    "rl_ride_height": {"min": 15.0, "max": 80.0, "spike_val": -10.0},
    "rr_ride_height": {"min": 15.0, "max": 80.0, "spike_val": -10.0},

    "fl_tire_pressure": {"min": 1.2, "max": 2.5, "spike_val": -1.0},
    "fr_tire_pressure": {"min": 1.2, "max": 2.5, "spike_val": -1.0},
    "rl_tire_pressure": {"min": 1.2, "max": 2.5, "spike_val": -1.0},
    "rr_tire_pressure": {"min": 1.2, "max": 2.5, "spike_val": -1.0},

    "fl_tire_temperature": {"min": 60.0, "max": 120.0, "spike_val": 999.0},
    "fr_tire_temperature": {"min": 60.0, "max": 120.0, "spike_val": 999.0},
    "rl_tire_temperature": {"min": 60.0, "max": 120.0, "spike_val": 999.0},
    "rr_tire_temperature": {"min": 60.0, "max": 120.0, "spike_val": 999.0},

    "fl_brake_temperature": {"min": 200.0, "max": 1000.0, "spike_val": 2000.0},
    "fr_brake_temperature": {"min": 200.0, "max": 1000.0, "spike_val": 2000.0},
    "rl_brake_temperature": {"min": 200.0, "max": 1000.0, "spike_val": 2000.0},
    "rr_brake_temperature": {"min": 200.0, "max": 1000.0, "spike_val": 2000.0},

    # 9. Aerodynamics (Aero Taps & Probes)
    "pitot_tube": {"min": 0.0, "max": 150.0, "spike_val": -99.0},
    "pressure_tap_front_wing": {"min": -50.0, "max": 100.0, "spike_val": -999.0},
    "pressure_tap_rear_wing": {"min": -50.0, "max": 100.0, "spike_val": -999.0},
    "pressure_tap_diffuser": {"min": -50.0, "max": 100.0, "spike_val": -999.0},
    "pressure_tap_splitter": {"min": -50.0, "max": 100.0, "spike_val": -999.0},
    
    "kiel_probe_front_wing": {"min": -50.0, "max": 100.0, "spike_val": -999.0},
    "kiel_probe_rear_wing": {"min": -50.0, "max": 100.0, "spike_val": -999.0},
    "kiel_probe_diffuser": {"min": -50.0, "max": 100.0, "spike_val": -999.0},

    # 10. Structural Integrity (Strain Gauges)
    "strain_rollcage": {"min": -2000.0, "max": 2000.0, "spike_val": 99999.0},
    "strain_subframe": {"min": -2000.0, "max": 2000.0, "spike_val": 99999.0},
    "strain_fl_suspension": {"min": -2000.0, "max": 2000.0, "spike_val": 99999.0},
    "strain_fr_suspension": {"min": -2000.0, "max": 2000.0, "spike_val": 99999.0},
    "strain_rl_suspension": {"min": -2000.0, "max": 2000.0, "spike_val": 99999.0},
    "strain_rr_suspension": {"min": -2000.0, "max": 2000.0, "spike_val": 99999.0},

    # 11. Biometrics
    "driver_heart_rate": {"min": 80.0, "max": 190.0, "spike_val": 0.0},
    "driver_blood_oxygen": {"min": 90.0, "max": 100.0, "spike_val": 0.0},
    "driver_core_body_temperature": {"min": 36.5, "max": 39.5, "spike_val": 99.0},
    "driver_respiratory_rate": {"min": 15.0, "max": 50.0, "spike_val": -1.0},
}

TRACK_SUFFIXES = ["Speedway", "Raceway", "Circuit", "International Raceway", "Motorplex", "Grand Prix Course"]

ENGINE_LAYOUT = ["Inline","V","Boxer"]
FORCE_INDUCTION = ["Turbo","Supercharger","NA","Twin-Charged"]
GEARBOX_TYPE = ["Manual","Automatic","Sequential"]
DRIVETRAINS = ["FWD","RWD","AWD"]
TURN_TYPE = ["Hairpin","Carousel","Chicane","Corkscrew","Esses","Double Apex","Kink","Sweeper","90-Degree","Spoon","Snail"]