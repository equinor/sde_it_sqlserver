DROP VIEW V_SDE_PROCESS;

/* Formatted on 28.05.2015 06:41:22 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_SDE_PROCESS
(
   SID,
   SERIAL,
   SDE_ID,
   START_TIME,
   OWNER,
   NODENAME,
   PROGRAM,
   SERVER_ID,
   PROCESS_ID
)
AS
     SELECT s.sid,
            s.serial#,
            pi.sde_id,
            pi.start_time,
            pi.owner,
            pi.nodename,
            s.program,
            pi.server_id,
            SUBSTR (s.process, 1, INSTR (s.process, ':') - 1)
       FROM sde.process_information pi, v$session s
      WHERE SUBSTR (s.process, 1, INSTR (s.process, ':') - 1) = pi.server_id
   ORDER BY start_time ASC;
