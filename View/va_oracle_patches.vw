DROP VIEW VA_ORACLE_PATCHES;

/* Formatted on 28.05.2015 06:41:27 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW VA_ORACLE_PATCHES
(
   NAME,
   ACTION_TIME,
   ID,
   ACTION,
   VERSION,
   COMMENTS
)
AS
     SELECT d.name,
            r.action_time,
            r.id,
            r.action,
            r.version,
            r.comments
       FROM v$database d, sys.registry$history r
   ORDER BY r.action_time DESC;
