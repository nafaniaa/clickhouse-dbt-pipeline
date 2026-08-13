CREATE TABLE IF NOT EXISTS default.raw_table (
    raw_data String,
    insert_time DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY insert_time;

CREATE TABLE IF NOT EXISTS default.people (
    craft String,
    name String,
    _inserted_at DateTime
) ENGINE = ReplacingMergeTree(_inserted_at)
ORDER BY (craft, name);

CREATE MATERIALIZED VIEW IF NOT EXISTS default.mv_parse_people
TO default.people
AS
SELECT
    JSONExtractString(arrayJoin(JSONExtractArrayRaw(raw_data, 'people')), 'craft') AS craft,
    JSONExtractString(arrayJoin(JSONExtractArrayRaw(raw_data, 'people')), 'name') AS name,
    insert_time AS _inserted_at
FROM default.raw_table;