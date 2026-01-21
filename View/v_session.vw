DROP VIEW V_SESSION;

/* Formatted on 28.05.2015 06:41:22 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_SESSION
(
   SID,
   USERNAME,
   STATUS,
   SCHEMANAME,
   OSUSER,
   MACHINE,
   PROGRAM,
   LOGON_TIME
)
AS
     SELECT sid,
            username,
            status,
            schemaname,
            osuser,
            machine,
            program,
            logon_time
       FROM v$session
   ORDER BY logon_time DESC;
