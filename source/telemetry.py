import io
import uuid
import time
import boto3
import numpy as np
import pyarrow as pa
import pyarrow.parquet as pq
from . import constants

# Generate Data Logged
def generate_session_data(session_id:str,n:int) -> dict:
    data = {}
    for field in constants.LOG_FIELDS:
        match field:
            case "session_id":
                data[field] = np.full(n,session_id)
            case "timestamp":
                data[field] = np.arange(0,n/constants.LOG_HZ,1/constants.LOG_HZ)
            case _:
                data[field] = np.random.uniform(0,100, size=n)
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
    return

# Stream Live data
def stream_data(data:dict,n:int,nth:int):
    for i in range(0,n,nth):
        record = {
            field : data[field][i] for field in constants.LIVE_FIELDS
        }

        # Push into kafka
        print(record)
        time.sleep(1/constants.LIVE_HZ)
        
if __name__ == "__main__":
    session_id = str(uuid.uuid4()) 
    session_length_sec = 60
    n = session_length_sec * constants.LOG_HZ 
    nth = constants.LOG_HZ // constants.LIVE_HZ

    data = generate_session_data(session_id,n)
    buffer = buffer_data(data)
    batch_data(buffer,session_id)
    stream_data(data,n,nth)
