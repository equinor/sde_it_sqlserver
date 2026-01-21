DROP VIEW ROLES_AND_FEATURECLASSES;

/* Formatted on 28.05.2015 06:41:28 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW ROLES_AND_FEATURECLASSES
(
   GRANTEE,
   OWNER,
   FEATURECLASS,
   READ,
   EDIT
)
AS
     SELECT DISTINCT SUBSTR (grantee, 1, 8),
                     SUBSTR (owner, 1, 8),
                     SUBSTR (featureclass, 1, 30),
                     MAX (select_priv),
                     MAX (edit_priv)
       FROM (SELECT GRANTEE,
                    OWNER,
                    FEATURECLASS,
                    DECODE (PRIVILEGE, 'SELECT', 'READ') SELECT_PRIV,
                    DECODE (PRIVILEGE,
                            'INSERT', 'EDIT',
                            'UPDATE', 'EDIT',
                            'DELETE', 'EDIT')
                       EDIT_PRIV
               FROM VA_ROLES_AND_FEATURECLASSES)
   GROUP BY grantee, owner, featureclass
   ORDER BY 2, 3;
