DROP VIEW VA_DATABASE_USERS;

/* Formatted on 28.05.2015 06:41:27 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW VA_DATABASE_USERS
(
   INSTANCE_NAME,
   USERNAME,
   ACCOUNT_STATUS,
   EXPIRY_DATE,
   WARNING_DATE
)
AS
     SELECT o.instance_name,
            u.username,
            u.account_status,
            u.expiry_date,
            u.expiry_date - 120 warning_date
       FROM dba_users u, v$instance o
      WHERE     username NOT LIKE '%STATOIL.NET%'
            AND (   username IN (SELECT DISTINCT owner FROM sde.layers)
                 OR username = 'SDE_IT'
                 OR username = 'SDE')
   ORDER BY username;
