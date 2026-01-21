DROP VIEW V_PI_HISTORY_SERVER_LAST_90;

/* Formatted on 28.05.2015 06:41:22 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_PI_HISTORY_SERVER_LAST_90
(
   SERVER,
   LAST_CONNECTED,
   CONNECTION_COUNT
)
AS
     SELECT DISTINCT
            nodename server,
            MAX (start_time) last_connected,
            COUNT (nodename) connection_count
       FROM v_pi_history
      WHERE LOWER (nodename) LIKE '%w%' AND start_time > SYSDATE - 90
   GROUP BY nodename
   ORDER BY MAX (start_time) DESC;
