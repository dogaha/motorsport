import io
import pyarrow as pa
import pyarrow.parquet as pq
import boto3

# Config
WRITE_HZ = 20
LIVE_HZ = 5
N = WRITE_HZ / LIVE_HZ
SESSION_LENGTH_SEC = 60

# Pre-Generation: Session and Buffer
def generate_data():
    return

buffer = io.BytesIO()


# Generate Data