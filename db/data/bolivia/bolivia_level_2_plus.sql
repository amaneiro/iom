SELECT lugar AS name,
       2 AS level,
       adm_level_1 AS parent_region,
       avg(lat) AS center_lat,
       avg(lng) AS center_lon
FROM bd_aod_lugares
WHERE adm_level_2 IS NULL
GROUP BY lugar,
         adm_level_1
ORDER BY adm_level_1,
         lugar;
