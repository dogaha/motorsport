CREATE TABLE IF NOT EXISTS drivers (
    driver_id SERIAL PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    dob DATE,
    weight INT
);

CREATE TABLE IF NOT EXISTS vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    owner_id INT NOT NULL REFERENCES drivers(driver_id),
    make VARCHAR(15),
    model VARCHAR(15),
    horsepower INT,
    torque INT,
    redline INT,
    engine_layout VARCHAR(20),
    engine_cylinders INT,
    engine_displacement INT,
    force_induction VARCHAR(15),
    boost_pressure INT,
    gearbox_type VARCHAR(10),
    gear_count INT,
    drivetrain VARCHAR(3),
    length INT,
    width INT,
    height INT,
    wheelbase INT,
    wheel_diameter INT,
    wheel_width INT,
    wheel_weight INT,
    curb_weight INT,
    tires VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS tracks (
    track_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    state VARCHAR(20) NOT NULL,
    city VARCHAR(20) NOT NULL,
    lap_length INT NOT NULL
);

CREATE TABLE IF NOT EXISTS track_sections (
    section_id SERIAL PRIMARY KEY,
    section_number INT NOT NULL,
    track_id INT NOT NULL REFERENCES tracks(track_id),
    section_type VARCHAR(20),
    start_coordinate POINT,

    UNIQUE (track_id, section_number)
);

CREATE TABLE IF NOT EXISTS  sessions (
    session_id UUID PRIMARY KEY,
    track_id INT REFERENCES tracks(track_id),
    vehicle_id INT REFERENCES vehicles(vehicle_id),
    driver_id INT REFERENCES drivers(driver_id),
    start_time TIMESTAMPTZ DEFAULT NOW(),
    end_time TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS sensors (
    sensor_id SERIAL PRIMARY KEY,
    sensor_name VARCHAR(40) NOT NULL UNIQUE,
    min_valid DOUBLE PRECISION NOT NULL,
    max_valid DOUBLE PRECISION NOT NULL,

    CHECK (min_valid < max_valid)
);
