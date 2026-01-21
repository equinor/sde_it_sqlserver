DROP VIEW VA_ROLES_AND_FEATURECLASSES;

/* Formatted on 28.05.2015 06:41:26 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW VA_ROLES_AND_FEATURECLASSES
(
   GRANTEE,
   OWNER,
   FEATURECLASS,
   PRIVILEGE
)
AS
   SELECT t.grantee,
          l.owner,
          l.table_name,
          t.privilege
     FROM sde.layers l, dba_tab_privs t
    WHERE     l.owner = t.owner(+)
          AND l.table_name = t.table_name(+)
          AND l.table_name NOT LIKE '%_H'
          AND l.owner != 'SDE'
          AND grantee NOT IN ('SDE',
                              'SDE_QUERY',
                              'R19_QUERY',
                              'SHELL');
