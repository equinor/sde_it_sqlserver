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
*           
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


--==================
CREATE TABLE sde_it.rbac_actor 
    ( st_created_by   nvarchar (75) DEFAULT 'NA'  NOT NULL 
     ,st_created_date datetime2 DEFAULT convert(datetime, '1970-01-01', 102)  NOT NULL 
     ,st_updated_by   nvarchar (75)  
     ,st_updated_date datetime2 
     ,st_id           INTEGER identity(1,1)  NOT NULL 
     ,is_active char(1) DEFAULT 'N'  NOT NULL 
    );

--COMMENT ON TABLE is sde_it.rbac_actor IS 'An actor can be a user, external system etc';

ALTER TABLE sde_it.rbac_actor ADD CONSTRAINT rbac_actor_PK PRIMARY KEY ( st_id ) ;
ALTER TABLE sde_it.rbac_actor ADD CHECK (is_active IN ('N', 'Y')) ;
ALTER TABLE sde_it.rbac_actor ADD CHECK (is_active IN ('N', 'Y')) ;

--==================
CREATE TABLE sde_it.rbac_legal_permission 
    (st_created_by   nvarchar (75) DEFAULT 'NA'  NOT NULL 
     ,st_created_date datetime2 DEFAULT convert(datetime, '1970-01-01', 102)  NOT NULL 
     ,st_updated_by   nvarchar (75)  
     ,st_updated_date datetime2 
     ,st_id           INTEGER identity(1,1)  NOT NULL 
     ,is_active char(1) DEFAULT 'N'  NOT NULL 
     ,data_type       nvarchar (100) 
     ,xselect         char(1) DEFAULT 'N' 
     ,xupdate         char(1) DEFAULT 'N' 
     ,xinsert         char(1) DEFAULT 'N' 
     ,xdelete         char(1) DEFAULT 'N' 
     ,xexecute        char(1) DEFAULT 'N' 
     ,xcreate         char(1) DEFAULT 'N' 
     ,xdrop           char(1) DEFAULT 'N' 
     ,xenable         char(1) DEFAULT 'N' 
     ,xdisable        char(1) DEFAULT 'N' 
     ,parent_st_id    integer

    );

ALTER TABLE sde_it.rbac_legal_permission ADD CHECK (is_active IN ('N', 'Y')) ;
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
CREATE TABLE sde_it.rbac_database 
    ( 
     st_created_by   nvarchar (75) DEFAULT 'NA'  NOT NULL , 
     st_created_date datetime2 DEFAULT convert(datetime, '1970-01-01', 102)  NOT NULL , 
     st_updated_by   nvarchar (75)  , 
     st_updated_date datetime2 , 
     st_id           INTEGER identity(1,1)  NOT NULL , 
     is_active char(1) DEFAULT 'N'  NOT NULL , 
     server          char(1) , 
     name            nvarchar(100)  NOT NULL 
    ) ;

ALTER TABLE sde_it.rbac_database  ADD CONSTRAINT rbac_database_PK PRIMARY KEY ( st_id ) ;

ALTER TABLE sde_it.rbac_database ADD CONSTRAINT rbac_database_unq UNIQUE ( name , server ) ;
 
ALTER TABLE sde_it.rbac_database ADD CHECK (is_active IN ('N', 'Y')) ; 

--==================
CREATE TABLE sde_it.rbac_object 
    (st_created_by   nvarchar (75) DEFAULT 'NA'  NOT NULL 
     ,st_created_date datetime2 DEFAULT convert(datetime, '1970-01-01', 102)  NOT NULL 
     ,st_updated_by   nvarchar (75)  
     ,st_updated_date datetime2 
     ,st_id           INTEGER identity(1,1)  NOT NULL 
     ,is_active char(1) DEFAULT 'N'  NOT NULL 
     ,name            nvarchar (100)  NOT NULL 
     ,xtype           nvarchar (100)  NOT NULL 
     ,xcomment        nvarchar (255) 
     ,parent_st_id    INTEGER 
     ,rbac_database_st_id INTEGER  NOT NULL 
--     ,rbac_object_name    nvarchar (100)  NOT NULL 
--    ,rbac_object_xtype   nvarchar (100)  NOT NULL 
    );

ALTER TABLE sde_it.rbac_object ADD CHECK (is_active IN ('N', 'Y')) ;

ALTER TABLE sde_it.rbac_object ADD CONSTRAINT rbac_object_PK PRIMARY KEY ( st_id ) ;

ALTER TABLE sde_it.rbac_object ADD CONSTRAINT rbac_object_name_xtype_UN UNIQUE ( name , xtype ) ;

 -- A  LTER TABLE sde_it.rbac_object ADD CHECK (xtype IN ('function', 'package', 'procedure', 'schema', 'synonym', 'table', 'trigger', 'view')) ;
--  A  LTER TABLE sde_it.rbac_object ADD CHECK 'rbac_object_xtype IN ('function', 'package', 'procedure', 'schema', 'synonym', 'table', 'trigger','view'));

--COMMENT ON TABLE sde_it.rbac_object IS 'Represents objects within a database. Note the parent relationship which is used to associate objects within a "schem"'';


--==================
-- If columns added or deleted, update associated triggers.
CREATE TABLE sde_it.rbac_permission 
    (st_created_by   nvarchar (75) DEFAULT 'NA'  NOT NULL 
     ,st_created_date datetime2 DEFAULT convert(datetime, '1970-01-01', 102)  NOT NULL 
     ,st_updated_by   nvarchar (75)  
     ,st_updated_date datetime2 
     ,st_id           INTEGER identity(1,1)  NOT NULL 
     ,is_active char(1) DEFAULT 'N'  NOT NULL 
     ,rbac_role_st_id      INTEGER  NOT NULL 
     ,rbac_object_st_id   INTEGER  NOT NULL 
     ,change_date     datetime2 DEFAULT convert(datetime, '1970-01-01', 102) 
     ,deploy_date     datetime2 DEFAULT null
     ,xselect         char(1) DEFAULT 'N' 
     ,xupdate         char(1) DEFAULT 'N' 
     ,xinsert         char(1) DEFAULT 'N' 
     ,xdelete         char(1) DEFAULT 'N' 
     ,xexecute        char(1) DEFAULT 'N' 
     ,xcreate         char(1) DEFAULT 'N' 
     ,xdrop           char(1) DEFAULT 'N' 
     ,xenable         char(1) DEFAULT 'N' 
     ,xdisable        char(1) DEFAULT 'N' 
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
CREATE TABLE sde_it.rbac_role 
    (st_created_by   nvarchar (75) DEFAULT 'NA'  NOT NULL 
     ,st_created_date datetime2 DEFAULT convert(datetime, '1970-01-01', 102)  NOT NULL 
     ,st_updated_by   nvarchar (75)  
     ,st_updated_date datetime2 
     ,st_id           INTEGER identity(1,1)  NOT NULL 
     ,is_active char(1) DEFAULT 'N'  NOT NULL 
     ,parent_st_id     INTEGER 
     ,name            nvarchar (100)  NOT NULL 
     ,is_system_role  char(1) DEFAULT 'N'  NOT NULL 
     ,change_date     datetime2 DEFAULT convert(datetime, '1970-01-01', 102) 
     ,deploy_date     datetime2 DEFAULT null
    );

alter table sde_it.rbac_role add check (is_active IN ('N', 'Y')) ;
alter table sde_it.rbac_role add check (is_system_role IN ('N', 'Y')) ;
alter table sde_it.rbac_role add constraint rbac_role_pk primary key ( st_id ) ;
alter table sde_it.rbac_role add constraint rbac_role_name_un unique (name) 


--==================
CREATE TABLE sde_it.rbac_actor_role 
    (rbac_actor_st_id     integer  not null
    ,rbac_role_st_id     integer  not null
    ,st_id           integer identity(1,1)  NOT NULL  -- not a primary key
    ,st_created_date datetime2 default convert(datetime, '1970-01-01', 102)  not null
    ,st_created_by   nvarchar (75) default convert(datetime, '1970-01-01', 102)  not null
    ,st_updated_by   nvarchar (75) default convert(datetime, '1970-01-01', 102)
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
---------------------------------------------------------------------
insert into sde_it.rbac_legal_permission (data_type,is_active,xselect, xupdate,xinsert,xdelete,xexecute,xcreate,xdrop,xenable,xdisable) values
 ('SCHEMA'     ,'Y','N','N','N','N', 'N','Y','Y','N', 'N');
,('SQL_TRIGGER','Y','N','N','N','N', 'N','Y','Y','Y', 'Y')
,('USER_TABLE' ,'Y','Y','Y','Y','Y', 'N','Y','Y','N', 'N')
,('VIEW'       ,'Y','Y','Y','Y','Y', 'N','Y','Y','N', 'N')
,('SYNONYM '   ,'Y','Y','Y','Y','Y', 'Y','Y','Y','N', 'N')
,('SQL_SCALAR_FUNCTION' ,'Y','N','N','N','N', 'Y','Y','Y','N', 'N')
,('SQL_STORED_PROCEDURE','Y','N','N','N','N', 'Y','Y','Y','N', 'N');
begin
   declare @lID integer;
   declare @lDate datetime2;
   select @lID = st_id,@lDate = st_created_date where name ='SCHEMA';
   
   update sde_it.rbac_legal_permission 
      set parent_st_id=@lID 
      where st_created_date > @lDate;
   update sde_it.rbac_legal_permission 
      set parent_st_id=null 
      where st_id =@lID;
end;      
   



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


