divert(-1)
# Cannot resolve the collation conflict between "COLLATION_DB_DEFAULT" and "Latin1_General_CI_AS_KS_WS" in the EXCEPT operation

define(VALID_SPATIL_OBJECT,<&>'FEATURE CLASS'<%>) -- If empty, use '' as a value must be present.
define(VALID_OBJECT,<&>'VIEW','SQL_STORED_PROCEDURE','SYNONYM','USER_TABLE','SQL_TRIGGER','SQL_SCALAR_FUNCTION',VALID_SPATIL_OBJECT<%>)

#---------------------------------------------------------------------------------
# Schema must be present in rbac_object.
# Parameter: 
# 1) Name of table containing the spatial data table for the schema in question.
# 2) Schema name
# 3) Schema st_id
# When filling the table with spatial objects, use a "left join" with v_rbac_object.
# This because for first run, there may be no objects loaded in rbac_object.
#---------------------------------------------------------------------------------
define(POPULATE_SPATIAL_TABLE,<&>
-------------------------------------------------------------------------------------
-- When filling the table with spatial objects, use a "left join" with v_rbac_object.
-- This because for first run, there may be no objects loaded in rbac_object.
-------------------------------------------------------------------------------------
      with xres as (
         select upper(gt.name) as spatial_type
               ,gi.name
               ,gi.PhysicalName
               ,FRAMEWORK_SCHEMA.instr_func(gi.PhysicalName,'.',default,default) as schema_pos
               ,FRAMEWORK_SCHEMA.instr_func(REVERSE(gi.PhysicalName ),'.',default,default ) as object_pos
               ,reverse(gi.PhysicalName) as reversed_PhysicalName
            from sde.gdb_items gi inner join sde.gdb_itemtypes gt on gt.uuid=gi.type
            where upper(gt.name) in ('FEATURE CLASS','FEATURE DATASET')
         )
         ,xdata as (select x.spatial_type as spatial_type
               ,lp.data_type
               ,case when x.schema_pos > 0 then
                  substring(x.PhysicalName,1,x.schema_pos - 1) -- Note: Starting at "1" is important
                else
                  null 
                end as schema_name
               ,reverse(case when x.object_pos > 0 then
                   -- Note: Starting at "1" is important.
                     substring(x.reversed_PhysicalName,1,x.object_pos - 1)
                  else
                     x.reversed_PhysicalName
                  end
               )  as object_name
            from xres x
            inner join FRAMEWORK_SCHEMA.rbac_legal_permission lp
              on lp.is_spatial = TRUE_CHAR
              and STR_EQUAL_CASE_INSENSITIVE(lower(lp.data_type),lower(x.spatial_type) )
             -- and lp.is_active = TRUE_CHAR
      )
      insert into $1 (schema_name,object_name,object_type,spatial_type,schema_st_id)
      select x.schema_name
            ,x.object_name
            ,ob.xtype as object_type
            ,x.spatial_type
            ,$3 as schema_st_id
         from xdata x
         left join FRAMEWORK_SCHEMA.v_rbac_object ob
            on x.schema_name is not null and x.schema_name = $2
            and x.object_name = ob.name
         where x.schema_name= $2;<%>)

define(GET_SCHEMA,<&>xsch as (select rbac_database_st_id
            ,st_id as schema_st_id
            ,name as schema_name
         from SCHEMA.rbac_object ob 
         where st_id = @lSchema_st_id
         -- and rbac_database_st_id = @lDB_st_id  -- unneccesary as schema st_id is unique
      )<%>)

#---------------------------------------------------------------------------------
# Retriving data from sys.objects requires the translation of spatial object types.
# Parameter: 
# 1) Name of table containing the spatial data table for the schema in question.
# 2) Schema name
# NOTE: Change xtype to correct spatial value where applicable
#---------------------------------------------------------------------------------
define(DATABASE_SET,<&>select schema_name(ob.schema_id) COLLATION_DB_DEFAULT as schema_name
            ,object_name(ob.object_id) COLLATION_DB_DEFAULT as object_name
            ,coalesce(sp.spatial_type,ob.type_desc COLLATION_DB_DEFAULT) as xtype
            --,sp.spatial_type,ob.type_desc COLLATION_DB_DEFAULT as obj_type
         from sys.objects ob
         left join $1 sp
            on STR_EQUAL_CASE_INSENSITIVE(lower(object_name(ob.object_id)), lower(sp.object_name) )
         where ob.is_ms_shipped != 1 
         and STR_EQUAL_CASE_INSENSITIVE(schema_name(ob.schema_id),$2)
         and ob.type_desc COLLATION_DB_DEFAULT in (VALID_OBJECT)
         --and STR_NOTEQUAL_CASE_INSENSITIVE(schema_name(ob.schema_id),'sys')<%>)

#---------------------------------------------------------------------------------
# NOTE: Engaging the spatial data allows for datatype change. 
#   This could be considered a mistake, please think about the consequences.
# Parameter: 
# 1) Name of table containing the spatial data table for the schema in question.
# NOTE: Change xtype to correct spatial value where applicable
#---------------------------------------------------------------------------------
define(REGISTERED_SET,<&>select xsch.schema_name
            ,ob.name as object_name
            ,ob.xtype
           -- ,coalesce(sp.spatial_type,ob.xtype) as xtype
         from SCHEMA.rbac_object ob
         inner join xsch
            on ob.rbac_database_st_id=xsch.rbac_database_st_id
            and ob.parent_st_id=xsch.schema_st_id
         left join $1 sp
            on STR_EQUAL_CASE_INSENSITIVE(lower(name),lower(sp.object_name))<%>)

define(EQ_INACTIVE_SET,<&>select xsch.schema_name
            ,ob.name COLLATION_DB_DEFAULT  as object_name
            ,upper(ob.xtype) COLLATION_DB_DEFAULT as xtype
         from SCHEMA.rbac_object ob
         inner join xsch
            on ob.rbac_database_st_id=xsch.rbac_database_st_id
            and ob.parent_st_id=xsch.schema_st_id
            and STR_EQUAL_CASE_INSENSITIVE(ob.is_active,FALSE_CHAR)<%>)
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
* TBD: There are two object sources.
*  1) the Informationschema
*  2) the SDE
*  Handling an objects datatype requires checking both and should
*  e.g. the object in question below to case 1 and is a table or view,
*  one has to check the SDE (case 2) to see if it is a 'feature class'.
*  If it is a "feature class" this takes precedence over case 1.
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
         ,@lAll_Targets nvarchar(100) = 'ALL'  -- constant
         ,@lCount integer = 0;

   ------------------------------------------------------------------------------
   -- Due to collation differences, casting "sys" collation to "geox" collation
   -- Precaution: setting @lTarget to uppercase as this matches master values.
   -- If lTarget_type is null, reassign it to 'ALL'. Do not allow it to be 'null'.
   ------------------------------------------------------------------------------
      set @lDatabase_name = trim(@lDatabase_name) COLLATION_DB_DEFAULT;
      set @lSchema_name   = trim(@lSchema_name) COLLATION_DB_DEFAULT;
      set @lTarget_type   = trim(upper(coalesce(@lTarget_type,@lAll_Targets))) COLLATION_DB_DEFAULT;

DEBUG_START
      if (@lTarget_type = @lAll_Targets)
      begin
         DEBUG(N'Targeting: all object types.');
      end
      else
      begin
         DEBUG(N'Targeting: '+@lTarget_type + '.');
      end;
DEBUG_END

   -- Recommended
   set nocount on;
   -------------------------------------------------------------
   -- Check database and schema valid
   -- Ensure items of interest are active?
   -------------------------------------------------------------
   select @lDB_st_id=st_id
      from SCHEMA.rbac_database
      where name = @lDatabase_name;
     
   if @lDB_st_id is null
   begin
      USERERROR(12,'database name '+@lDatabase_name);
   end;

   select @lSchema_st_id=st_id
      from SCHEMA.rbac_object
      where rbac_database_st_id = @lDB_st_id
      and name = @lSchema_name
      and xtype ='schema';
      
   if @lSchema_st_id is null
   begin
      USERERROR(12,'schema name '+@lSchema_name);
   end;  
DEBUG_START 
   DEBUG(N' @lDB_st_id is  '+ cast(@lDB_st_id as nvarchar(10)));
   DEBUG('@lSchema_name '+ @lSchema_name+'.');   
   DEBUG(N' @lSchema_st_id is  '+ cast(@lSchema_st_id as nvarchar(10)));
   
   DEBUG('@lTarget_type ' +  coalesce(@lTarget_type,@lAll_Targets) +'.');
DEBUG_END
   -------------------------------------------------------------
   -- Preload Feature Classes
   -------------------------------------------------------------
   declare @lTabSpatial table (
       schema_name nvarchar(100)
      ,object_name nvarchar(250)
      ,spatial_type nvarchar(100)
      ,object_type nvarchar(100)
      ,schema_st_id integer
      );

   POPULATE_SPATIAL_TABLE(@lTabSpatial, @lSchema_name,@lSchema_st_id);
   DEBUG('Identified spatial feature classes: ' + cast(GET_ROWCOUNT as nvarchar(10)) +'.');   
DEBUG_START
   DEBUG('Listing @lTabSpatial.');
   select * from @lTabSpatial;
DEBUG_END;
   
   BEGIN_EXCEPTION
      -------------------------------------------------------------
      -- Maintain object listing.
      -- First the addtions, thereafter those exiting.
      -------------------------------------------------------------
      BEGIN_TRANSACTION
         set @lCount = 0;
         
         -------------------------------------------------------
         -- Ensuring spatial objects have correct datatype. Feature classes only
         -------------------------------------------------------
         DEBUG('Checking for spatial objects. Feature classes only.');
         merge into FRAMEWORK_SCHEMA.rbac_object ob
            using (select ob.name, sp.object_name
                  ,ob.xtype ,sp.spatial_type
                  ,ob.st_id rbac_object_st_id
               from FRAMEWORK_SCHEMA.v_rbac_object ob
               inner join @lTabSpatial sp
                  on ob.name = sp.object_name
                  and STR_NOTEQUAL_CASE_INSENSITIVE(ob.xtype,sp.spatial_type)
            ) xdata
            on (ob.st_id = xdata.rbac_object_st_id)
            when matched then update set xtype = xdata.spatial_type;
            
         -------------------------------------------------------
         -- Start loading data.
         -------------------------------------------------------
         DEBUG('Inserting new additions bulk wise.');
         with GET_SCHEMA
            ,xdata as (DATABASE_SET(@lTabSpatial, @lSchema_name)
            except
            REGISTERED_SET(@lTabSpatial)
            )
         insert into SCHEMA.rbac_object (rbac_database_st_id,parent_st_id,name,xtype,is_active)
            select @lDB_st_id,@lSchema_st_id,object_name,xtype,TRUE_CHAR
               from xdata xd
               where ((@lTarget_type = @lAll_Targets and xd.xtype COLLATION_DB_DEFAULT in (VALID_OBJECT) )
                     or STR_EQUAL_COLLATION_DB_DEFAULT(xd.xtype,@lTarget_type)
                     );              ;
         DEBUG('Inserted new additions : '+cast(GET_ROWCOUNT as nvarchar(10))+'.');
         set @lCount = @lCount + GET_ROWCOUNT;
DEBUG_START
   if 1=2
   begin
      declare @zlCnt integer = 0;
      select @zlCnt = count(*) 
         from FRAMEWORK_SCHEMA.v_rbac_object
         where schema_name = @lSchema_name
         and xtype = 'FEATURE CLASS';
      DEBUG('Inserted "FEATURE CLASS": '+cast(@zlCnt as nvarchar)+'.');
      DEBUG('Danger: Committing and returning');       
      while @@trancount > 0 commit;
      return;   
   end;
DEBUG_END  ;

 
         DEBUG('Updating reactivation bulk wise.');
         with GET_SCHEMA
            ,xdata as (EQ_INACTIVE_SET
               intersect
               DATABASE_SET(@lTabSpatial, @lSchema_name)
            )
         merge SCHEMA.rbac_object ob
            using xdata as xd
            on (STR_EQUAL_COLLATION_DB_DEFAULT(ob.name,xd.object_name)
               and STR_EQUAL_COLLATION_DB_DEFAULT(ob.xtype,xd.xtype)
               and ob.parent_st_id = @lSchema_st_id
               and ((@lTarget_type = @lAll_Targets and ob.xtype COLLATION_DB_DEFAULT in (VALID_OBJECT) )
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
            ,xdata as (REGISTERED_SET(@lTabSpatial)
               except
               DATABASE_SET(@lTabSpatial, @lSchema_name)
            )
         merge SCHEMA.rbac_object ob
            using xdata as xd
            on (STR_EQUAL_COLLATION_DB_DEFAULT(ob.name,xd.object_name)
               and STR_EQUAL_COLLATION_DB_DEFAULT(ob.xtype,xd.xtype)
               and ob.parent_st_id = @lSchema_st_id
               and ((@lTarget_type = @lAll_Targets and ob.xtype COLLATION_DB_DEFAULT in (VALID_OBJECT) )
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



/*
-----------------   Dead code ----------------------
  declare cur_addtional_diff cursor local
   for  with GET_SCHEMA
      ,xdata as (DATABASE_SET
         except
         R EGISTERED_SET
      )
      select * from xdata
         where xtype COLLATION_DB_DEFAULT = @lTarget_type COLLATION_DB_DEFAULT;
---------------------------------------------------------
--         (@lTarget_type is null and xtype COLLATION_DB_DEFAULT in (VALID_OBJECT)
--               )
--         or STR_EQUAL_CASE_INSENSITIVE(xtype,@lTarget_type);
--         --or xtype = @lTarget_type;
---------------------------------------------------------
         
   declare cur_exiting_diff cursor local
   for with GET_SCHEMA
      ,xdata as (R EGISTERED_SET
         except
         D ATABASE_SET
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
         E Q_SET_INACTIVE
      )
      select * from xdata
         where (@lTarget_type is null and xtype COLLATION_DB_DEFAULT in (VALID_OBJECT)
               )
         or STR_EQUAL_CASE_INSENSITIVE(xtype,@lTarget_type);
         --or xtype =@lTarget_type;
--========================================================         
         
         with xres as (
            select upper(gt.name) as spatial_type
                  ,gi.name
                  ,gi.PhysicalName
                  ,sde_it.instr_func(gi.PhysicalName,'.',default,default) as schema_pos
                  ,sde_it.instr_func(REVERSE(gi.PhysicalName ),'.',default,default ) as object_pos
                  ,reverse(gi.PhysicalName) as reversed_PhysicalName
               from sde.gdb_items gi 
               inner join sde.gdb_itemtypes gt 
                  on gt.uuid=gi.type
               where upper(gt.name) in ('FEATURE CLASS','FEATURE DATASET')
            )
            ,xdata as (select x.spatial_type as spatial_type
                  ,lp.data_type
                  ,case when x.schema_pos > 0 then
                     substring(x.PhysicalName,1,x.schema_pos - 1) -- Note: Starting at "1" is important
                   else
                     null 
                   end as schema_name
                  ,reverse(case when x.object_pos > 0 then
                      -- Note: Starting at "1" is 
                        substring(x.reversed_PhysicalName,1,x.object_pos - 1)
                     else
                        x.reversed_PhysicalName
                     end
                  )  as object_name
               from xres x
               inner join sde_it.rbac_legal_permission lp
                 on lp.is_spatial = TRUE_CHAR
                 and STR_EQUAL_COLLATION_DB_DEFAULT(lower(lp.data_type),lower(x.spatial_type))
                -- and lp.is_active = TRUE_CHAR
         )
         ,xd as (select x.schema_name
                  ,x.object_name
                  ,x.spatial_type
                  ,ob.xtype as object_type
                  ,ob.schema_st_id
               from xdata x
               inner join sde_it.v_rbac_object ob
                  on x.schema_name is not null and x.schema_name='sde_adm'
                  and x.object_name = ob.name
                  and STR_EQUAL_COLLATION_DB_DEFAULT(x.spatial_type,'FEATURE CLASS')
                  and ob.xtype  COLLATION_DB_DEFAULT in ('USER_TABLE','VIEW')
         )
         merge into sde_it.rbac_object_org rb
            using (select * from xd) xx
            --select * from xd 
            on  (rb.parent_st_id =  xx.schema_st_id
            and rb.name  = xx.object_name
            )
         when matched then update set xtype = 'FEATURE CLASS' COLLATION_DB_DEFAULT;
               
         
*/         