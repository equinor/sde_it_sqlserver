CREATE_PROCEDURE(SCHEMA.table_add_comment) (@lSchema nvarchar(120)
   ,@lTable nvarchar(120)
   ,@lComment nvarchar(500)
   )
  --with execute as { CALLER | SELF | OWNER | 'user_name' } 
as
/*****************************************************************
* Procedure Info
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 2025.09.30 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: GITHUB $
* Description     :  $
* Revision History: $Revision: 1.1 $
* Workfile        : $Workfile: $
* Copyright       : Equinor ASA  $Date:  2025.09.30 $
*****************************************************************
* Description
* https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-addextendedproperty-transact-sql?view=sql-server-ver17
*
*select 
*    name as propertyname
*    ,value as propertyvalue
*    ,class_desc as objecttype
*    ,object_name(major_id) as objectname
*    ,minor_id as columnorparameterid
*  from 
*    sys.extended_properties;
*****************************************************************
* Log
* Date   Description                                        Done by
*
*****************************************************************/
  STANDARD_VARIABLE;
  declare @lStr nvarchar(300);
BEGIN_EXCEPTION
   set @lStr =  N'Comment: '+@lTable;
   exec sp_addextendedproperty 
        @name  = @lStr
       ,@value = @lComment 
       ,@level0type = N'schema' 
       ,@level0name = @lSchema 
       ,@level1type = N'table' 
       ,@level1name = @lTable
EXCEPTION
   STD_EXCEPTION_HANDLER;
END_EXCEPTION;
