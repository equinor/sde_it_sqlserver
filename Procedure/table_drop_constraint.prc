CREATE_PROCEDURE(SCHEMA.table_drop_constraint)(lSchema nvarchar(120),lTable nvarchar(120))
  --with execute as { CALLER | SELF | OWNER | 'user_name' } 
as
/*****************************************************************
* Procedure Info
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 27.08.2025 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: GITHUB $
* Description     :  $
* Revision History: $Revision: 1.1 $
* Workfile        : $Workfile: $
* Copyright       : Equinor ASA
*****************************************************************
* Description
* When dropping a table it may be necessary to drop associate contraints.
* Prior to dropping a table all constraints must be dropped.
*   https://www.mssqltips.com/sqlservertip/6769/sql-server-drop-table-if-exists/
*
* Code to list constraints:
*  select OBJECT_SCHEMA_NAME(schema_ID)
*    ,QUOTENAME(OBJECT_NAME(parent_object_id))
*	  ,x.* 
*	from sys.foreign_keys x;
* 	--where OBJECT_SCHEMA_NAME(schema_ID) = 'sys';
* Another recipe:
* In SQL Server, there is no direct CASCADE option for the DROP TABLE statement like in some other database systems. However, you can achieve similar functionality by manually removing dependent objects (e.g., constraints, foreign keys) before dropping the table. 
* Here's how you can do it:
* 
* 1. Alternative: Use a Script to Automate. Supply schema and table_name
* 2. Drop Table If Exists
*   To drop a table if it exists, you can use the following syntax:
*    IF OBJECT_ID('YourTableName', 'U') IS NOT NULL
*     DROP TABLE YourTableName;
* 3. Drop Table with Dependencies
*   If the table has dependencies (e.g., foreign key constraints), you need to drop those first. Here's an example:
*   -- Drop foreign key constraints
*   DECLARE @sql NVARCHAR(MAX) = '';
*   SELECT @sql += 'ALTER TABLE ' + QUOTENAME(OBJECT_NAME(parent_object_id)) +
*                ' DROP CONSTRAINT ' + QUOTENAME(name) + '; '
*   FROM sys.foreign_keys
*   WHERE referenced_object_id = OBJECT_ID('YourTableName');
* 
*   EXEC sp_executesql @sql;
* 4. Drop the table
* 4.1IF OBJECT_ID('YourTableName', 'U') IS NOT NULL
*     DROP TABLE [YourTableName];
* 342 DROP TABLE IF EXISTS [YourTableName];
* 
* If you frequently need to drop tables with dependencies, you can write a stored procedure or script to automate the process of identifying and removing constraints before dropping the table.
* This approach ensures that all related constraints are removed before the table is dropped, mimicking a "cascade" behavior.
*
*****************************************************************
* Log
* Date   Description					 Done by
*
*****************************************************************/
  STANDARD_VARIABLE;
BEGIN_EXCEPTION
   print('Work in progress on developing code.');
EXCEPTION
   STD_EXCEPTION_HANDLER;
END_CREATE_PROCEDURE;
