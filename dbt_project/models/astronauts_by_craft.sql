{{ config(materialized='table') }}

SELECT
    craft,
    count(name) AS astronauts_count,
    now() AS _transformed_at
FROM {{ source('my_clickhouse_db', 'people') }} FINAL
GROUP BY craft
ORDER BY astronauts_count DESC