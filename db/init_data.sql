-- Seed data: 4 drivers, 2 vehicles each (8 total)
-- One-time insert, run via psql after schema is applied.
-- Values are placeholder-realistic; adjust as you see fit (schema/data modeling is your call).

-- ---- Drivers ----
INSERT INTO drivers (first_name, last_name, dob, weight) VALUES
('Ethan',  'Rivera',   '1998-04-12', 165),
('Maya',   'Chen',     '1996-09-03', 140),
('Jordan', 'Alvarez',  '2000-01-27', 180),
('Sam',    'Okafor',   '1994-11-15', 155);

-- ---- Vehicles ----
INSERT INTO vehicles (
    owner_id, make, model, horsepower, torque, readline, engine_name,
    engine_displacement, force_induction, boost_pressure, gear_count,
    gearbox_type, drivetrain, length, width, height, wheelbase,
    suspension, wheel_diameter, wheel_width, tires
) VALUES
(1, 'Subaru', 'WRX STI', 310, 290, 6700, 'EJ257', 2500, 'Turbo', 14, 6,
 'Manual', 'AWD', 4415, 1795, 1475, 2650, 'Coilover', 18, 9, '245/40R18'),

(2, 'BMW', 'M240i', 335, 369, 6500, 'B58', 3000, 'Turbo', 16, 8,
 'Automatic', 'RWD', 4465, 1800, 1400, 2705, 'Adaptive M Sport', 18, 8, '225/40R18'),

(3, 'Honda', 'Civic Type R', 315, 310, 7000, 'K20C1', 2000, 'Turbo', 20, 6,
 'Manual', 'FWD', 4595, 1890, 1410, 2735, 'Adaptive', 19, 9, '265/30R19'),

(4, 'Ford', 'Mustang GT', 460, 420, 7500, 'Coyote', 5000, 'NA', 0, 6,
 'Manual', 'RWD', 4784, 1916, 1381, 2720, 'MagneRide', 19, 9, '255/40R19'),