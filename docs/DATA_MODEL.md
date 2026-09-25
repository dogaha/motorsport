# Data Model

## Gold layer entity relationships

```
                         dim_drivers (SCD1)
                         driver_id (PK)
                              ^
                              |
        +---------------------+---------------------+
        |                                            |
   dim_vehicles (SCD2)                          fct_sessions
   vehicle_id + version_number (PK)             session_id (PK)
   driver_id (FK, owner)                        driver_id (FK)
        ^                                        vehicle_id (FK)
        |                                        track_id (FK)
        +----------------------------------------+
                              |
                    +---------+---------+
                    |                   |
             fct_section_times    fct_warning
             session_id (FK)      session_id (FK)
             + lap + section_num  + sensor_name + reading_ts
             (grain, no own PK)   (grain, no own PK)
                    |                   |
                    v                   v
            dim_track_sections      sensors (dbt seed)
            section_id (PK)         sensor_name (PK)
            track_id (FK)
                    |
                    v
               dim_tracks
               track_id (PK)
```

## Grain by table

| Table | Grain | Type |
|-------|-------|------|
| dim_drivers | one row per driver | Dimension (SCD1) |
| dim_tracks | one row per track | Dimension (SCD1) |
| dim_track_sections | one row per track + section | Dimension (SCD1) |
| dim_vehicles | one row per vehicle + version | Dimension (SCD2) |
| sensors | one row per sensor | Reference (seed, static) |
| fct_sessions | one row per session | Fact (transaction) |
| fct_section_times | one row per session + lap + section | Fact (transaction, fine-grain) |
| fct_warning | one row per session + sensor + reading (out-of-range only) | Fact (event, sparse) |

`fct_sessions` is the hub: every other fact joins back through
`session_id`, and `driver_id`/`vehicle_id`/`track_id` are denormalized
onto the finer-grained facts (`fct_section_times`, `fct_warning`) rather
than requiring a join through `fct_sessions` to get them — a deliberate
star-schema tradeoff (query simplicity over strict normalization).

## Lineage (per layer)

```
RDS Postgres (drivers, vehicles, tracks, track_sections, sessions)
      |  (Debezium CDC, pgoutput)
      v
Kafka (Confluent Cloud) --- per-table topics
      |  (Databricks Structured Streaming, availableNow)
      v
bronze.cdc_<table>  (raw Debezium envelope, JSON string)
      |  (parse_envelope, convert_types, add_versions/latest_per_key)
      v
silver.<table>  (typed, one row per entity; vehicles = SCD2, rest = SCD1)
      |  (dbt, incremental merge/append)
      v
gold.dim_*, gold.fct_sessions


Generator (EC2) --- Parquet file per session
      |  (S3 landing/, Auto Loader, availableNow)
      v
bronze.telemetry  (raw sensor readings + GPS)
      |  (join to silver.sessions + silver.track_sections,
      |   derive lap/section from GPS, drop NaN -> null)
      v
silver.telemetry  (append-only, session-watermarked)
      |  (dbt, incremental)
      v
gold.fct_section_times, gold.fct_warning
      (joined against gold.sensors seed for min/max/normal thresholds)
```

## Key relationships and cardinality

- **driver → vehicle**: one driver can own multiple vehicles
  (`dim_vehicles.driver_id`), 1:N.
- **driver → session**: one driver, many sessions, 1:N.
- **vehicle → session**: one vehicle (at a specific version), many
  sessions over time, 1:N — but a vehicle can only be in one *open*
  session at a time (enforced at generator level, not DB constraint —
  see open issue below).
- **track → track_sections**: 1:N.
- **track → session**: 1:N.
- **session → section_times**: 1:N (one row per lap × section
  completed in that session).
- **session → warnings**: 1:N (zero or more; most sessions likely have
  zero rows here, by design — event fact, not populated for every
  session).
- **sensor → warnings**: 1:N (a sensor can appear in many warning
  events across many sessions).

## Slowly changing dimension handling

| Dimension | Type | Mechanism |
|-----------|------|-----------|
| dim_drivers | SCD1 | Latest state overwrites; no history kept |
| dim_tracks | SCD1 | Same |
| dim_track_sections | SCD1 | Same |
| dim_vehicles | **SCD2** | Full history via `version_number` + `valid_from`/`valid_to`; built in silver from the CDC change log, not via dbt snapshot |

`dim_vehicles` is the only dimension where history matters for
correctness — a session's telemetry and section times should reflect
the vehicle configuration *at the time of the session*, not the
vehicle's current spec. This is why it's the one dimension worth the
SCD2 complexity; the others don't have a use case that depends on their
history (documented as a deliberate scope decision, consistent with the
project's complexity-gating standard).

---

## Open issues found while building this model

These surfaced directly from the sample data — worth checking before
treating the schema as final:

1. **`dim_track_sections.section_type` casing differs from silver.**
   Silver sample shows lowercase (`"sweeper"`); gold sample shows title
   case (`"Hairpin"`). Either the generator produces mixed casing, or
   something in the gold transform is altering it — worth confirming
   which, since inconsistent casing will break any grouping/filtering
   downstream.

2. **`dim_track_sections.section_longitude`/`section_latitude` look
   swapped or lossy.** Silver's `start_coordinate` is `{x: -16, y: -93}`
   (doubles). Gold's sample row shows `section_longitude: -94,
   section_latitude: -49` as whole integers — different values than a
   direct x/y passthrough would produce, and truncated to int. If `x`
   maps to longitude and `y` to latitude, confirm that assignment is
   intentional and check why precision was dropped; sub-degree
   precision matters if any downstream consumer expects real-ish GPS
   coordinates.

3. **Duration column naming has drifted across this conversation.**
   Earlier iterations used `approximate_session_duration_seconds`
   (flagging that the value doesn't represent real elapsed time, since
   the generator compresses session length via `time.sleep(session_length_sec/60)`).
   The current gold sample shows a plain `session_duration_seconds`
   with no "approximate" qualifier — `3840` seconds for what the
   generator would have compressed to a few seconds of wall-clock
   time. If this column is meant to represent the *simulated* race
   duration (which `3840` seconds ≈ 64 minutes suggests, and is
   plausible for a 6-lap session), that's fine — but the dropped
   "approximate" naming loses the caveat that this is simulated time,
   not simulator wall-clock time. Worth a one-line comment in the model
   or a note in the README so nobody downstream assumes this is
   real-time telemetry duration.

4. **No visible DB-level constraint enforcing "one open session per
   vehicle."** The rule exists in generator logic (`create_session`'s
   `NOT EXISTS` check, `random_modify_vehicle`'s row lock), but nothing
   in the schema itself (e.g., a partial unique index on
   `sessions(vehicle_id) WHERE end_time IS NULL`) guarantees it can't be
   violated by a bug or a future direct write. Not a blocker, but worth
   naming as an application-level rather than data-level invariant if
   asked about it.

5. **`fct_warning`'s `min_valid`/`max_valid`/`normal_min`/`normal_max`
   are denormalized onto every warning row** rather than requiring a
   join to `sensors` to interpret a reading. That's a reasonable
   BI-friendly tradeoff, just flagging it as a deliberate denormalization
   rather than an oversight, since dim/fact modeling purists would
   normally expect that lookup to happen via the relationship rather
   than being copied at write time.