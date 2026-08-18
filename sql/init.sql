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
    JSONExtractString(person_json, 'craft') AS craft,
    JSONExtractString(person_json, 'name') AS name,
    insert_time AS _inserted_at
FROM (
    SELECT
        arrayJoin(JSONExtractArrayRaw(raw_data, 'people')) AS person_json,
        insert_time
    FROM default.raw_table
);