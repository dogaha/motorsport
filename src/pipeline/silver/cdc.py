from pyspark.sql import DataFrame, Window
from pyspark.sql import functions as F
from pyspark.sql.types import (
    LongType,
    StringType,
    StructField,
    StructType,
)


def _envelope_schema(row_ddl: str) -> StructType:
    """Build the Spark schema for a Debezium message.

    Only the parts we use are described: payload.before, payload.after,
    payload.op and payload.source (ts_ms and lsn). The repeated `schema`
    block in each message is ignored. `row_ddl` is the table's own columns,
    taken from the registry.
    """
    row = StructType.fromDDL(row_ddl)
    return StructType(
        [
            StructField(
                "payload",
                StructType(
                    [
                        StructField("before", row),
                        StructField("after", row),
                        StructField("op", StringType()),
                        StructField(
                            "source",
                            StructType(
                                [
                                    StructField("ts_ms", LongType()),
                                    StructField("lsn", LongType()),
                                ]
                            ),
                        ),
                    ]
                ),
            )
        ]
    )


def parse_envelope(df: DataFrame, config: dict) -> DataFrame:
    """Turn bronze rows (JSON text in `value`) into typed columns.

    Output has one row per change message: the table's columns, plus
    `op` (r/c/u/d), `_lsn` (Postgres log position), `_changed_at` (when the
    change happened in the database) and `_offset` (Kafka offset).
    """
    parsed = df.select(
        F.from_json("value", _envelope_schema(config["schema"])).alias("m"),
        F.col("offset").alias("_offset"),
    )

    # Deletes carry the row in `before` (`after` is null); all other
    # operations carry it in `after`.
    row = F.when(F.col("m.payload.op") == "d", F.col("m.payload.before")).otherwise(
        F.col("m.payload.after")
    )

    return parsed.select(
        row.alias("row"),
        F.col("m.payload.op").alias("op"),
        F.col("m.payload.source.lsn").alias("_lsn"),
        (F.col("m.payload.source.ts_ms") / 1000).cast("timestamp").alias("_changed_at"),
        "_offset",
    ).select("row.*", "op", "_lsn", "_changed_at", "_offset")


def convert_types(df: DataFrame, config: dict) -> DataFrame:
    """Convert Debezium's encodings into real Spark types.

    Debezium sends DATE as days since 1970-01-01 and TIMESTAMPTZ as ISO
    strings. The registry lists which columns need which conversion, under
    `dates` and `timestamps`. Tables with neither are returned unchanged.
    """
    for col in config.get("dates", []):
        df = df.withColumn(col, F.expr(f"date_add('1970-01-01', {col})"))
    for col in config.get("timestamps", []):
        df = df.withColumn(col, F.to_timestamp(col))
    return df


def add_versions(df: DataFrame, key: str) -> DataFrame:
    """Build SCD2 history from the change log.

    Adds `version_id` (1, 2, 3... per key), `valid_from` (when the version
    began) and `valid_to` (when the next change happened; null means
    current). Changes are ordered by Postgres log position, with the Kafka
    offset as a tiebreak. A delete closes the previous version and does not
    create a row of its own.
    """
    order = Window.partitionBy(key).orderBy("_lsn", "_offset")

    # `valid_to` is taken from the next change, delete or not, so a delete
    # correctly closes the row before it.
    with_close = df.withColumn("valid_to", F.lead("_changed_at").over(order))

    # Drop deletes now so they don't consume a version number, then number
    # the surviving versions in the same order.
    kept = with_close.filter(F.col("op") != "d")
    order_kept = Window.partitionBy(key).orderBy("_lsn", "_offset")

    return (
        kept.withColumn("version_id", F.row_number().over(order_kept))
        .withColumn("valid_from", F.col("_changed_at"))
        .drop("op", "_lsn", "_changed_at", "_offset")
    )
    
def latest_per_key(df: DataFrame, key: str) -> DataFrame:
    """Keep only the most recent change per key (SCD1).

    Ordered by Postgres log position, with the Kafka offset as a tiebreak.
    If the newest change is a delete, the key is removed entirely.
    """
    order = Window.partitionBy(key).orderBy(F.col("_lsn").desc(), F.col("_offset").desc())
    return (
        df.withColumn("_rn", F.row_number().over(order))
        .filter((F.col("_rn") == 1) & (F.col("op") != "d"))
        .drop("_rn", "op", "_lsn", "_changed_at", "_offset")
    )