DROP VIEW V_PI_HISTORY_USERS_30D;

/* Formatted on 28.05.2015 06:41:22 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_PI_HISTORY_USERS_30D
(
   CONNECT_DATE,
   NODENAME,
   OWNER,
   SHORTNAME,
   USERNAME,
   ORG_UNIT
)
AS
     SELECT DISTINCT
            TO_DATE (TO_CHAR (p.start_time, 'YYYY-MM-DD'), 'YYYY-MM-DD')
               connect_date,
            p.NODENAME,
            p.OWNER,
            a.shortname,
            a.username,
            a.org_unit
       FROM SDE_IT.V_PI_HISTORY p, T_TREND_USER_HOST_LOCATION_90D a
      WHERE     p.nodename = a.HOST(+)
            AND ABS (p.start_time - a.log_date) < 0.2
            AND UPPER (nodename) NOT LIKE '%W%'
            AND p.start_time > SYSDATE - 30
   ORDER BY TO_DATE (TO_CHAR (p.start_time, 'YYYY-MM-DD'), 'YYYY-MM-DD') DESC,
            a.shortname;
