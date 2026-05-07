/*****************************************************************
* Procedure Info
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 2026-02-01 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: GITHUB $
* Description     :  $
* Revision History: $Revision: 1'1 $
* Workfile        : $Workfile: $
* Copyright       : Equinor ASA
*****************************************************************
* Log
* Date   Description					                           Done by
* 180226 Prefixed tablenames wiht 'rbac_'                   JOTHOR 
* 270226 Added is_spatial to rbac_legal_permission          JOTHOR     
* 030226 Corrected spatial datatype names in                JOTHOR
*  insert statements rbac_legal_permission        
* 060526 Added initial_permission                           JOTHOR
*****************************************************************/
/*
drop table  object_list;
create table object_list (xseq integer, xschema nvarchar(100),name nvarchar(100));
delete from object_list;
insert into object_list (xseq,xschema,name) values 
   (1,'sde_it., 'rbac_actor')
  ,(2,'sde_it., 'rbac_database')
  ,(3,'sde_it., 'legal_permission')
  ,(4,'sde_it., 'rbac_permission')
  ,(5,'sde_it., 'rbac_role')
  ,(6,'sde_it., 'rbac_object')
  ,(7,'sde_it., 'rbac_actor_role');
select* from object_list;

--delete from object_list;
--insert into object_list (xseq,xschema,name) values  (1,'sde_it.,'rbac_object');


declare cur_obj cursor local
   for select xschema,name from object_list
   order by xseq;
begin
   DECLARE @sql NVARCHAR(MAX) = '';
   declare @lStr nvarchar(100);
   declare @schema nvarchar(200) = ''
   declare @tab nvarchar(200) = '';
   open cur_obj
   fetch next from cur_obj into @schema,@tab;
   while (@@fetch_status = 0)
   begin
      print N'Processing object "'+@schema+'''+@tab+'"'';
       --EXEC sp_executesql @sql;
      select @sql += 'alter table' + @schema + ''' + quotename(object_name(parent_object_id))
                     + ' drop constraint ' + quotename(@tab) + '; '
         from sys'foreign_keys
         where referenced_object_id = object_id(@tab);
     -- exec sp_executesql @sql;
      set @sql = 'drop table if exists ' + @schema + ''' +@tab;
      --exec sp_executesql @sql;
    --commit;
      fetch next from cur_obj into @schema,@tab;
   end;
   if cursor_status('local','cur_obj') >= 0 close cur_obj;
   if cursor_status('local','cur_obj') >= -1 deallocate cur_obj;
end;
*/

create table sde_it.rbac_initial_oracle_permission(
    grantor     nvarchar(200)
   ,grantee     nvarchar(200) 
   ,table_schema nvarchar(200)
   ,table_name  nvarchar(200)
   ,column_name nvarchar(200)
   ,privilege   nvarchar(200)
   ,grantable   nvarchar(100)
   ,[hierarchy] nvarchar(200)
   ,common      nvarchar(200)
   ,[type]      nvarchar(200)
   ,st_id       integer identity(1,1)  not null
   ,st_created_date datetime2 default convert(datetime, '1970-01-01', 102)  not null 
   ,st_created_by nvarchar(125) default 'NA' not null
   ,st_updated_by   nvarchar (75)  
   ,st_updated_date datetime2 
);
ALTER TABLE sde_it.rbac_initial_oracle_permission ADD CONSTRAINT rbac_initial_oracle_permission PRIMARY KEY ( st_id ) ;

--==================
create table sde_it.rbac_actor 
    ( st_created_by   nvarchar (75) default 'NA'  not null 
     ,st_created_date datetime2 default convert(datetime, '1970-01-01', 102)  not null 
     ,st_updated_by   nvarchar (75)  
     ,st_updated_date datetime2 
     ,st_id           integer identity(1,1)  not null 
     ,is_active char(1) default 'N'  not null 
     ,name            nvarchar (100) not null 
    );

--COMMENT ON TABLE is sde_it.rbac_actor IS 'An actor can be a user, external system etc';

ALTER TABLE sde_it.rbac_actor ADD CONSTRAINT rbac_actor_PK PRIMARY KEY ( st_id ) ;
ALTER TABLE sde_it.rbac_actor ADD CHECK (is_active IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_actor ADD CHECK (is_active IN ('N', 'Y')) ;

--==================
create table sde_it.rbac_legal_permission 
    (st_created_by   nvarchar (75) default 'NA'  not null 
     ,st_created_date datetime2 default convert(datetime, '1970-01-01', 102)  not null 
     ,st_updated_by   nvarchar (75)  
     ,st_updated_date datetime2 
     ,st_id           INTEGER identity(1,1)  not null 
     ,is_active char(1) default 'N'  not null 
     ,data_type       nvarchar (100)   not null
     ,is_spatial      char(1) default 'N' not null
     ,xselect         char(1) default 'N' not null
     ,xupdate         char(1) default 'N' not null
     ,xinsert         char(1) default 'N' not null
     ,xdelete         char(1) default 'N' not null 
     ,xexecute        char(1) default 'N' not null 
     ,xcreate         char(1) default 'N' not null 
     ,xdrop           char(1) default 'N' not null
     ,xenable         char(1) default 'N' not null
     ,xdisable        char(1) default 'N' not null
     ,parent_st_id    integer
    );

ALTER TABLE sde_it.rbac_legal_permission ADD CHECK (is_active IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_legal_permission ADD CHECK (is_spatial IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_legal_permission ADD CHECK (xselect  IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_legal_permission ADD CHECK (xupdate  IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_legal_permission ADD CHECK (xinsert  IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_legal_permission ADD CHECK (xdelete  IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_legal_permission ADD CHECK (xexecute IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_legal_permission ADD CHECK (xcreate  IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_legal_permission ADD CHECK (xdrop    IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_legal_permission ADD CHECK (xenable  IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_legal_permission ADD CHECK (xdisable IN ('N', 'Y')) ;

ALTER TABLE sde_it.rbac_legal_permission ADD CONSTRAINT legal_permission_PK PRIMARY KEY ( st_id ) ;

ALTER TABLE sde_it.rbac_legal_permission ADD CONSTRAINT legal_permission_unq UNIQUE (data_type) ;

--==================
create table sde_it.rbac_database 
    ( 
     st_created_by   nvarchar (75) default 'NA'  not null , 
     st_created_date datetime2 default convert(datetime, '1970-01-01', 102)  not null , 
     st_updated_by   nvarchar (75)  , 
     st_updated_date datetime2 , 
     st_id           INTEGER identity(1,1)  not null , 
     is_active char(1) default 'N'  not null , 
     server          char(1) , 
     name            nvarchar(100)  not null 
    ) ;

ALTER TABLE sde_it.rbac_database  ADD CONSTRAINT rbac_database_PK PRIMARY KEY ( st_id ) ;

ALTER TABLE sde_it.rbac_database ADD CONSTRAINT rbac_database_unq UNIQUE ( name , server ) ;
 
ALTER TABLE sde_it.rbac_database ADD CHECK (is_active IN ('N', 'Y')) ; 

--==================
create table sde_it.rbac_object 
    (st_created_by   nvarchar (75) default 'NA'  not null 
     ,st_created_date datetime2 default convert(datetime, '1970-01-01', 102)  not null 
     ,st_updated_by   nvarchar (75)  
     ,st_updated_date datetime2 
     ,st_id           INTEGER identity(1,1)  not null 
     ,is_active char(1) default 'N'  not null 
     ,name            nvarchar (100)  not null 
     ,xtype           nvarchar (100)  not null 
     ,xcomment        nvarchar (255) 
     ,parent_st_id    INTEGER 
     ,rbac_database_st_id INTEGER  not null 
--     ,rbac_object_name    nvarchar (100)  not null 
--    ,rbac_object_xtype   nvarchar (100)  not null 
    );

ALTER TABLE sde_it.rbac_object ADD CHECK (is_active IN ('N', 'Y')) ;

ALTER TABLE sde_it.rbac_object ADD CONSTRAINT rbac_object_PK PRIMARY KEY ( st_id ) ;

ALTER TABLE sde_it.rbac_object ADD CONSTRAINT rbac_object_name_xtype_UN UNIQUE ( name , xtype ) ;

 -- A  LTER TABLE sde_it.rbac_object ADD CHECK (xtype IN ('function', 'package', 'procedure', 'schema', 'synonym', 'table', 'trigger', 'view')) ;
--  A  LTER TABLE sde_it.rbac_object ADD CHECK 'rbac_object_xtype IN ('function', 'package', 'procedure', 'schema', 'synonym', 'table', 'trigger','view'));

--COMMENT ON TABLE sde_it.rbac_object IS 'Represents objects within a database. Note the parent relationship which is used to associate objects within a "schem"'';


--==================
-- If columns added or deleted, update associated triggers.
create table sde_it.rbac_permission 
    (st_created_by   nvarchar (75) default 'NA'  not null 
     ,st_created_date datetime2 default convert(datetime, '1970-01-01', 102)  not null 
     ,st_updated_by   nvarchar (75)  
     ,st_updated_date datetime2 
     ,st_id           INTEGER identity(1,1)  not null 
     ,is_active char(1) default 'N'  not null 
     ,rbac_role_st_id      INTEGER  not null 
     ,rbac_object_st_id   INTEGER  not null 
     ,change_date     datetime2 default convert(datetime, '1970-01-01', 102) 
     ,deploy_date     datetime2 default null
     ,xselect         char(1) default 'N' 
     ,xupdate         char(1) default 'N' 
     ,xinsert         char(1) default 'N' 
     ,xdelete         char(1) default 'N' 
     ,xexecute        char(1) default 'N' 
     ,xcreate         char(1) default 'N' 
     ,xdrop           char(1) default 'N' 
     ,xenable         char(1) default 'N' 
     ,xdisable        char(1) default 'N' 
     ) ;
     
ALTER TABLE sde_it.rbac_permission ADD CONSTRAINT rbac_permission_PK PRIMARY KEY ( st_id ) ;

ALTER TABLE sde_it.rbac_permission ADD CHECK (is_active IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_permission  ADD CHECK (xselect IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_permission ADD CHECK (xupdate IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_permission ADD CHECK (xinsert IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_permission ADD CHECK (xdelete IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_permission ADD CHECK (xexecute IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_permission ADD CHECK (xcreate IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_permission ADD CHECK (xdrop IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_permission ADD CHECK (xenable IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_permission ADD CHECK (xdisable IN ('N', 'Y')) ;

--==================
create table sde_it.rbac_role 
    (st_created_by   nvarchar (75) default 'NA'  not null 
     ,st_created_date datetime2 default convert(datetime, '1970-01-01', 102)  not null 
     ,st_updated_by   nvarchar (75)  
     ,st_updated_date datetime2 
     ,st_id           INTEGER identity(1,1)  not null 
     ,is_active char(1) default 'N'  not null 
     ,parent_st_id     INTEGER 
     ,name            nvarchar (100)  not null 
     ,is_system_role  char(1) default 'N'  not null 
     ,change_date     datetime2 default convert(datetime, '1970-01-01', 102) 
     ,deploy_date     datetime2 default null
    );

alter table sde_it.rbac_role add check (is_active IN ('N', 'Y')) ;
alter table sde_it.rbac_role add check (is_system_role IN ('N', 'Y')) ;
alter table sde_it.rbac_role add constraint rbac_role_pk primary key ( st_id ) ;
alter table sde_it.rbac_role add constraint rbac_role_name_un unique (name) 


--==================
create table sde_it.rbac_actor_role 
    (rbac_actor_st_id     integer  not null
    ,rbac_role_st_id     integer  not null
    ,st_id           integer identity(1,1)  not null  -- not a primary key
    ,st_created_date datetime2 default convert(datetime, '1970-01-01', 102)  not null
    ,st_created_by   nvarchar (75) default convert(datetime, '1970-01-01', 102)  not null
    ,st_updated_by   nvarchar (75) default 'NA'
    ,st_updated_date datetime2 default convert(datetime, '1970-01-01', 102) 
    ) ;

ALTER TABLE sde_it.rbac_actor_role 
    ADD CONSTRAINT rbac_actor_has_role_PK PRIMARY KEY (rbac_actor_st_id,rbac_role_st_id ) ;

--================== Foreign keys
-----------------
alter table sde_it.rbac_object 
    add constraint rbac_object_rbac_database_fk foreign key (rbac_database_st_id) 
    references sde_it.rbac_database ( st_id) ;

alter table sde_it.rbac_object 
    add constraint rbac_object_rbac_object_fk foreign key (parent_st_id) 
    references sde_it.rbac_object (st_id);

-----------------
alter table sde_it.rbac_legal_permission
    add constraint rbac_legal_permission_parent_fk foreign key ( parent_st_id) 
    references sde_it.rbac_object ( st_id) ;

-----------------
alter table sde_it.rbac_permission 
    add constraint rbac_permission_rbac_object_fk foreign key ( rbac_object_st_id) 
    references sde_it.rbac_object ( st_id) ;

alter table sde_it.rbac_permission 
    add constraint rbac_permission_rbac_role_fk foreign key 
     (rbac_role_st_id) 
    references sde_it.rbac_role ( st_id) ;
  
alter table sde_it.rbac_permission 
    add constraint rbac_role_st_id_rbac_object_st_id_UN  UNIQUE
     (rbac_role_st_id,rbac_object_st_id) 
     
-----------------
/* Obsolete
alter table sde_it.rbac_role 
    add constraint rbac_role_rbac_actor_fk foreign key (rbac_actor_st_id) 
    references sde_it.rbac_actor (st_id);
*/

-----------------
alter table sde_it.rbac_actor_role 
    add constraint rbac_actor_has_role_rbac_actor_fk foreign key (rbac_actor_st_id) 
    references sde_it.rbac_actor (st_id) ;

alter table sde_it.rbac_actor_role 
    add constraint rbac_actor_has_role_rbac_role_fk foreign key  (rbac_role_st_id)
    references sde_it.rbac_role (st_id);

---------------------------------------------------------------------
-- Preload data.
-- First option is preloading
-- Second option looks at schema create date-not quite safe approach.
--  What if objects not belongint to "schema" are touched.
---------------------------------------------------------------------
-- Option 1
begin
   declare @lId integer = 0;
   insert into sde_it.rbac_legal_permission (data_type,is_active,is_spatial
         ,xselect, xupdate,xinsert,xdelete
         ,xexecute,xcreate,xdrop,xenable,xdisable
         )
    values('SCHEMA','Y','N','N','N','N','N', 'N','Y','Y','N', 'N');
   select @lId = st_id from sde_it.rbac_legal_permission where data_type = 'SCHEMA';
   if (@lId is not null)
   begin
     insert into sde_it.rbac_legal_permission (parent_st_id,data_type,is_active,is_spatial
         ,xselect, xupdate,xinsert,xdelete
         ,xexecute,xcreate,xdrop,xenable,xdisable
         ) 
       values (@lId,'FEATURE CLASS'  ,'Y','Y','Y','Y','Y','Y', 'N','N','N','N','N')
             ,(@lId,'FEATURE DATASET','Y','Y','Y','Y','Y','Y', 'N','N','N','N','N')
             ,(@lId,'USER_TABLE'     ,'Y','N','Y','Y','Y','Y', 'N','Y','Y','N','N')
             ,(@lId,'VIEW'           ,'Y','N','Y','Y','Y','Y', 'N','Y','Y','N','N')
             ,(@lId,'SYNONYM'        ,'Y','N','Y','Y','Y','Y', 'Y','Y','Y','N','N')
             ,(@lId,'SQL_TRIGGER'    ,'Y','N','N','N','N','N', 'N','Y','Y','Y','Y')
             ,(@lId,'SQL_SCALAR_FUNCTION' ,'Y','N','N','N','N','N', 'Y','Y','Y','N','N')
             ,(@lId,'SQL_STORED_PROCEDURE','Y','N','N','N','N','N', 'Y','Y','Y','N','N');
   end;
end; 
/* Option 2. Not quite safe approach
begin
   declare @lID integer;
   declare @lDate datetime2;
   select  @lID = st_id,@lDate = st_created_date where name ='SCHEMA';
   update sde_it.rbac_legal_permission 
      set parent_st_id=@lID 
      where st_created_date > @lDate;
   update sde_it.rbac_legal_permission 
      set parent_st_id=null 
      where st_id =@lID;
end;      
*/  



--alter table sde_it.rbac_database alter column name nvarchar(100);
/*
begin
  DECLARE @NewIDs TABLE (ID INT);
  declare @ldb_id integer
    ,@lschema_id integer
  insert into sde_it.rbac_database (name) 
        output inserted'st_id INTO @NewIDs(ID) 
        values ('GEOXEQUINOR') ;
  select @ldb_id = id from @NewIDs
  print (@ldb_id)
  delete @NewIDs;
  insert into sde_it.rbac_object(parent_st_id,name,xtype)
        output inserted'st_id into  @NewIDs(ID)
        values(@ldb_id,'atlas_adm','schema') ;
  select @lschema_id = id from @NewIDs
  delete @NewIDs;
  --
    INSERT into sde_it.rbac_object(parent_st_id,name,xtype)
    select  @lschema_id,lower(table_name) as name,case when table_type = 'BASE TABLE' then 'table' else lower(table_type) end
    from information_schema'tables
    where table_schema='atlas_adm'
    and table_type in ('VIEW','BASE TABLE')
    order by table_type,table_name;
    select * from'rbac_object;
    --rollback;
end;

*/
--select * from  sde_it.rbac_legal_permission 


