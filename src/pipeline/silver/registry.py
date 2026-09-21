TABLES = {
    "sensors": {
        "key": "sensor_id",
        "schema": "sensor_id INT, sensor_name STRING, min_valid DOUBLE, max_valid DOUBLE",
        "scd": 1
    },
    "vehicles": {
        "key": "vehicle_id",
        "schema": (
            "vehicle_id INT, owner_id INT, make STRING, model STRING, "
            "horsepower INT, torque INT, redline INT, engine_layout STRING, "
            "engine_cylinders INT, engine_displacement INT, force_induction STRING, "
            "boost_pressure INT, gearbox_type STRING, gear_count INT, drivetrain STRING, "
            "length INT, width INT, height INT, wheelbase INT, wheel_diameter INT, "
            "wheel_width INT, wheel_weight INT, curb_weight INT, tires STRING"
        ),
        "scd": 2
    },
    "tracks": {
        "key": "track_id",
        "schema": "track_id INT, name STRING, state STRING, city STRING, lap_length INT",
        "scd": 1
    },
    "track_sections": {
        "key": "section_id",
        "schema": (
            "section_id INT, section_number INT, track_id INT, section_type STRING, "
            "start_coordinate STRUCT<x: DOUBLE, y: DOUBLE, srid: INT>"
        ),
        "scd": 1
    },
    "drivers": {
        "key": "driver_id",
        "schema": "driver_id INT, first_name STRING, last_name STRING, dob INT, weight INT",
        "scd": 1,
        "dates": ["dob"],
    },
    "sessions": {
        "key": "session_id",
        "schema": "session_id STRING, track_id INT, vehicle_id INT, driver_id INT, start_time STRING, end_time STRING",
        "scd": 1,
        "timestamps": ["start_time", "end_time"],
    },
    
}