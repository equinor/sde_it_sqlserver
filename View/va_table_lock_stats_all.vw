DROP VIEW VA_TABLE_LOCK_STATS_ALL;

/* Formatted on 28.05.2015 06:41:25 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW VA_TABLE_LOCK_STATS_ALL
(
   REGISTRATION_ID,
   OWNER,
   TABLE_NAME,
   LAYER_ID,
   SPATIAL_COLUMN,
   ACCUMULATED_LOCK_COUNT,
   LAST_ACCESS,
   DAYS_AGO,
   WEBMAP_ST_W2011,
   WEBMAP_ST_W2986,
   FME_ST_W3185
)
AS
   SELECT r.registration_id,
          r.owner,
          r.table_name,
          r.layer_id,
          r.spatial_column,
          l.accumulated_lock_count,
          l.last_access,
          l.days_ago,
          l.WEBMAP_ST_W2011,
          l.webmap_st_w2986,
          l.fme_st_w3185
     FROM VA_TABLE_REGISTRY_ALL r, va_table_lock_stats l
    WHERE r.registration_id = l.registration_id(+);
