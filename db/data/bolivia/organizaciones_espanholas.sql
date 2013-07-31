COPY (SELECT socio_short_name AS organization_id,
             socio_long_name AS name,
             socio_url AS website
      FROM bd_aod_socio
      WHERE socio_tipo = 'OE'
      ORDER BY socio_short_name)
TO '/tmp/organizaciones_espanholas.csv'
WITH CSV HEADER;
