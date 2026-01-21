/* Formatted on 27/05/2015 15:54:14 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW V_VERSION
(
   INSTANCE_NAME,
   ORACLE_VERSION,
   SDE_VERSION
)
AS
   SELECT o.instance_name,
          o.version oracle_version,
          s.major || '.' || s.minor || '.' || s.bugfix sde_version
     FROM v$instance o, sde.version s;

