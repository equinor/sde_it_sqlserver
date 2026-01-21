/* Formatted on 27/05/2015 15:54:24 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_USER_SESSION
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

