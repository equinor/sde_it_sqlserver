DROP VIEW V_PI_HISTORY_OTHER_LAST_30;

/* Formatted on 28.05.2015 06:41:23 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_PI_HISTORY_OTHER_LAST_30
(
   NODENAME,
   LAST_CONNECTED,
   CONNECTION_COUNT
)
AS
     SELECT DISTINCT
            nodename server,
            MAX (start_time) last_connected,
            COUNT (nodename) connection_count
       FROM v_pi_history
      WHERE     LOWER (nodename) NOT LIKE 'pc%'
            AND LOWER (nodename) NOT LIKE 'lt%'
            AND LOWER (nodename) NOT LIKE '%-ts%'
            AND LOWER (nodename) NOT IN (SELECT LOWER (server)
                                           FROM V_PI_HISTORY_SERVER_LAST_30)
            AND start_time > SYSDATE - 30
   GROUP BY nodename
   ORDER BY MAX (start_time) DESC;
