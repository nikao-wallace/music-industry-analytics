USE ROLE MUSIC_ANALYTICS_ROLE;
USE WAREHOUSE MUSIC_WH;
USE DATABASE MUSIC_ANALYTICS;
USE SCHEMA RAW;

-- ============================================================
-- Profiling ARTISTS
-- Grain: one row per Artist
-- Primary key: artist_id
-- ============================================================


-- Validating one row per distinct artist_id
-- Validating no NULL or blank artist_id

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT artist_id) AS distinct_artist_ids,
    COUNT_IF(artist_id IS NULL) AS null_artist_ids,
    COUNT_IF(TRIM(artist_id) = '') AS blank_artist_ids
FROM MUSIC_ANALYTICS.RAW.ARTISTS;

SELECT
    COUNT_IF(artist_name IS NULL OR TRIM(artist_name) = '') AS missing_artist_names,
    COUNT_IF(genre IS NULL OR TRIM(genre) = '') AS missing_genres,
    COUNT_IF(signed_date IS NULL) AS missing_signed_dates,
    COUNT_IF(artist_status IS NULL OR TRIM(artist_status) = '') AS missing_artist_statuses,
    MIN(signed_date) AS earliest_signed_date,
    MAX(signed_date) AS latest_signed_date
FROM ARTISTS;

SELECT
    artist_status,
    COUNT(*) AS artist_count
FROM ARTISTS
GROUP BY artist_status
ORDER BY artist_count DESC;

-- Validating genres

SELECT
    genre,
    COUNT(*) AS artist_count
FROM ARTISTS
GROUP BY genre
ORDER BY genre;

-- Genres may need broader classifications to streamline segmentation


-- ============================================================
-- Profiling TRACKS
-- Grain: one row per Track
-- Primary key: track_id
-- ============================================================


-- Validating one row per distinct track_id
-- Validating no NULL or blank track_id
-- Validating distinct track names

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT track_id) AS distinct_track_ids,
    COUNT(DISTINCT track_name) AS distinct_track_names,
    COUNT_IF(track_id IS NULL) AS null_track_ids,
    COUNT_IF(TRIM(track_id) = '') AS blank_track_ids,
    COUNT_IF(duration_ms <= 0) AS impossible_duration
FROM MUSIC_ANALYTICS.RAW.TRACKS;

-- Checking for missing artist_id, track_name, duration_ms, or release_date
-- Earliest and latest release date 
SELECT
    COUNT_IF(artist_id IS NULL OR TRIM(artist_id) = '') AS missing_artist_id,
    COUNT_IF(track_name IS NULL OR TRIM(track_name) = '') AS missing_track_name,
    COUNT_IF(duration_ms IS NULL) AS missing_duration_ms,
    COUNT_IF(release_date IS NULL) AS missing_release_date,
    MIN(release_date) AS earliest_release_date,
    MAX(release_date) AS latest_release_date
FROM TRACKS;

-- Validating that every artist id in the tracks table is also in artists table

SELECT 
    COUNT(DISTINCT t.artist_id) AS missing_artist_ids
FROM TRACKS AS t
WHERE NOT EXISTS(
    SELECT 1 
    FROM ARTISTS AS a
    WHERE a.artist_id = t.artist_id
);




-- Checking shortest track and longest track

SELECT
    MIN(duration_ms) AS shortest_track_ms,
    MAX(duration_ms) AS longest_track_ms,
    ROUND(MIN(duration_ms) / 60000.0, 2) AS shortest_track_minutes,
    ROUND(MAX(duration_ms) / 60000.0, 2) AS longest_track_minutes
FROM TRACKS;

-- ============================================================
-- Profiling STREAM_EVENTS
-- Grain: one row per listening event
-- Primary key: stream_id
-- ============================================================

-- Checking compleatness of streaming event attributes

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT stream_id) AS distinct_stream_ids,
    COUNT_IF(stream_id IS NULL OR TRIM(stream_id) = '') AS missing_stream_ids,
    COUNT_IF(listener_id IS NULL OR TRIM(listener_id) = '') AS missing_listener_ids,
    COUNT_IF(track_id IS NULL OR TRIM(track_id) = '') AS missing_track_ids,
    COUNT_IF(stream_timestamp IS NULL) AS missing_stream_timestamps,
    COUNT_IF(ms_played IS NULL) AS missing_ms_played,
    COUNT_IF(streaming_platform IS NULL OR TRIM(streaming_platform) = '') AS missing_platforms,
    COUNT_IF(country IS NULL OR TRIM(country) = '') AS missing_countries,
    COUNT_IF(stream_source IS NULL OR TRIM(stream_source) = '') AS missing_stream_sources,
    COUNT_IF(device_type IS NULL OR TRIM(device_type) = '') AS missing_device_types
FROM STREAM_EVENTS;

-- Profiling observation:
-- 62 streams have no country and 79 have no device_type.
-- These are optional descriptive attributes, representing less than 0.1%
-- of stream events. Retain the events and classify missing dimensions as
-- unknown during staging.

-- Inspecting streaming platforms sources and device types

-- PLATFORM

SELECT streaming_platform, COUNT(*) AS stream_count
FROM STREAM_EVENTS
GROUP BY streaming_platform
ORDER BY streaming_platform;

-- SOURCE

SELECT stream_source, COUNT(*) AS stream_count
FROM STREAM_EVENTS
GROUP BY stream_source
ORDER BY stream_source;

-- DEVICE TYPE

SELECT device_type, COUNT(*) AS stream_count
FROM STREAM_EVENTS
GROUP BY device_type
ORDER BY device_type;

-- Observation as of 2026-08-19:
-- streaming_platform contains leading whitespace that splits identical
-- platforms into separate categories. Standardize with TRIM().
--
-- stream_source contains uppercase variants of lowercase snake-case values.
-- Standardize with LOWER(TRIM()).
--
-- device_type values are consistently lowercase; 79 missing values should
-- be retained and classified as 'unknown' during staging.

-- Checking that every track_id in streaming_events corrolates with a track_id in tracks

SELECT 
    COUNT(DISTINCT s.track_id ) AS missing_track_ids
FROM STREAM_EVENTS AS s
WHERE NOT EXISTS(
    SELECT 1 
    FROM TRACKS AS t
    WHERE s.track_id = t.track_id
);

--

SELECT
    MIN(s.stream_timestamp) AS earliest_stream,
    MAX(s.stream_timestamp) AS latest_stream,
    MIN(s.ms_played) AS minimum_ms_played,
    MAX(s.ms_played) AS maximum_ms_played,
    MAX(
    CASE
        WHEN s.ms_played > t.duration_ms
        THEN s.ms_played - t.duration_ms
    END
) AS maximum_overage_ms,
    COUNT_IF(
        CAST(s.stream_timestamp AS DATE) < t.release_date
    ) AS streams_before_release
FROM STREAM_EVENTS AS s
INNER JOIN TRACKS AS t
    ON s.track_id = t.track_id;

SELECT
    COUNT_IF(s.ms_played > t.duration_ms) AS any_overage,
    COUNT_IF(s.ms_played > t.duration_ms + 1000) AS over_by_more_than_1_second,
    COUNT_IF(s.ms_played > t.duration_ms + 5000) AS over_by_more_than_5_seconds,
    COUNT_IF(s.ms_played > t.duration_ms + 10000) AS over_by_more_than_10_seconds,
    MIN(
    CASE
        WHEN s.ms_played > t.duration_ms
        THEN s.ms_played - t.duration_ms
    END
        ) AS minimum_overage_ms,
    MAX(s.ms_played - t.duration_ms) AS maximum_difference_ms,
   ROUND(AVG(
    CASE
        WHEN s.ms_played > t.duration_ms
        THEN s.ms_played - t.duration_ms
    END
), 2) AS average_overage_ms
FROM STREAM_EVENTS AS s
INNER JOIN TRACKS AS t
    ON s.track_id = t.track_id;

-- Observation as of 2026-08-20:
-- 3 stream events report ms_played greater than track duration.
-- The maximum overage is approximately 6.9 seconds.
-- Retain these isolated source anomalies for staging-layer handling.

-- ============================================================
-- Profiling ENGAGEMENT_EVENTS
-- Grain: one row per engagement event
-- Primary key: engagement_id
-- ============================================================


SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT engagement_id) AS distinct_engagement_ids,
    COUNT_IF(engagement_id IS NULL OR TRIM(engagement_id) = '') AS missing_engagement_ids,
    COUNT_IF(listener_id IS NULL OR TRIM(listener_id) = '') AS missing_listener_ids,
    COUNT_IF(track_id IS NULL OR TRIM(track_id) = '') AS missing_track_ids,
    COUNT_IF(event_timestamp IS NULL) AS missing_event_timestamps,
    COUNT_IF(event_type IS NULL OR TRIM(event_type) = '') AS missing_event_types
FROM ENGAGEMENT_EVENTS;

--

SELECT
    event_type,
    COUNT(*) AS event_count
FROM ENGAGEMENT_EVENTS
GROUP BY event_type
ORDER BY event_type;

-- Observation: Only the three expected event types are present:
-- playlist_add, save, and share. Labels are consistently formatted.


-- Validating that all track id's in engagement_events are represented in tracks table

SELECT 
    COUNT(DISTINCT e.track_id) AS unknown_track_ids
FROM ENGAGEMENT_EVENTS AS e
WHERE NOT EXISTS(
    SELECT 1 
    FROM TRACKS AS t
    WHERE e.track_id = t.track_id
);

--

SELECT
    MIN(event_timestamp) AS min_event_date,
    MAX(event_timestamp) AS max_event_date,
    COUNT_IF(
        CAST(e.event_timestamp AS DATE) < t.release_date
    ) AS events_before_release
FROM ENGAGEMENT_EVENTS AS e
INNER JOIN TRACKS AS t 
ON e.track_id = t.track_id;

SELECT
    COUNT(*) AS engagements_without_prior_stream
FROM ENGAGEMENT_EVENTS AS e
WHERE NOT EXISTS (
    SELECT 1
    FROM STREAM_EVENTS AS s
    WHERE s.listener_id = e.listener_id
      AND s.track_id = e.track_id
      AND s.stream_timestamp <= e.event_timestamp
);

-- Observation: Every engagement event has a corresponding prior stream
-- for the same listener and track.

-- validating no duplicates

SELECT
    listener_id,
    track_id,
    event_timestamp,
    event_type,
    COUNT(*) AS duplicate_count
FROM ENGAGEMENT_EVENTS
GROUP BY
    listener_id,
    track_id,
    event_timestamp,
    event_type
HAVING COUNT(*) > 1;

-- ============================================================
-- Profiling MARKETING_CAMPAIGNS
-- Grain: one row per marketing campaign
-- Primary key: campaign_id
-- ============================================================

-- Validating no missing columns

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT campaign_id) AS distinct_campaign_ids,
    COUNT_IF(campaign_id IS NULL OR TRIM(campaign_id) = '') AS missing_campaign_ids,
    COUNT_IF(campaign_name IS NULL OR TRIM(campaign_name) = '') AS missing_campaign_names,
    COUNT_IF(artist_id IS NULL OR TRIM(artist_id) = '') AS missing_artist_ids,
    COUNT_IF(channel IS NULL OR TRIM(channel) = '') AS missing_channels,
    COUNT_IF(start_date IS NULL) AS missing_start_dates,
    COUNT_IF(end_date IS NULL) AS missing_end_dates,
    COUNT_IF(spend IS NULL) AS missing_spend
FROM MARKETING_CAMPAIGNS;

-- Validating column standardizations

SELECT
    channel,
    COUNT(*) AS campaign_count
FROM MARKETING_CAMPAIGNS
GROUP BY channel
ORDER BY channel;


-- Validating that every artist_id is represented in the ARTISTS table

SELECT
    COUNT(DISTINCT m.artist_id) AS missing_artist_ids
FROM MARKETING_CAMPAIGNS AS m
WHERE NOT EXISTS(
    SELECT 1
    FROM ARTISTS AS a
    WHERE m.artist_id = a.artist_id
);

SELECT
    COUNT_IF(start_date > end_date) AS impossible_dates,
    COUNT_IF(spend < 0) AS impossible_spend,
    SUM(spend) AS total_spend,
    MIN(spend) AS minimum_spend,
    MAX(spend) AS maximum_spend,
    ROUND(
        AVG(spend),2) AS avg_spend,
    MIN(start_date) AS earliest_campaign_start,
MAX(end_date) AS latest_campaign_end
FROM MARKETING_CAMPAIGNS;

SELECT
    campaign_id,
    artist_id,
    campaign_name,
    channel,
    start_date,
    end_date,
    spend
FROM MARKETING_CAMPAIGNS
WHERE end_date > '2026-08-15'
ORDER BY end_date;


-- Observation: 3 campaigns end after the behavioral-data cutoff.
-- CMP038 is partially observed; CMP044 and CMP014 begin after the
-- cutoff and therefore have no observable campaign-period outcomes.

SELECT
    a.artist_id,
    a.channel,

    a.campaign_id AS campaign_a_id,
    a.campaign_name AS campaign_a_name,
    a.start_date AS campaign_a_start_date,
    a.end_date AS campaign_a_end_date,

    b.campaign_id AS campaign_b_id,
    b.campaign_name AS campaign_b_name,
    b.start_date AS campaign_b_start_date,
    b.end_date AS campaign_b_end_date

FROM MARKETING_CAMPAIGNS AS a

INNER JOIN MARKETING_CAMPAIGNS AS b
    ON a.artist_id = b.artist_id
    AND a.channel = b.channel
    AND a.campaign_id < b.campaign_id
    AND a.start_date <= b.end_date
    AND b.start_date <= a.end_date

ORDER BY
    a.artist_id,
    a.channel,
    a.start_date;

-- Observation: No campaigns overlap for the same artist and channel.
-- Three campaigns are not fully observable within the behavioral-data window.

-- ============================================================
-- Final profiling summary
-- ============================================================
-- 1. Standardize streaming_platform with TRIM().
-- 2. Standardize stream_source with LOWER(TRIM()).
-- 3. Classify missing country and device_type values as 'unknown'.
-- 4. Handle the 3 isolated ms_played overages explicitly.
-- 5. Preserve campaign observation-window status for later analysis.
-- 6. No orphaned foreign keys or semantic duplicates were identified.