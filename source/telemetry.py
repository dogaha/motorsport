import io
import np
import pyarrow as pa
import pyarrow.parquet as pq
import boto3
import motorsport.source.constants as constants


# Session INIT
buffer = io.BytesIO

# Generate Data Logged
data = {}
for field in constants.LOG_FIELDS:
    match field:
        case "timestamp":
            data[field] = np.arrange(0,constants.SESSION_LENGTH_SEC,1/constants.LOG_HZ)
            break
        case _:
            data[field] = np.random.uniform(0,100, size=constants.N)
            break

table = pa.table(data)
buffer = io.ByteIO()
pq.write_table(table, buffer)
buffer.seek(0)

# get live data
for i in range()
    

# Send batch data
