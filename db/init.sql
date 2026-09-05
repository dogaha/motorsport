CREATE TABLE tracks (
    track_id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL,
    state VARCHAR(20) NOT NULL,
    city VARCHAR(20) NOT NULL,
    lap_length INT NOT NULL,
    start_coordinates POINT NOT NULL,
    end_coordinate POINT NOT NULL
);

CREATE TABLE track_turns (
    turn_id SERIAL  PRIMARY KEY,
    turn_number INT NOT NULL,
    track_id INT NOT NULL REFERENCES tracks(track_id),
    turn_type VARCHAR(20),
    coordinate POINT,

    UNIQUE (track_id, turn_number)
);

CREATE TABLE drivers (
    driver_id SERIAL PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    dob DATE,
    weight INT
);

CREATE TABLE vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    owner_id INT NOT NULL REFERENCES drivers(driver_id),
    make VARCHAR(15),
    model VARCHAR(15),
    horsepower INT,
    torque INT,
    readline INT,
    engine_name VARCHAR(20),
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
    tires VARCHAR(20)
);