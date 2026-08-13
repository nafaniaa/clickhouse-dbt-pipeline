{{ config(materialized='table') }}

SELECT
    craft,
    count(name) AS astronauts_count,
    now() AS _transformed_at
FROM default.people
GROUP BY craft
ORDER BY astronauts_count DESC