-- Seed data: 3 tracks + track_turns, 3 drivers, 3 vehicles

-- ---- Tracks ----
INSERT INTO tracks (name, state, city, lap_length, start_coordinates, end_coordinates) VALUES
('Harris County Motorsports Park', 'Texas', 'Houston', 2, '(29,-95)', '(29,-95)'),
('Eagles Canyon Raceway', 'Texas', 'Decatur', 3, '(33,-97)', '(33,-97)'),
('Circuit of the Americas', 'Texas', 'Austin', 5, '(30,-97)', '(30,-97)');

-- ---- Drivers ----
INSERT INTO drivers (first_name, last_name, dob, weight) VALUES
('Ethan', 'Rivera', '1998-04-12', 165),
('Maya', 'Chen', '1996-09-03', 140),
('Jordan', 'Alvarez', '2000-01-27', 180);

-- ---- Vehicles ----
-- owner_id 1 -> Ethan
INSERT INTO vehicles (
    owner_id, make, model, horsepower, torque, redline, engine_layout,
    engine_cylinders, engine_displacement, force_induction, boost_pressure,
    gearbox_type, gear_count, drivetrain, length, width, height, wheelbase,
    wheel_diameter, wheel_width, wheel_weight, curb_weight, tires
) VALUES
(1, 'Subaru', 'WRX STI', 310, 290, 6700, 'Flat-4', 4, 2500, 'Turbo', 14,
 'Manual', 6, 'AWD', 4415, 1795, 1475, 2650, 18, 9, 25, 3400, '245/40R18'),

-- owner_id 2 -> Maya
(2, 'BMW', 'M240i', 335, 369, 6500, 'Inline-6', 6, 3000, 'Turbo', 16,
 'Automatic', 8, 'RWD', 4465, 1800, 1400, 2705, 18, 8, 28, 3650, '225/40R18'),

-- owner_id 3 -> Jordan
(3, 'Ford', 'Mustang GT', 460, 420, 7500, 'V8', 8, 5000, 'NA', 0,
 'Manual', 6, 'RWD', 4784, 1916, 1381, 2720, 19, 9, 32, 3700, '255/40R19');

 -- Seed data: track_turns for tracks 1, 2, 3

INSERT INTO track_turns (turn_number, track_id, turn_type, coordinate) VALUES
(1, 1, 'sweeper', '(-16,-93)'),
(2, 1, 'sweeper', '(86,-45)'),
(3, 1, 'esses', '(-77,67)'),
(4, 1, 'hairpin', '(63,62)'),
(5, 1, 'esses', '(43,89)'),
(6, 1, 'esses', '(-94,-91)'),
(7, 1, 'esses', '(-51,18)'),
(8, 1, 'sweeper', '(26,-56)'),
(9, 1, 'esses', '(-57,-46)'),
(10, 1, 'sweeper', '(-98,-53)'),
(11, 1, 'esses', '(-84,-69)'),
(12, 1, 'hairpin', '(31,-29)'),
(1, 2, 'kink', '(-51,57)'),
(2, 2, 'hairpin', '(26,83)'),
(3, 2, 'esses', '(-15,-80)'),
(4, 2, 'sweeper', '(-11,91)'),
(5, 2, 'chicane', '(-51,62)'),
(6, 2, 'sweeper', '(10,53)'),
(7, 2, 'hairpin', '(-83,-17)'),
(8, 2, 'kink', '(83,40)'),
(9, 2, 'chicane', '(-75,77)'),
(10, 2, 'chicane', '(-26,38)'),
(11, 2, 'sweeper', '(65,15)'),
(12, 2, 'chicane', '(93,42)'),
(13, 2, 'sweeper', '(15,-56)'),
(1, 3, 'sweeper', '(-52,-3)'),
(2, 3, 'kink', '(87,-62)'),
(3, 3, 'hairpin', '(-43,2)'),
(4, 3, 'kink', '(-13,68)'),
(5, 3, 'hairpin', '(-2,79)'),
(6, 3, 'esses', '(-26,79)'),
(7, 3, 'sweeper', '(44,16)'),
(8, 3, 'hairpin', '(6,-68)'),
(9, 3, 'kink', '(-65,-52)'),
(10, 3, 'hairpin', '(2,81)'),
(11, 3, 'sweeper', '(49,61)'),
(12, 3, 'kink', '(26,61)');