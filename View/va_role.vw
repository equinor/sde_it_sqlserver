DROP VIEW VA_ROLE;

/* Formatted on 28.05.2015 06:41:27 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW VA_ROLE
(
   GRANTED_ROLE,
   GRANTEE,
   SHORTNAME
)
AS
     SELECT granted_role,
            grantee,
            SUBSTR (SUBSTR (grantee,
                            1,
                              INSTR (grantee,
                                     '@',
                                     1,
                                     1)
                            - 1),
                    1,
                    8)
               shortname
       FROM dba_role_PRIVS
      WHERE granted_role NOT IN ('AQ_ADMINISTRATOR_ROLE',
                                 'AQ_USER_ROLE',
                                 'CONNECT',
                                 'DBA',
                                 'DELETE_CATALOG_ROLE',
                                 'EXECUTE_CATALOG_ROLE',
                                 'EXP_FULL_DATABASE',
                                 'GATHER_SYSTEM_STATISTICS',
                                 'HS_ADMIN_ROLE',
                                 'IMP_FULL_DATABASE',
                                 'LOGSTDBY_ADMINISTRATOR',
                                 'OEM_ADVISOR',
                                 'OEM_MONITOR',
                                 'RECOVERY_CATALOG_OWNER',
                                 'RESOURCE',
                                 'SCHEDULER_ADMIN',
                                 'SELECT_CATALOG_ROLE',
                                 'ADM_PARALLEL_EXECUTE_TASK',
                                 'CTXAPP',
                                 'DATAPUMP_EXP_FULL_DATABASE',
                                 'DATAPUMP_IMP_FULL_DATABASE',
                                 'DBFS_ROLE',
                                 'HS_ADMIN_EXECUTE_ROLE',
                                 'HS_ADMIN_SELECT_ROLE')
   ORDER BY granted_role, grantee;
