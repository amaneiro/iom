COPY (SELECT p.titulo AS project,
             s.socio_long_name AS donor,
             sp.socio_aporte AS amount
      FROM bd_aod_socios_proyectos sp,
           bd_aod_socio s,
           bd_aod_proyecto p
      WHERE sp.socio_id = s.socio_id
            AND sp.project_id = p.project_id
            AND socio_aporte > 0)
TO '/tmp/donations.csv'
WITH CSV HEADER;
