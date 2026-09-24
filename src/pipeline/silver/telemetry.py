from pyspark.sql import DataFrame, Window
from pyspark.sql import functions as F


def clean_telemetry(df: DataFrame, sensor_cols: list) -> DataFrame:
    """Convert NaN to null in sensor columns and drop exact duplicate rows.

    NaN is a value in Spark, so isNull() would miss it. Spikes are left as
    they are: they are impossible values, and gold decides what to do
    with them.
    """
    for c in sensor_cols:
        df = df.withColumn(c, F.when(F.isnan(c), None).otherwise(F.col(c)))
    return df.dropDuplicates(["session_id", "timestamp"])


def assert_positions_valid(df: DataFrame) -> None:
    """Fail loudly if any latitude/longitude is null or NaN.

    Section matching relies on exact coordinates, so a missing position
    would silently put a whole section in the wrong place.
    """
    bad = df.filter(
        F.col("latitude").isNull()
        | F.isnan("latitude")
        | F.col("longitude").isNull()
        | F.isnan("longitude")
    ).count()
    if bad:
        raise ValueError(f"{bad} rows have null/NaN positions")


def add_sections(telemetry: DataFrame, sections: DataFrame) -> DataFrame:
    """Label each reading with the track section it belongs to.

    A reading whose (latitude, longitude) equals a section's start
    coordinate begins that section. The section is then carried forward
    over the following readings, ordered by timestamp within the session.
    `sections` needs: track_id, section_number, start_x (longitude),
    start_y (latitude).
    """
    s = sections.select(
        F.col("track_id").alias("_s_track_id"),
        "section_number",
        "start_x",
        "start_y",
    )
    matched = telemetry.join(
        s,
        (telemetry["track_id"] == s["_s_track_id"])
        & (telemetry["latitude"] == s["start_x"])
        & (telemetry["longitude"] == s["start_y"]),
        "left",
    ).select(telemetry["*"], s["section_number"])

    order = (
        Window.partitionBy("session_id")
        .orderBy("timestamp")
        .rowsBetween(Window.unboundedPreceding, Window.currentRow)
    )
    return matched.withColumn(
        "section_number", F.last("section_number", ignorenulls=True).over(order)
    )


def assert_sections_matched(df: DataFrame) -> None:
    """Fail loudly if any session has no section matches at all.

    A swapped x/y or a coordinate that never lands exactly would otherwise
    give all-null sections and lap 0 with no error.
    """
    unmatched = (
        df.groupBy("session_id")
        .agg(F.count("section_number").alias("n"))
        .filter("n = 0")
    )
    if unmatched.limit(1).count() > 0:
        ids = [r["session_id"] for r in unmatched.collect()]
        raise ValueError(f"no section matches for sessions: {ids}")


def add_laps(df: DataFrame, first_section: int = 1) -> DataFrame:
    """Number laps by counting each time the first section starts.

    The counter increments on a row where the section changes to the first
    section. Readings before the first such row have lap 0.
    """
    order = Window.partitionBy("session_id").orderBy("timestamp")
    prev = F.lag("section_number").over(order)
    starts_lap = (F.col("section_number") == first_section) & (
        prev.isNull() | (prev != first_section)
    )
    running = (
        Window.partitionBy("session_id")
        .orderBy("timestamp")
        .rowsBetween(Window.unboundedPreceding, Window.currentRow)
    )
    return df.withColumn("lap", F.sum(F.when(starts_lap, 1).otherwise(0)).over(running))