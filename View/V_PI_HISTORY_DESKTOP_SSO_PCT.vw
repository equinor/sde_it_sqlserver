/* Formatted on 09.02.2016 08:07:03 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_PI_HISTORY_DESKTOP_SSO_PCT
(
   CONNECT_DATE,
   TOTAL,
   SSO,
   SCHEMA_OWNER,
   QUERY_USER,
   PERCENT_SSO
)
   BEQUEATH DEFINER
AS
     SELECT connect_date,
            COUNT (*) total,
            SUM (
               CASE WHEN UPPER (owner) LIKE '%STATOIL.NET%' THEN 1 ELSE 0 END)
               SSO,
            SUM (
               CASE
                  WHEN    UPPER (owner) LIKE '%ADM%'
                       OR UPPER (owner) = 'MILJODATA'
                  THEN
                     1
                  ELSE
                     0
               END)
               SCHEMA_OWNER,
            SUM (CASE WHEN UPPER (owner) LIKE '%QUERY%' THEN 1 ELSE 0 END)
               QUERY_USER,
            ROUND (
                 SUM (
                    CASE
                       WHEN UPPER (owner) LIKE '%STATOIL.NET%' THEN 1
                       ELSE 0
                    END)
               * 100
               / COUNT (*),
               0)
               percent_sso
       FROM (SELECT DISTINCT
                    TO_CHAR (start_time, 'YYYY-MM-DD') connect_date,
                    OWNER,
                    NODENAME
               FROM V_PI_HISTORY)
      WHERE     TO_CHAR (TO_DATE (connect_date, 'YYYY-MM-DD'), 'DY') NOT IN ('SAT',
                                                                             'SUN')
            AND UPPER (owner) NOT LIKE '"F_%'
            AND UPPER (owner) != 'SDE'
            AND (UPPER (nodename) LIKE 'PC%' OR UPPER (nodename) LIKE 'LT%')
   GROUP BY CONNECT_DATE
   ORDER BY connect_date DESC;

