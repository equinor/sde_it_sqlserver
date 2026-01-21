CREATE_PROCEDURE(recompile_invalid_objects) (
   o_owner IN VARCHAR2 := USER
 , o_name IN VARCHAR2 := '%'
 , o_type IN VARCHAR2 := '%'
 , o_status IN VARCHAR2 := 'INVALID'
)
AUTHID CURRENT_USER
/*****************************************************************
*  Function Info
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: 2020/08/24 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:   Exp $
*   Revision History: $Revision: 1.0 $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*   Copyright       : $Equinor ASA: $
*****************************************************************
* Description
*
*****************************************************************
* Log
* Date   Description                                        Done by
* 170223 Including VIEW                                     JOTHOR
*****************************************************************/

-------------------------------------------------------------------
-- FILE: recompile.sql
-- TITLE:   Recompile Utility
-- AUTHOR:  Solomon Yakobson
--
--    Objects are recompiled based on object dependencies and
--    therefore compiling  all requested objects in one path.
--    Recompile Utility skips every object which is either of
--    unsupported object type or depends on INVALID object(s)
--    outside of current request (which means we know upfront
--    compilation will fail anyway).  If object recompilation
--    is not successful, Recompile Utility continues with the
--    next object. Recompile Utility has five parameters:
--
--      o_owner  - IN  mode  parameter is a VARCHAR2 defining
--            owner  of to  be  recompiled  objects.  It
--            accepts operator LIKE widcards.  Backslash
--            (\)  is used  for escaping  wildcards.  If
--            omitted, parameter defaults to USER.
--      o_name   - IN  mode  parameter is a VARCHAR2 defining
--            names  of to  be  recompiled  objects.  It
--            accepts operator LIKE widcards.  Backslash
--            (\)  is used  for escaping  wildcards.  If
--            omitted, it defaults to '%' - any name.
--      o_type   - IN  mode  parameter is a VARCHAR2 defining
--            types  of to  be  recompiled  objects.  It
--            accepts operator LIKE widcards.  Backslash
--            (\)  is used  for escaping  wildcards.  If
--            omitted, it defaults to '%' - any type.
--      o_status - IN  mode  parameter is a VARCHAR2 defining
--            status of to  be  recompiled  objects.  It
--            accepts operator LIKE widcards.  Backslash
--            (\)  is used  for escaping  wildcards.  If
--            omitted, it defaults  to 'INVALID'.
--
--    Recompile Utility returns the following values or their
--    combinations:
--
--      0 - Success. All requested objects are recompiled and
--          are VALID.
--      1 - INVALID_TYPE. At least one  of to  be  recompiled
--          objects is not of supported object type.
--      2 - INVALID_PARENT. At  least one of to be recompiled
--          objects depends on an  invalid object outside  of
--          current request.
--      4 - COMPILE_ERRORS. At  least one of to be recompiled
--          objects was compiled with errors and is INVALID.
--
-------------------------------------------------------------------
IS
   DECLARE_VARIABLE;

   -- Exceptions
   success_with_error EXCEPTION;
   PRAGMA EXCEPTION_INIT (success_with_error, -24344);
   -- Return Codes
   invalid_type CONSTANT INTEGER := 1;
   invalid_parent CONSTANT INTEGER := 2;
   compile_errors CONSTANT INTEGER := 4;
   cnt NUMBER;
   dyncur INTEGER;
   type_status INTEGER := 0;
   parent_status INTEGER := 0;
   recompile_status INTEGER := 0;
   object_status VARCHAR2 (30);

   lCount integer := 0;
   lFailure integer := 0;
   lFailureDependency integer := 0;

   CURSOR invalid_parent_cursor (
      oowner VARCHAR2
    , oname VARCHAR2
    , otype VARCHAR2
    , ostatus VARCHAR2
    , OID NUMBER
   )
   IS
      SELECT /*+ RULE */
             o.object_id
        FROM public_dependency d, all_objects o
       WHERE d.object_id = OID
         AND o.object_id = d.referenced_object_id
         AND o.status != 'VALID'
      MINUS
      SELECT /*+ RULE */
             object_id
        FROM all_objects
       WHERE owner LIKE UPPER (oowner)
         AND object_name LIKE UPPER (oname)
         AND object_type LIKE UPPER (otype)
         AND status LIKE UPPER (ostatus);

   CURSOR recompile_cursor (OID NUMBER)
   IS
      SELECT /*+ RULE */
                'ALTER '
             || DECODE (object_type
                      , 'PACKAGE BODY', 'PACKAGE'
                      , 'TYPE BODY', 'TYPE'
                      ,'VIEW'
                      , object_type
                       )
             || ' '
             || owner
             || '.'
             || object_name
             || ' COMPILE '
             || DECODE (object_type
                      , 'PACKAGE BODY', ' BODY'
                      , 'TYPE BODY', 'BODY'
                      , 'TYPE', 'SPECIFICATION'
                      ,'VIEW'
                      , ''
                       ) stmt
           , object_type, owner, object_name
        FROM all_objects
       WHERE object_id = OID;

   recompile_record recompile_cursor%ROWTYPE;

   CURSOR obj_cursor (
      oowner VARCHAR2
    , oname VARCHAR2
    , otype VARCHAR2
    , ostatus VARCHAR2
   )
   IS
      SELECT     /*+ RULE */
                 MAX (LEVEL) dlevel, object_id
            FROM SYS.public_dependency
      START WITH object_id IN (
                    SELECT object_id
                      FROM all_objects
                     WHERE owner LIKE UPPER (oowner)
                       AND object_name LIKE UPPER (oname)
                       AND object_type LIKE UPPER (otype)
                       AND status LIKE UPPER (ostatus))
      CONNECT BY object_id = PRIOR referenced_object_id
        GROUP BY object_id
          HAVING MIN (LEVEL) = 1
      UNION ALL
      SELECT   1 dlevel, object_id
          FROM all_objects o
         WHERE owner LIKE UPPER (oowner)
           AND object_name LIKE UPPER (oname)
           AND object_type LIKE UPPER (otype)
           AND status LIKE UPPER (ostatus)
           AND NOT EXISTS (SELECT 1
                             FROM SYS.public_dependency d
                            WHERE d.object_id = o.object_id)
      ORDER BY 1 DESC;

   CURSOR status_cursor (OID NUMBER)
   IS
      SELECT /*+ RULE */
             status
        FROM all_objects
       WHERE object_id = OID;
BEGIN
   -- Recompile requested objects based on their dependency levels.
   dyncur := DBMS_SQL.open_cursor;

   FOR obj_record IN obj_cursor (o_owner
                               , o_name
                               , o_type
                               , o_status
                                )
   LOOP
      OPEN recompile_cursor (obj_record.object_id);

      FETCH recompile_cursor
       INTO recompile_record;

      CLOSE recompile_cursor;
      DEBUG('After close of cursor:'||recompile_record.stmt);

      --------------------------------------------------------------------
      -- We can recompile only Functions, Packages, Package Bodies,
      -- Procedures, Triggers, Views, Types and Type Bodies.
      -- NOTE: Due to m4 macro expansion, two objects must be "escaped"
      -- so as not to be incorrectly expanded during macro processing.
      --------------------------------------------------------------------
      IF (recompile_record.object_type IN
           ('<&>FUNCTION<%>'
           ,'<&>PROCEDURE<%>'
           ,'PACKAGE'
           ,'PACKAGE BODY'
           ,'TRIGGER'
           ,'VIEW'
           ,'TYPE'
           ,'TYPE BODY'
           ) 
         and recompile_record.object_name not like '%==$0' -- skip objects ending with this nam
        )
      THEN
         -- There is no sense to recompile an object that depends on
         -- invalid objects outside of the current recompile request.
         OPEN invalid_parent_cursor (o_owner
                                   , o_name
                                   , o_type
                                   , o_status
                                   , obj_record.object_id
                                    );

         FETCH invalid_parent_cursor INTO cnt;

         lCount := lCount + 1;

         IF invalid_parent_cursor%NOTFOUND THEN
          -- Recompile object.
            DEBUG('Start recompile: '||recompile_record.stmt);
            BEGIN
               DBMS_SQL.parse (dyncur
                             , recompile_record.stmt
                             , DBMS_SQL.native
                              );
            EXCEPTION
               WHEN success_with_error
               THEN
                  NULL;
            END;

            OPEN status_cursor (obj_record.object_id);

            FETCH status_cursor
             INTO object_status;

            CLOSE status_cursor;

            IF object_status <> 'VALID' THEN
               DEBUG('Compile failed: '||recompile_record.stmt);
               LOG(LEVEL_HIGH,'Compile failed: '||recompile_record.stmt);
               lFailure := lFailure + 1;
               recompile_status := compile_errors;
            END IF;
         ELSE
            DEBUG('Dependent upon other invalid: '||recompile_record.stmt);
            LOG(LEVEL_HIGH,'Dependent upon other invalid: '||recompile_record.stmt);
            lFailureDependency := lFailureDependency + 1;
            parent_status := invalid_parent;
         END IF;

         CLOSE invalid_parent_cursor;
      ELSE
         type_status := invalid_type;
      END IF;
   END LOOP;

   DBMS_SQL.close_cursor (dyncur);
   DEBUG('Report: Total invalid: '|| lCount||'; compile failure: '|| lFailure || '; dependency invalid: '||lFailureDependency);
EXCEPTION
   WHEN OTHERS THEN
      IF obj_cursor%ISOPEN THEN
         CLOSE obj_cursor;
      END IF;

      IF recompile_cursor%ISOPEN THEN
         CLOSE recompile_cursor;
      END IF;

      IF invalid_parent_cursor%ISOPEN THEN
         CLOSE invalid_parent_cursor;
      END IF;

      IF status_cursor%ISOPEN THEN
         CLOSE status_cursor;
      END IF;

      IF DBMS_SQL.is_open (dyncur) THEN
         DBMS_SQL.close_cursor (dyncur);
      END IF;

      RAISE;
END_CREATE_PROCEDURE;

