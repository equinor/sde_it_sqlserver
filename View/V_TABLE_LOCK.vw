/* Formatted on 27/05/2015 15:53:59 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW VA_TABLE_LOCK
(
   SDE_ID,
   REGISTRATION_ID,
   SERVER_ID,
   TABLE_NAME,
   START_TIME,
   NODENAME
)
AS
     SELECT p.sde_id,
            l.registration_id,
            p.server_id,
            r.owner || '.' || r.table_name,
            p.start_time,
            p.nodename
       FROM sde.table_locks l, sde.table_registry r, sde.process_information p
      WHERE l.registration_id = r.registration_id AND l.SDE_ID = p.SDE_ID
   ORDER BY r.owner || r.table_name ASC;

