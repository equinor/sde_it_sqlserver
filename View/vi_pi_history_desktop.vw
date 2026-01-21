/* Formatted on 09.02.2016 08:04:46 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_PI_HISTORY_DESKTOP
(
   SDE_ID,
   SERVER_ID,
   START_TIME,
   OWNER,
   DIRECT_CONNECT,
   SYSNAME,
   NODENAME,
   END_TIME
)
   BEQUEATH DEFINER
AS
     SELECT "SDE_ID",
            "SERVER_ID",
            "START_TIME",
            "OWNER",
            "DIRECT_CONNECT",
            "SYSNAME",
            "NODENAME",
            "END_TIME"
       FROM process_information_history
      WHERE UPPER (nodename) NOT LIKE '%W%'
   ORDER BY start_time DESC;
