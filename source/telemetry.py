import io
import uuid
import time
import json
import boto3
import random
import psycopg2
from collections import deque
from psycopg2 import sql
import numpy as np
import pyarrow as pa
import pyarrow.parquet as pq
from . import constants
from confluent_kafka import Producer


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

def create_session(conn):
    cur = conn.cursor()
    session_id = str(uuid.uuid4())
    cur.execute("SELECT vehicle_id FROM vehicles ORDER BY RANDOM() LIMIT 1")
    vehicle_id = cur.fetchone()[0]
    cur.execute("SELECT track_id FROM tracks ORDER BY RANDOM() LIMIT 1")
    track_id = cur.fetchone()[0]
    cur.execute("SELECT driver_id FROM drivers ORDER BY RANDOM() LIMIT 1")
    driver_id = cur.fetchone()[0]

    cur.execute(
        """
        INSERT INTO sessions (session_id,track_id,vehicle_id,driver_id)
        VALUES (%s,%s,%s,%s)
        """, (session_id,track_id,vehicle_id,driver_id)

    )
    conn.commit()
    cur.close()
    return session_id

def end_session(conn,session_id):
    cur = conn.cursor()
    cur.execute(
        """
        UPDATE sessions SET end_time = NOW()
        WHERE session_id = %s
        """, (session_id,)
    )
    conn.commit()
    cur.close()
    return

# Generate Data Logged
def generate_session_data(session_id:str,n:int) -> dict:
    data = {}
    log_dict = constants.LOG_FIELDS
    data["session_id"] = np.full(n,session_id)
    data["timestamp"] = np.arange(n) / constants.LOG_HZ
    for field in log_dict.keys():
        mask_null = np.random.random(size=n) < 0.05
        mask_range = np.random.random(size=n) < 0.02
        data[field] = np.random.uniform(log_dict[field]['min'],log_dict[field]['max'], size=n)
        data[field][mask_null] = np.nan
        data[field][mask_range] = log_dict[field]['spike_val']
    print("Finish Data Generation")
    return data

# save data to memeory
def buffer_data(data: dict) -> io.BytesIO:
    table = pa.table(data)
    buffer = io.BytesIO()
    pq.write_table(table, buffer)
    buffer.seek(0)
    return buffer

def batch_data(buffer: io.BytesIO,session_id:str):
    # send to S3
    s3 = boto3.client("s3")
    s3.upload_fileobj(buffer,"motorsport-data-lake",f"landing/{session_id}.parquet")

    # reclaim memory
    buffer.close()
    print("Finished Loading Into S3")
    return

# Stream Live data
def stream_data(data:dict,n:int,nth:int):
    # producer
    producer = Producer({ "bootstrap.servers":"kafka:9092" })
    bs_records = []
    retry_records = deque()
    in_blind_spot = False
    blind_spot_ticks = 0

    for i in range(0,n,nth):
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
            blind_spot_ticks = random.randint(5,15)

        # retry error
        if random.random() < 0.03:
            retry_records.append(payload)
            time.sleep(1/constants.LIVE_HZ)
            continue

        # Blind spot condition
        if in_blind_spot:
            # fill blind spot
            bs_records.append(payload)
            blind_spot_ticks -= 1
            if blind_spot_ticks <= 0:
                in_blind_spot = False
        else:
            # Push current payload
            producer.produce(
                "telemetry",
                value=payload
            )

            # duplicate
            if random.random() < 0.02:
                producer.produce(
                    "telemetry",
                    value=payload
                )

            # burst refill
            if bs_records:
                random.shuffle(bs_records)
                for p in bs_records:
                    producer.produce(
                        "telemetry",
                        value=p
                    )
                bs_records.clear()

            # retry past records
            if retry_records and random.random() < 0.2:
                producer.produce(
                    "telemetry",
                    value=retry_records.popleft()
                )
        producer.poll(0)
        time.sleep(1/constants.LIVE_HZ)
    # burst refill
    if bs_records:
        random.shuffle(bs_records)
        for p in bs_records:
            producer.produce(
                "telemetry",
                value=p
            )
        bs_records.clear()
    while retry_records:
        producer.produce(
            "telemetry",
            value=retry_records.popleft()
        )
        producer.poll(0)

    producer.flush()
    print("Finish Streaming Data")
    
if __name__ == "__main__":
    SECRET_NAME = "motorsport-rds-credentials"
    AWS_REGION = "us-east-2"
    session_length_sec = 60
    n = session_length_sec * constants.LOG_HZ 
    nth = constants.LOG_HZ // constants.LIVE_HZ
    conn = get_db_credentials(SECRET_NAME, AWS_REGION)
    try:
        session_id = create_session(conn)
        data = generate_session_data(session_id,n)
        buffer = buffer_data(data)
        batch_data(buffer,session_id)
        stream_data(data,n,nth)
        end_session(conn,session_id)
    finally:
        conn.close()
