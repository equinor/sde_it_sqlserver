/* Formatted on 27/05/2015 15:54:35 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_PI_HISTORY
(
   SDE_ID,
   SERVER_ID,
   AUDSID,
   START_TIME,
   OWNER,
   DIRECT_CONNECT,
   SYSNAME,
   NODENAME,
   PROXY_YN,
   PARENT_SDE_ID,
   END_TIME
)
AS
     SELECT "SDE_ID",
            "SERVER_ID",
            "AUDSID",
            "START_TIME",
            "OWNER",
            "DIRECT_CONNECT",
            "SYSNAME",
            "NODENAME",
            "PROXY_YN",
            "PARENT_SDE_ID",
            "END_TIME"
       FROM process_information_history
   ORDER BY start_time DESC;

