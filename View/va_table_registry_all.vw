DROP VIEW VA_TABLE_REGISTRY_ALL;

/* Formatted on 28.05.2015 06:41:25 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW VA_TABLE_REGISTRY_ALL
(
   REGISTRATION_ID,
   OWNER,
   TABLE_NAME,
   ROWID_COLUMN,
   LAYER_ID,
   SPATIAL_COLUMN
)
AS
     SELECT r.registration_id,
            r.owner,
            r.table_name,
            r.rowid_column,
            l.layer_id,
            l.spatial_column
       FROM sde.table_registry r, sde.layers l
      WHERE     r.owner != 'SDE'
            AND r.owner = l.owner(+)
            AND r.table_name = l.table_name(+)
   ORDER BY owner, table_name;
