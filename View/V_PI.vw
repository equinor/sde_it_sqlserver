/* Formatted on 27/05/2015 15:50:19 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_PI
(
   SDE_ID,
   SERVER_ID,
   START_TIME,
   OWNER,
   DIRECT_CONNECT,
   SYSNAME,
   NODENAME
)
AS
     SELECT "SDE_ID",
            "SERVER_ID",
            "START_TIME",
            "OWNER",
            "DIRECT_CONNECT",
            "SYSNAME",
            "NODENAME"
       FROM sde.process_information
   ORDER BY start_time DESC;
