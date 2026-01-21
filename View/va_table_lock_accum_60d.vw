DROP VIEW VA_TABLE_LOCK_ACCUM_60D;

/* Formatted on 28.05.2015 06:41:25 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW VA_TABLE_LOCK_ACCUM_60D
(
   OWNER,
   TABLE_NAME,
   ACCUMULATED_LOCK_COUNT
)
AS
     SELECT table_owner, table_name, COUNT (table_name) accumulated_lock_count
       FROM va_table_lock_history l
      WHERE table_owner != 'SDE' AND start_time > SYSDATE - 60
   GROUP BY table_owner, table_name
   ORDER BY COUNT (table_name) DESC;
