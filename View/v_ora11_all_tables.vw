DROP VIEW V_ORA11_ALL_TABLES;

/* Formatted on 28.05.2015 06:41:24 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_ORA11_ALL_TABLES
(
   REGISTRATION_ID,
   OWNER,
   TABLE_NAME,
   ROWID_COLUMN,
   SPATIAL_COLUMN
)
AS
     SELECT r.registration_id,
            r.owner,
            r.table_name,
            r.rowid_column,
            l.spatial_column
       FROM sde.table_registry r, sde.layers l
      WHERE     r.owner != 'SDE'
            AND r.owner = l.owner(+)
            AND r.table_name = l.table_name(+)
   ORDER BY owner, table_name;
