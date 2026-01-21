DROP VIEW VA_TABLE_LOCK_STATS;

/* Formatted on 28.05.2015 06:41:25 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW VA_TABLE_LOCK_STATS
(
   REGISTRATION_ID,
   TABLE_OWNER,
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
            l.table_owner,
            l.table_name,
            r.layer_id,
            r.spatial_column,
            COUNT (l.table_name) accumulated_lock_count,
            MAX (l.start_time) last_access,
            FLOOR (SYSDATE - MAX (l.start_time)) days_ago,
            DECODE (UPPER (l.nodename), 'ST-W2011', 'yes') "WEBMAP ST-W2011",
            DECODE (UPPER (l.nodename), 'ST-W2986', 'yes') "WEBMAP ST-W2986",
            DECODE (UPPER (l.nodename), 'ST-W3185', 'yes') "FME ST-W3185"
       FROM va_table_lock_history l, VA_TABLE_REGISTRY_ALL r
      WHERE     table_owner != 'SDE'
            AND l.nodename != 'PC-737415'
            AND r.owner = l.table_owner(+)
            AND r.table_name = l.table_name(+)
   GROUP BY r.layer_id,
            r.registration_id,
            l.table_owner,
            l.table_name,
            r.layer_id,
            r.spatial_column,
            DECODE (UPPER (l.nodename), 'ST-W2011', 'yes'),
            DECODE (UPPER (l.nodename), 'ST-W2986', 'yes'),
            DECODE (UPPER (l.nodename), 'ST-W3185', 'yes')
   ORDER BY l.table_owner, l.table_name;
