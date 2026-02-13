divert(-1)
# Cannot resolve the collation conflict between "COLLATION_DB_DEFAULT" and "Latin1_General_CI_AS_KS_WS" in the EXCEPT operation

define(VALID_OBJECT,<&>'VIEW','SQL_STORED_PROCEDURE','SYNONYM','USER_TABLE','SQL_TRIGGER','SQL_SCALAR_FUNCTION'<%>)

define(GET_SCHEMA,<&>xsch as (select xdatabase_st_id
            ,st_id as schema_st_id
            ,name COLLATION_DB_DEFAULT as schema_name
         from SCHEMA.xobject ob 
         where st_id = @lSchema_st_id
         -- and xdatabase_st_id = @lDB_st_id  -- unneccesary as schema st_id is unique
      )<%>)

define(DATABASE_SET,<&>select cast(schema_name(schema_id) as nvarchar) COLLATION_DB_DEFAULT as schema_name
            ,cast(object_name(object_id) as nvarchar) COLLATION_DB_DEFAULT as object_name
            ,type_desc COLLATION_DB_DEFAULT as xtype
         from sys.objects 
         where is_ms_shipped != 1 
         and STR_EQUAL_CASE_INSENSITIVE(schema_name(schema_id),@lSchema_name)
         and type_desc COLLATION_DB_DEFAULT in (VALID_OBJECT)
         --and STR_NOTEQUAL_CASE_INSENSITIVE(schema_name(schema_id),'sys')<%>)

define(REGISTERED_SET,<&>select xsch.schema_name COLLATION_DB_DEFAULT as schema_name
            ,ob.name COLLATION_DB_DEFAULT as object_name
            ,upper(ob.xtype) COLLATION_DB_DEFAULT as xtype
         from sde_it.xobject ob
             ,xsch
         where ob.xdatabase_st_id=xsch.xdatabase_st_id
         and ob.parent_st_id=xsch.schema_st_id<%>)

define(EQ_SET_INACTIVE,<&>select xsch.schema_name COLLATION_DB_DEFAULT as schema_name
            ,ob.name COLLATION_DB_DEFAULT  as object_name
            ,upper(ob.xtype) COLLATION_DB_DEFAULT as xtype
         from sde_it.xobject ob
             ,xsch
         where ob.xdatabase_st_id=xsch.xdatabase_st_id
         and ob.parent_st_id=xsch.schema_st_id
         and ob.is_active COLLATION_DB_DEFAULT = FALSE_CHAR<%>)
divert

CREATE_PROCEDURE(SCHEMA.rbac_load_objects) (@lDatabase_name nvarchar(100)
   ,@lSchema_name nvarchar(100)
   ,@lTarget_type nvarchar(100) = null
   )
--with execute ???
--with execute as owner
as
/*****************************************************************
*  Procedure Info
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: 2026-02-04 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: 1.0 $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
*
*
*****************************************************************
* Log
* Date   Description					                           Done by
*
*****************************************************************/
begin
   STANDARD_VARIABLE;
   declare @lStr nvarchar(100) = null 
         ,@lDB_st_id integer = null
         ,@lSchema_st_id integer = null
         ,@lObject_st_id integer = null
         ,@lObject_name nvarchar(100) = null
         ,@lObject_type nvarchar(100) = null
         ,@lCount integer = 0;

   ---------------------------------------------------------------------
   -- Due to collation differences, casting "sys" collation to "geox" collation
   -- Precaution: setting @lTarget to uppercase as this matches master values.
   ---------------------------------------------------------------------
      set @lDatabase_name = trim(@lDatabase_name) COLLATION_DB_DEFAULT;
      set @lSchema_name   = trim(@lSchema_name) COLLATION_DB_DEFAULT;
      set @lTarget_type   = trim(upper(@lTarget_type)) COLLATION_DB_DEFAULT;

DEBUG_START
      if (@lTarget_type is null)
      begin
         DEBUG(N'Targeting: all object types.');
      end
      else
      begin
         DEBUG(N'Targeting: '+@lTarget_type + '.');
      end;
DEBUG_END

   declare cur_addtional_diff cursor local
   for  with GET_SCHEMA
      ,xdata as (DATABASE_SET
         except
         REGISTERED_SET
      )
      select * from xdata
         where xtype COLLATION_DB_DEFAULT = @lTarget_type COLLATION_DB_DEFAULT;
/*         
         (@lTarget_type is null and xtype COLLATION_DB_DEFAULT in (VALID_OBJECT)
               )
         or STR_EQUAL_CASE_INSENSITIVE(xtype,@lTarget_type);
         --or xtype = @lTarget_type;
*/
         
   declare cur_exiting_diff cursor local
   for with GET_SCHEMA
      ,xdata as (REGISTERED_SET
         except
         DATABASE_SET
      )
      select * from xdata
         where STR_EQUAL_CASE_INSENSITIVE(xtype,@lTarget_type);
--(@lTarget_type is null and xtype COLLATION_DB_DEFAULT in (VALID_OBJECT)) or         
    
   ---------------------------------------------------
   -- Reactivating object
   ---------------------------------------------------
   declare cur_reborn_diff cursor local
   for with GET_SCHEMA
      ,xdata as (DATABASE_SET
         intersect
         EQ_SET_INACTIVE
      )
      select * from xdata
         where (@lTarget_type is null and xtype COLLATION_DB_DEFAULT in (VALID_OBJECT)
               )
         or STR_EQUAL_CASE_INSENSITIVE(xtype,@lTarget_type);
         --or xtype =@lTarget_type;
         
   -- Recommended
   set nocount on;
   -------------------------------------------------------------
   -- Check database and schema valid
   -- Ensure items of interest are active?
   -------------------------------------------------------------
   select @lDB_st_id=st_id
      from SCHEMA.xdatabase
      where name = @lDatabase_name;
     
   if @lDB_st_id is null
   begin
      USERERROR(12,'database name '+@lDatabase_name)
   end;

   select @lSchema_st_id=st_id
      from SCHEMA.xobject
      where xdatabase_st_id = @lDB_st_id
      and name = @lSchema_name
      and xtype ='schema';
      
   if @lSchema_st_id is null
   begin
      USERERROR(12,'schema name '+@lSchema_name)
   end;  
DEBUG_START   
   DEBUG(N' @lDB_st_id is  '+ cast(@lDB_st_id as nvarchar(10)));
   DEBUG('@lSchema_name '+ @lSchema_name+'.');   
   DEBUG(N' @lSchema_st_id is  '+ cast(@lSchema_st_id as nvarchar(10)));
   DEBUG('@lTarget_type ' +  @lTarget_type +'.');
DEBUG_END

   BEGIN_EXCEPTION
      -------------------------------------------------------------
      -- Maintain object listing.
      -- First the addtions, thereafter those exiting.
      -------------------------------------------------------------
      BEGIN_TRANSACTION
         set @lCount = 0;

         DEBUG('Inserting new additions bulk wise.');
         with GET_SCHEMA
            ,xdata as (DATABASE_SET
               except
               REGISTERED_SET
            )
         insert into sde_it.xobject (xdatabase_st_id,parent_st_id,name,xtype,is_active)
            select @lDB_st_id,@lSchema_st_id,object_name,xtype,TRUE_CHAR
               from xdata xd
               where ((@lTarget_type is null and xd.xtype COLLATION_DB_DEFAULT in (VALID_OBJECT) )
                     or STR_EQUAL_COLLATION_DB_DEFAULT(xd.xtype,@lTarget_type)
                     );              ;
         DEBUG('Inserted new additions : '+cast(GET_ROWCOUNT as nvarchar(10))+'.');
         set @lCount = @lCount + GET_ROWCOUNT;
         
         DEBUG('Updating reactivation bulk wise.');
         with GET_SCHEMA
            ,xdata as (EQ_SET_INACTIVE
               intersect
               DATABASE_SET
            )
         merge sde_it.xobject ob
            using xdata as xd
            on (STR_EQUAL_COLLATION_DB_DEFAULT(ob.name,xd.object_name)
               and STR_EQUAL_COLLATION_DB_DEFAULT(ob.xtype,xd.xtype)
               and ob.parent_st_id = @lSchema_st_id
               and ((@lTarget_type is null and ob.xtype COLLATION_DB_DEFAULT in (VALID_OBJECT) )
                     or STR_EQUAL_COLLATION_DB_DEFAULT(ob.xtype,@lTarget_type)
                   )
               )
            when matched then update
                set is_active = TRUE_CHAR
               ,xcomment = 'Reactivated';
         DEBUG('Updated reactivated objects : '+cast(GET_ROWCOUNT as nvarchar(10))+'.');
         set @lCount = @lCount + GET_ROWCOUNT;               
            
         DEBUG('Updating exiting bulk wise.');
         with GET_SCHEMA
            ,xdata as (REGISTERED_SET
               except
               DATABASE_SET
            )
         merge sde_it.xobject ob
            using xdata as xd
            on (STR_EQUAL_COLLATION_DB_DEFAULT(ob.name,xd.object_name)
               and STR_EQUAL_COLLATION_DB_DEFAULT(ob.xtype,xd.xtype)
               and ob.parent_st_id = @lSchema_st_id
               and ((@lTarget_type is null and ob.xtype COLLATION_DB_DEFAULT in (VALID_OBJECT) )
                     or STR_EQUAL_COLLATION_DB_DEFAULT(ob.xtype,@lTarget_type)
                   )
               )
            when matched then update
                set is_active = FALSE_CHAR
               ,xcomment = 'Deleted';
 
         DEBUG('Updated deleted objects : '+cast(GET_ROWCOUNT as nvarchar(10))+'.');
         set @lCount = @lCount + GET_ROWCOUNT; 

         DEBUG('Exiting transaction sequence.');         
      END_TRANSACTION;
      
      DEBUG('Total nr of modifications: '+cast(@lCount as nvarchar(10))+'.');
   EXCEPTION
      STD_EXCEPTION_HANDLER;
   END_EXCEPTION;  
END_CREATE_PROCEDURE;
