DROP TABLE IF EXISTS tracks CASCADE;
CREATE TABLE tracks (
    track_id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL,
    state VARCHAR(20) NOT NULL,
    city VARCHAR(20) NOT NULL,
    lap_length INT NOT NULL,
    start_coordinates POINT NOT NULL,
    end_coordinate POINT NOT NULL
);

DROP TABLE IF EXISTS track_turns CASCADE;
CREATE TABLE track_turns (
    turn_id SERIAL PRIMARY KEY,
    turn_number INT NOT NULL,
    track_id INT NOT NULL REFERENCES tracks(track_id),
    turn_type VARCHAR(20),
    coordinate POINT,

    UNIQUE (track_id, turn_number)
);

DROP TABLE IF EXISTS drivers CASCADE;
CREATE TABLE drivers (
    driver_id SERIAL PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    dob DATE,
    weight INT
);

DROP TABLE IF EXISTS vehicles CASCADE;
CREATE TABLE vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    owner_id INT NOT NULL REFERENCES drivers(driver_id),
    make VARCHAR(15),
    model VARCHAR(15),
    horsepower INT,
    torque INT,
    redline INT,
    engine_layout VARCHAR(20),
    engine_displacement INT,
    force_induction VARCHAR(15),
    boost_pressure INT,
    gear_count INT,
    gearbox_type VARCHAR(10),
    drivetrain VARCHAR(3),
    length INT,
    width INT,
    height INT,
    wheelbase INT,
    suspension VARCHAR(20),
    wheel_diameter INT,
    wheel_width INT,
    wheel_weight INT,
    tires VARCHAR(20)
);

DROP TABLE IF EXISTS sessions CASCADE;
CREATE TABLE sessions (
    session_id UUID PRIMARY KEY,
    track_id INT REFERENCES tracks(track_id),
    vehicle_id INT REFERENCES vehicles(vehicle_id),
    driver_id INT REFERENCES drivers(driver_id),
    start_time TIMESTAMP DEFAULT NOW(),
    end_time TIMESTAMP
);