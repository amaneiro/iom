COPY (SELECT socio_short_name AS organization_id,
             socio_long_name AS name,
             socio_url AS website
      FROM bd_aod_socio
      ORDER BY socio_short_name)
TO '/tmp/organizaciones.csv'
WITH CSV HEADER;
