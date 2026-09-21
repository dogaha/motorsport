import io
import time
import json
import boto3
import random
from . import constants
import psycopg2
from psycopg2 import sql
from faker import Faker
from faker_vehicle import VehicleProvider

# credentials
def get_db_credentials(secret_name: str, region: str = "us-east-2"):
    client = boto3.client("secretsmanager", region_name=region)
    response = client.get_secret_value(SecretId=secret_name)
    creds = json.loads(response["SecretString"])
    conn = psycopg2.connect(
        host=creds["host"],
        port=creds.get("port", "5432"),
        dbname=creds["dbname"],
        user=creds["username"],
        password=creds["password"]
    )
    return conn

# random generated data:
def random_new_track(conn):
    fake = Faker()
    cur = conn.cursor()

    state = fake.state()
    city = fake.city()
    lap_length = random.randint(2,15)
    start_coordinates = f"{random.randint(-100,100)},{random.randint(-100,100)}"
    end_coordinate = f"{random.randint(-100,100)},{random.randint(-100,100)}"
    name = f"{city} {random.choice(constants.TRACK_SUFFIXES)}"

    cur.execute(
        """
        INSERT INTO tracks (name,state,city,lap_length,start_coordinates,end_coordinates)
        VALUES (%s,%s,%s,%s,%s,%s)
        RETURNING track_id
        """,
        (name,state,city,lap_length,start_coordinates,end_coordinate)
    )
    track_id = cur.fetchone()[0]

    for i in range(0,random.randint(10,30)):
        section_number = i
        section_type = random.choice(constants.section_TYPE) if random.random() < 0.5 else "straight"
        coordinate = f"{random.randint(-100,100)},{random.randint(-100,100)}"

        cur.execute(
            """
            INSERT INTO track_sections (section_number,track_id,section_type,coordinates)
            VALUES(%s,%s,%s,%s)
            """,
            (section_number,track_id,section_type,coordinate)
        )

    conn.commit()
    cur.close()
    print("Inserted Random Track Record and Track sections Records")
    return track_id

def random_new_driver(conn):
    fake = Faker()
    cur = conn.cursor()

    first_name = fake.first_name()
    last_name = fake.last_name()
    dob = fake.date_of_birth(minimum_age=18, maximum_age=80)
    weight = random.randint(100,300)

    cur.execute(
        """
        INSERT INTO drivers(first_name,last_name,dob,weight)
        VALUES (%s,%s,%s,%s)
        RETURNING driver_id
        """,
        (first_name,last_name,dob,weight)
    )
    driver_id = cur.fetchone()[0]

    conn.commit()
    cur.close()
    print("Inserted Random Driver Record")
    return driver_id

def random_new_vehicle(conn):
    fake = Faker()
    fake.add_provider(VehicleProvider)
    cur = conn.cursor()

    make, model = fake.vehicle_make_model().split(" ", 1)
    horsepower = random.randint(150, 900)
    torque = random.randint(100, 700)
    redline = random.randrange(7000, 11001, 1000)
    engine_layout = random.choice(constants.ENGINE_LAYOUT)
    engine_cylinders = random.randint(3, 8)
    engine_displacement = random.randrange(1500, 5001, 1000)
    force_induction = random.choice(constants.FORCE_INDUCTION)
    boost_pressure = 0 if force_induction == "NA" else random.randint(5, 30)
    gearbox_type = random.choice(constants.GEARBOX_TYPE)
    gear_count = random.randint(5, 6) if gearbox_type == "Manual" else random.randint(7, 10)
    drivetrain = random.choice(constants.DRIVETRAINS)
    length = random.randint(310, 550)
    width = random.randint(160, 200)
    height = random.randint(140, 150)
    wheelbase = random.randint(240, 280)
    wheel_diameter = random.randint(15, 22)  # in
    wheel_width = random.randint(7, 13)      # in
    wheel_weight = random.randint(12, 40)    # lbs
    curb_weight = random.randint(2200, 4500) # lbs -- placeholder range, your call
    tires = f"{random.randint(160,260)}/{random.randrange(40,71,5)}R{wheel_diameter}"

    cur.execute("SELECT driver_id FROM drivers ORDER BY RANDOM() LIMIT 1")
    owner_id = cur.fetchone()[0]

    cur.execute(
        """
        INSERT INTO vehicles (
            owner_id, make, model, horsepower, torque, redline,
            engine_layout, engine_cylinders, engine_displacement,
            force_induction, boost_pressure, gearbox_type, gear_count,
            drivetrain, length, width, height, wheelbase,
            wheel_diameter, wheel_width, wheel_weight, curb_weight, tires
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING vehicle_id
        """,
        (owner_id, make, model, horsepower, torque, redline,
         engine_layout, engine_cylinders, engine_displacement,
         force_induction, boost_pressure, gearbox_type, gear_count,
         drivetrain, length, width, height, wheelbase,
         wheel_diameter, wheel_width, wheel_weight, curb_weight, tires)
    )
    vehicle_id = cur.fetchone()[0]

    conn.commit()
    cur.close()
    print("Inserted Random Vehicle")
    return vehicle_id

def random_modify_vehicle(conn):
    fake = Faker()
    cur = conn.cursor()
    
    force_induction = random.choice(constants.FORCE_INDUCTION)
    gearbox_type = random.choice(constants.GEARBOX_TYPE)
    wheel_diameter = random.randint(15, 22)

    cur.execute("SELECT vehicle_id FROM vehicles ORDER BY RANDOM() LIMIT 1")
    vehicle_id = cur.fetchone()[0]

    if not vehicle_id:
        return None

    car = {
        "horsepower": random.randint(150, 900),
        "torque": random.randint(100, 700),
        "redline": random.randrange(7000, 11001, 1000),
        "engine_layout": random.choice(constants.ENGINE_LAYOUT),
        "engine_cylinders": random.randint(3, 8),
        "engine_displacement": random.randrange(1500, 5001, 1000),
        "force_induction": force_induction,
        "boost_pressure": 0 if force_induction == "NA" else random.randint(5, 30),
        "gearbox_type": gearbox_type,
        "gear_count": random.randint(5, 6) if gearbox_type == "Manual" else random.randint(7, 10),
        "drivetrain": random.choice(constants.DRIVETRAINS),
        "wheel_diameter": wheel_diameter,
        "wheel_width": random.randint(7, 13),
        "wheel_weight": random.randint(12, 40),
        "curb_weight": random.randint(2200, 4500),
        "tires": f"{random.randint(160, 260)}/{random.randrange(40, 71, 5)}R{wheel_diameter}",
    }

    key = random.choice(list(car))
    value = car[key]

    cur.execute(
        sql.SQL("UPDATE vehicles SET {} = %s WHERE vehicle_id = %s").format(sql.Identifier(key)),
        (value, vehicle_id)
    )

    print("Modfied Random Vehicle")
    return vehicle_id


if __name__ == "__main__":
    SECRET_NAME = "motorsport-rds-credentials"
    AWS_REGION = "us-east-2"
    conn = get_db_credentials(SECRET_NAME, AWS_REGION)

    try:
        functions = [random_new_track,random_new_driver,random_new_vehicle,random_modify_vehicle]
        weights = [10, 25, 25, 40]
        while True:
            function = random.choices(functions, weights=weights, k=1)[0]
            function(conn)
            time.sleep(random.randint(15,30))
    finally:
        conn.close()
