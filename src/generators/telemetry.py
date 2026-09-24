import io
import uuid
import time
import json
import signal
import boto3
import random
import psycopg2
from collections import deque
import numpy as np
import pyarrow as pa
import pyarrow.parquet as pq
from . import constants
from confluent_kafka import Producer

# graceful stop: finish the current session, then exit the loop
stop = False

def _handle_stop(signum, frame):
    global stop
    stop = True
    print("Stop requested, finishing current session")

signal.signal(signal.SIGTERM, _handle_stop)
signal.signal(signal.SIGINT, _handle_stop)

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

def get_producer() -> Producer:
    client = boto3.client("secretsmanager", region_name="us-east-2")
    response = client.get_secret_value(SecretId="motorsport-confluent-producer")
    creds = json.loads(response["SecretString"])
    return Producer({
        "bootstrap.servers": creds["bootstrap"],
        "security.protocol": "SASL_SSL",
        "sasl.mechanism": "PLAIN",
        "sasl.username": creds["api_key"],
        "sasl.password": creds["api_secret"],
    })

class DeliveryStats:
    def __init__(self):
        self.ok = 0
        self.failed = 0
        self.first_error = None

    def callback(self, err, msg):
        if err is not None:
            self.failed += 1
            if self.first_error is None:
                self.first_error = str(err)
        else:
            self.ok += 1

def create_session(conn):
    cur = conn.cursor()
    session_id = str(uuid.uuid4())

    cur.execute("""
        SELECT v.vehicle_id
        FROM vehicles v
        WHERE NOT EXISTS (
            SELECT 1 FROM sessions s
            WHERE s.vehicle_id = v.vehicle_id AND s.end_time IS NULL
        )
        ORDER BY RANDOM() LIMIT 1
    """)
    row = cur.fetchone()
    if row is None:
        cur.close()
        return None, None
    vehicle_id = row[0]

    cur.execute("""
        SELECT d.driver_id
        FROM drivers d
        WHERE NOT EXISTS (
            SELECT 1 FROM sessions s
            WHERE s.driver_id = d.driver_id AND s.end_time IS NULL
        )
        ORDER BY RANDOM() LIMIT 1
    """)
    row = cur.fetchone()
    if row is None:
        cur.close()
        return None, None
    driver_id = row[0]

    cur.execute("SELECT track_id FROM tracks ORDER BY RANDOM() LIMIT 1")
    track_id = cur.fetchone()[0]

    cur.execute(
        """
        INSERT INTO sessions (session_id,track_id,vehicle_id,driver_id)
        VALUES (%s,%s,%s,%s)
        """, (session_id, track_id, vehicle_id, driver_id)
    )

    cur.execute("SELECT start_coordinate[0], start_coordinate[1] FROM track_sections WHERE track_id = %s ORDER BY section_number ASC;", (track_id,))
    section_starts = cur.fetchall()   # list of (x, y) tuples

    conn.commit()
    cur.close()
    print("Session Created")
    return session_id, section_starts

def end_session(conn, session_id):
    cur = conn.cursor()
    cur.execute(
        """
        UPDATE sessions SET end_time = NOW()
        WHERE session_id = %s
        """, (session_id,)
    )
    conn.commit()
    cur.close()
    print("Ended Session")
    return

def positional_data_generation(section_starts, laps, n):
    section_starts = np.array(section_starts, dtype=float)
    num_sections = len(section_starts)

    mandatory_points = num_sections * laps

    random_points_needed = n - mandatory_points

    points_per_segment = np.random.multinomial(
        random_points_needed,
        [1.0 / mandatory_points] * mandatory_points
    )

    # 1. PRE-ALLOCATE the final NumPy array. Shape is (n, 2) for X, Y coordinates
    track_data = np.empty((n, 2), dtype=float)

    segment_index = 0
    current_row = 0  # We will use this to track where to insert the next batch of data

    for lap in range(laps):
        for i in range(num_sections):
            start_coord = section_starts[i]

            # 2. Insert the single start coordinate directly into the array
            track_data[current_row] = start_coord
            current_row += 1

            end_coord = section_starts[(i + 1) % num_sections]
            num_random_pts = points_per_segment[segment_index]
            segment_index += 1

            if num_random_pts > 0:
                t_values = np.random.uniform(0.001, 0.999, size=num_random_pts)
                t_values.sort()
                t_values = t_values[:, np.newaxis]

                intermediate_coords = start_coord + t_values * (end_coord - start_coord)

                # 3. Drop the entire chunk of intermediate coordinates directly into the array
                track_data[current_row : current_row + num_random_pts] = intermediate_coords

                # Move the tracker forward
                current_row += num_random_pts

    return track_data

# Generate Data Logged
def generate_session_data(session_id: str, track_turns: list, laps: int, n: int) -> dict:
    data = {}
    log_dict = constants.LOG_FIELDS

    data["session_id"] = np.full(n, session_id)
    data["timestamp"] = np.arange(n) / constants.LOG_HZ

    coords = positional_data_generation(track_turns, laps, n)

    # 2. Slice the 2D array into our 1D latitude and longitude arrays
    data["latitude"] = coords[:, 0]
    data["longitude"] = coords[:, 1]

    # 3. Generate uniform data and apply noise/spikes
    for field in log_dict.keys():
        mask_null = np.random.random(size=n) < 0.05
        mask_range = np.random.random(size=n) < 0.02

        # Only generate uniform randoms if the field isn't our pre-calculated lat/lon
        if field not in ["latitude", "longitude"]:
            data[field] = np.random.uniform(log_dict[field]['min'], log_dict[field]['max'], size=n)
            data[field][mask_null] = np.nan
            data[field][mask_range] = log_dict[field]['spike_val']

        # Apply the missing data (np.nan) and spikes to the fields
        # Note: ensuring the array is float handles potential issues where np.nan fails on int arrays
        data[field] = data[field].astype(float)

    print("Finish Data Generation")
    return data

# save data to memeory
def buffer_data(data: dict) -> io.BytesIO:
    table = pa.table(data)
    buffer = io.BytesIO()
    pq.write_table(table, buffer)
    buffer.seek(0)
    return buffer

def batch_data(buffer: io.BytesIO, session_id: str):
    # send to S3
    s3 = boto3.client("s3", region_name="us-east-2")
    s3.upload_fileobj(buffer, "motorsport-data-lake", f"landing/{session_id}.parquet")

    # reclaim memory
    buffer.close()
    print("Finished Loading Into S3")
    return

# Stream Live data
def stream_data(producer: Producer, data: dict, n: int, nth: int):
    stats = DeliveryStats()

    def send(payload: bytes):
        producer.produce("telemetry", value=payload, callback=stats.callback)

    bs_records = []
    retry_records = deque()
    in_blind_spot = False
    blind_spot_ticks = 0

    for i in range(0, n, nth):
        record = {
            field: (
                data[field][i].item()
                if isinstance(data[field][i], np.generic)
                else data[field][i]
            )
            for field in constants.LIVE_FIELDS
        }
        payload = json.dumps(record).encode("utf-8")

        # Skip Row
        if random.random() < 0.02:
            time.sleep(1/constants.LIVE_HZ)
            continue

        # blind spot
        if random.random() < 0.03 and not in_blind_spot:
            in_blind_spot = True
            blind_spot_ticks = random.randint(5, 15)

        # retry error
        if random.random() < 0.03:
            retry_records.append(payload)
            time.sleep(1/constants.LIVE_HZ)
            continue

        # Blind spot condition
        if in_blind_spot:
            bs_records.append(payload)
            blind_spot_ticks -= 1
            if blind_spot_ticks <= 0:
                in_blind_spot = False
        else:
            send(payload)

            # duplicate
            if random.random() < 0.02:
                send(payload)

            # burst refill
            if bs_records:
                random.shuffle(bs_records)
                for p in bs_records:
                    send(p)
                bs_records.clear()

            # retry past records
            if retry_records and random.random() < 0.2:
                send(retry_records.popleft())

        producer.poll(0)
        time.sleep(1/constants.LIVE_HZ)

    # burst refill
    if bs_records:
        random.shuffle(bs_records)
        for p in bs_records:
            send(p)
        bs_records.clear()
    while retry_records:
        send(retry_records.popleft())
        producer.poll(0)

    remaining = producer.flush(30)
    print(f"delivered={stats.ok} failed={stats.failed} undelivered_at_timeout={remaining}")
    if stats.failed or remaining:
        raise RuntimeError(f"streaming problems, first error: {stats.first_error}")
    print("Finish Streaming Data")

if __name__ == "__main__":
    print("--telemetry.py--")
    SECRET_NAME = "motorsport-rds-credentials"
    AWS_REGION = "us-east-2"
    laps = 6
    conn = get_db_credentials(SECRET_NAME, AWS_REGION)

    try:
        while not stop:
            session_length_sec = laps * random.randint(600, 900)
            n = session_length_sec * constants.LOG_HZ

            # Start Session
            session_id, track_turns = create_session(conn)
            if session_id is None:
                time.sleep(15)
                continue

            try:
                # Create Data
                data = generate_session_data(session_id, track_turns, laps, n)
                buffer = buffer_data(data)

                # Send Data Over
                time.sleep(session_length_sec / 60)
                batch_data(buffer, session_id)
            finally:
                # Always close the session, even if generation or upload failed,
                # so a failed session never pins its vehicle and driver
                end_session(conn, session_id)
    finally:
        conn.close()