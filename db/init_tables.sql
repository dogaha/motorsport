CREATE TABLE IF NOT EXISTS tracks (
    track_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    state VARCHAR(20) NOT NULL,
    city VARCHAR(20) NOT NULL,
    lap_length INT NOT NULL,
    start_coordinates POINT NOT NULL,
    end_coordinates POINT NOT NULL
);

CREATE TABLE IF NOT EXISTS track_turns (
    turn_id SERIAL PRIMARY KEY,
    turn_number INT NOT NULL,
    track_id INT NOT NULL REFERENCES tracks(track_id),
    turn_type VARCHAR(20),
    coordinate POINT,

    UNIQUE (track_id, turn_number)
);
