DROP VIEW VA_FAILED_LOGON_30D;

/* Formatted on 28.05.2015 06:41:27 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW VA_FAILED_LOGON_30D
(
   OS_USERNAME,
   USERNAME,
   USERHOST,
   TERMINAL,
   TIMESTAMP,
   ACTION,
   ACTION_NAME,
   RETURNCODE,
   ERROR_MESSAGE
)
AS
     SELECT "OS_USERNAME",
            "USERNAME",
            "USERHOST",
            "TERMINAL",
            "TIMESTAMP",
            "ACTION",
            "ACTION_NAME",
            "RETURNCODE",
            CASE returncode
               WHEN 1017 THEN 'Invalid username/password'
               WHEN 28000 THEN 'Account Locked'
            END
               Error_message
       FROM dba_audit_trail
      WHERE returncode IN (1017, 28000) AND timestamp > SYSDATE - 30
   ORDER BY timestamp DESC;
