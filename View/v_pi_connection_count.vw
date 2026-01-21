DROP VIEW V_PI_CONNECTION_COUNT;

/* Formatted on 28.05.2015 06:41:24 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_PI_CONNECTION_COUNT
(
   INSTANCE_NAME,
   SDE_SERVER_CONNECTIONS,
   DIRECT_CONNECTIONS,
   TOTAL_CONNECTIONS
)
AS
     SELECT i.instance_name,
            MAX (DECODE (connect_type, 'sde', COUNT)) sde_server_connections,
            MAX (DECODE (connect_type, 'dc', COUNT)) direct_connections,
            MAX (DECODE (connect_type, 'total', COUNT)) total_connections
       FROM (SELECT 'sde' connect_type, COUNT (*) COUNT
               FROM v_pi
              WHERE UPPER (direct_connect) IN ('N', 'F')
             UNION ALL
             SELECT 'dc', COUNT (*) direct
               FROM v_pi
              WHERE UPPER (direct_connect) IN ('T', 'Y')
             UNION ALL
             SELECT 'total', COUNT (*) FROM v_pi) a,
            v$instance i
   GROUP BY i.instance_name;
