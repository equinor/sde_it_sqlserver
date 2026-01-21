DROP VIEW V_PI_HISTORY_USERS_LTPC_30D;

/* Formatted on 28.05.2015 06:41:22 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_PI_HISTORY_USERS_LTPC_30D
(
   CONNECT_DATE,
   NODENAME,
   OWNER,
   NAME,
   ORG_UNIT
)
AS
     SELECT DISTINCT
            TO_DATE (TO_CHAR (p.start_time, 'YYYY-MM-DD'), 'YYYY-MM-DD'),
            p.NODENAME,
            p.OWNER,
            a.name,
            a.org_unit
       FROM SDE_IT.V_PI_HISTORY p, arcgis_user_host a
      WHERE     UPPER (p.nodename) = UPPER (a.HOST)
            AND ABS (p.start_time - a.log_date) < 4
            AND (UPPER (nodename) LIKE 'LT%' OR UPPER (nodename) LIKE 'PC%')
            AND p.start_time > SYSDATE - 30
   ORDER BY TO_DATE (TO_CHAR (p.start_time, 'YYYY-MM-DD'), 'YYYY-MM-DD') DESC,
            a.name;
