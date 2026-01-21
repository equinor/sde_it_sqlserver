DROP VIEW VZ_VERSION_TABLES;

/* Formatted on 28.05.2015 06:41:24 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW VZ_VERSION_TABLES
(
   STATE_ID,
   REGISTRATION_ID,
   OWNER,
   TABLE_NAME
)
AS
   SELECT m.state_id,
          m.registration_id,
          r.owner,
          r.table_name
     FROM sde.mvtables_modified m, sde.table_registry r
    WHERE m.registration_id = r.registration_id;
