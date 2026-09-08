import io
import json
import random
import constants
import psycopg2
from faker import Faker

# credentials
def get_db_credentials(secret_name: str, region: str = "us-east-2") -> dict:
    client = boto3.client("secretsmanager", region_name=region)
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response["SecretString"])

# random generated data:
def new_track(conn):
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
    track_id = cur.fetchone([0])

    for i in range(0,random.randint(25,75)):
        turn_number = i
        turn_type = random.choice(constants.TURN_TYPE)
        coordinate = f"{random.randint(-100,100)},{random.randint(-100,100)}"

        cur.execute(
            """
            INSERT INTO track_turns (turn_number,track_id,turn_type,coordinate)
            VALUES(%s,%s,%s,%s)
            """,
            (turn_number,track_id,turn_type,coordinate)
        )

    conn.commit()
    cur.close()
    return track_id

def new_driver(conn):
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
        RETURN driver_id
        """,
        (first_name,last_name,dob,weight)
    )
    driver_id = cur.fetchone()[0]

    conn.commit()
    cur.close()
    return driver_id

def new_vehicle(conn):
    fake = Faker()
    cur = conn.cursor()

    owner_id INT NOT NULL REFERENCES drivers(driver_id),
    make, model = fake.vehicle_make_model().split(" ", 1)

    horsepower = random.randint(150,900)
    torque = random.randint(100,700)
    redline = random.randrange(7000,11000,1000)
    engine_layout = random.choice(constants.ENGINE_LAYOUT)
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

def modify_vehicle():
    return


if __name__ == "__main__":
    print("hello world")
