from pyspark.sql import DataFrame

def to_bronze(df: DataFrame) -> DataFrame:
    """Shape raw Kafka rows into a bronze CDC table. No parsing: value stays raw JSON."""
    return df.selectExpr(
        "topic",
        "partition",
        "offset",
        "timestamp AS kafka_ts",
        "CAST(key AS STRING) AS key",
        "CAST(value AS STRING) AS value",
        "current_timestamp() AS _ingested_at",
    )