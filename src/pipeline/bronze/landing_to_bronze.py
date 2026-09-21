from pyspark.sql import DataFrame
from pyspark.sql import functions as F


def add_metadata(df: DataFrame) -> DataFrame:
    """Add ingestion metadata columns. No other transformation: bronze stays raw."""
    return (
        df.withColumn("_source_file",F.col("_metadata.file_path"))
        .withColumn("_ingested_at",F.current_timestamp())
    )