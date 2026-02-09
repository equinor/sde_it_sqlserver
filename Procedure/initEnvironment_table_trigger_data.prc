/******************************************************************
* Package Info
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 2007/03/23 $
* Last Modified   : $Modtime:  $
* Archive Name    : $Archive:  $
* Description     : $Header:  $
* Revision History: $Revision:  $
* Workfile        : $Workfile:  $
* Copyright info  : Copyright (c), Equinor ASA,Norway. $Date: 2007/03/23 13:46:23 $
******************************************************************
* Description
* Add comment on table or column:
* https://stackoverflow.com/questions/9018518/how-to-add-a-comment-to-an-existing-table-column-in-sql-server
* To set the description programmatically, you can use the 
*  sp_addextendedproperty, sp_updateextendedproperty 
*  and sp_dropextendedproperty stored procedures. 
* Example:
   EXEC sp_addextendedproperty 
       @name = N'MS_Description', @value = 'This is the description of my column',
       @level0type = N'Schema', @level0name = 'dbo',
       @level1type = N'Table', @level1name = 'MyTable', 
       @level2type = N'Column', @level2name = 'MyColumn'o set the description programmatically, you can use the sp_addextendedproperty, sp_updateextendedproperty and sp_dropextendedproperty stored procedures. Example:

   EXEC sp_addextendedproperty 
       @name = N'MS_Description', @value = 'This is the description of my column',
       @level0type = N'Schema', @level0name = 'dbo',
       @level1type = N'Table', @level1name = 'MyTable', 
       @level2type = N'Column', @level2name = 'MyColumn'
    
******************************************************************
* LOG
* Date   Description							                  Done by
* 200815 Alterd length row_creator/updator to allow for		JOTHOR
*  "user/osuser" to be registered. This picks up username when
*  user uses a shared account.
* 170418 Added calculated hour,min and second to batch_status table JOTHOR
* 200418 Added table epsilon							            JOTHOR
* 261119 Added table cleanuptableinfo                      JOTHOR
* 281020 Altered column length in batch_status             JOTHOR
*  and t_basis_clienterrorlog
* 140322 Added table user_administration                   JOTHOR
* 160622 Added table CLIENT_VERSION                        JOTHOR
* 200922 Added table ACCESSIT                              JOTHOR
* 220922 Added maintain_dba_audit_hist (incl job)          JOTHOR
* 290922 Upgraded tiu_cleanuptableinfo to trim values      JOTHOR
* 051022 Added mail defaults in R_TABLE_DEF                JOTHOR
* 251022 Altered table AccessIT to accessit_data           JOTHOR
*    st_dataset now type "date" and default sysdate.
* 171122 Added table PROCESSING_SCRIPT and supporting      JOTHOR
*    elements
* 060123 Added new messages 31-33 "Addtional data..."      JOTHOR
* 030223 Added new message 34 "No data found..."           JOTHOR
* 271124 Upgraded to Sqlserver                             JOTHOR
* 051225 St_created_by/date to have defaults as Sqlserver   JOTHOR
*  has only after triggers.
******************************************************************/

/* --Populate 
merge into user_administration ud
  USING (select
      case when account_status='OPEN' then
         current_date
      else
         null
      end as xopen 
      ,case when account_status='LOCKED' then
         lock_date
      else
        null
      end as xlock 
      ,case when regexp_like(username,'^[AF]_.+@STATOIL.NET') then
         1
       else
         0
       end as isSystemUser
      ,x.* 
   from dba_users x
   where oracle_maintained ='N'
   and username like '%@STATOIL.NET'
   --and not regexp_like(username,'^[AF]_.+@STATOIL.NET')
   ) u
   on (u.username = ud.username)
   when matched then update set ud.open_date=u.xopen
                                ,ud.lock_date=u.xlock
                                ,isSystemUser = u.isSystemUser
   when not matched then insert(username,open_date,lock_date,isSystemUser)
      values(u.username,u.xopen,u.xlock,u.isSystemUser)
*/

---
drop table if exists FRAMEWORK_SCHEMA.dba_audit_hist;
go
create table FRAMEWORK_SCHEMA.dba_audit_hist
(
    os_username   nvarchar(255)
   ,xusername     nvarchar(128)
   ,xcurrent_user nvarchar(128)
   ,xowner        nvarchar(128)
   ,obj_name      nvarchar(128)
   ,action_name   nvarchar(28)
   ,report_day    date
   ,cnt           integer
   ,st_id int identity not null
   ,st_created_by nvarchar(100) not null default N'NA'  -- note capital "N"
   ,st_created_date datetime2   not null default convert(datetime, '1970-01-01', 102)
   ,st_updated_by nvarchar(100)
   ,st_updated_date datetime2   --with time zone
   ,constraint pk_dba_audit_hist primary key (st_id)  
);
go

TABLE_COMMENT(FRAMEWORK_SCHEMA,dba_audit_hist,If needed -to get the login name use SUSER_NAME());
go

---
drop table if exists FRAMEWORK_SCHEMA.user_administration; 
go
create table FRAMEWORK_SCHEMA.user_administration(
    username nvarchar(100)
   ,lock_date date
   ,open_date date
   ,isSystemUser integer default 0 check (isSystemUser in (0,1))
   ,st_id int identity not null
   ,st_created_by nvarchar(100) not null default N'NA'  -- note capital "N"
   ,st_created_date datetime2   not null default convert(datetime, '1970-01-01', 102)
   ,st_updated_by nvarchar(100)
   ,st_updated_date datetime2   --with time zone
   ,constraint pk_user_administration primary key (st_id)
);
go

------------------------------------------------------------------
-- Transit table for AccessIT csv data
------------------------------------------------------------------
drop table if exists FRAMEWORK_SCHEMA.accessit_data; -- cascade constraints purge;
go
create table FRAMEWORK_SCHEMA.accessit_data
(
    full_name         nvarchar(100)
   ,short_name        nvarchar(50)
   ,employee_no       nvarchar(50)
   ,contract_date     nvarchar(200)
   ,organization      nvarchar(200)
   ,position          nvarchar(200)
   ,business_process  nvarchar(200)
   ,access_type       nvarchar(50)
   ,xaccess           nvarchar(100)
   ,xrole             nvarchar(100)
   ,valid_to          nvarchar(50)
   ,yearly_cost_nok   nvarchar(20)
   ,st_dataset        date default getdate()
   ,st_id int identity not null
   ,st_created_by nvarchar(100) not null default N'NA'  -- note capital "N"
   ,st_created_date datetime2   not null default convert(datetime, '1970-01-01', 102)
   ,st_updated_by nvarchar(100)
   ,st_updated_date datetime2   --with time zone
   ,constraint pk_accessit_data primary key (st_id)  
);
go

------------------------------------------------------------------
-- Processing_script  (table) 
------------------------------------------------------------------
drop table if exists FRAMEWORK_SCHEMA.processing_script
go
create table FRAMEWORK_SCHEMA.processing_script
(
    system_name       nvarchar(100)
   ,container_name    nvarchar(100)
   ,pre_create        nvarchar(4000)
   ,pre_create_type   nvarchar(30)   default 'sql'
   ,post_create       nvarchar(4000)
   ,post_create_type  nvarchar(30)   default 'sql'
   ,pre_delete        nvarchar(4000)
   ,pre_delete_type   nvarchar(30)   default 'sql'
   ,post_delete       nvarchar(4000)
   ,post_delete_type  varchar(30)   default 'sql'
   ,st_id            int identity not null
   ,st_created_by nvarchar(100) not null default N'NA'  -- note capital "N"
   ,st_created_date datetime2   not null default convert(datetime, '1970-01-01', 102)
   ,st_updated_by    nvarchar(100)
   ,st_updated_date  datetime2            --with time zone
   ,constraint pk_processing_script primary key (st_id)
   ,constraint unq_processing_script unique (system_name, container_name)
);
go

exec sp_dropextendedproperty  @name = N'FRAMEWORK_SCHEMA.processing_script'
    ,@level0type = N'Schema'
    , @level0name = 'FRAMEWORK_SCHEMA'
    ,@level1type = N'Table'
    , @level1name = 'processing_script';
go

exec sp_addextendedproperty 
    @name = N'FRAMEWORK_SCHEMA.processing_script'
   ,@value = 'System_id and container_id are mutally exclusive. 
Providing a system_id implies all containers in the system are subject to these processing scripts.
Providing a container_id overrides the processing scripts registered on the system (if any).
All scripts are directly related to user. rbac is a system for handling user access to systems and containers.
Therefore the create and delete scripts are related to the creation and deletion of users.
Any parameter to be supplied to script is limited to the user in focus.
\
Examples (newlines are represented as "\n", a command separator as "go"
1)
   begin\n
      ....
   end;\n
   go\n
2)
create users ....;\n
go\n
create table...;\n
go\n
-- create seque ....;\n
-- an optional "go\n" can be placed after last command
'
   ,@level0type = N'Schema', @level0name = 'FRAMEWORK_SCHEMA'
   ,@level1type = N'Table', @level1name = 'processing_script';
   --,@level2type = N'Column', @level2name = 'MyColumn'
go

TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,processing_script,container_name,Database name normally.)
go

------------------------------------------------------------------
-- The procedure cleanUpLogTable (and the likes) use the information
-- is this table to perform its tasks.
------------------------------------------------------------------
drop table if exists FRAMEWORK_SCHEMA.cleanuptableinfo; -- cascade constraints purge;
go
create table FRAMEWORK_SCHEMA.cleanuptableinfo (
    appname nvarchar(130) default 'na' not null
   ,columnappname nvarchar(130) default 'na' not null
   ,tabname nvarchar(60) not null
   ,message nvarchar(130)
   ,days integer  not null
   ,synccolumn nvarchar(60)  not null
   ,isactive integer default 0   not null
   ,st_id            int identity not null
   ,st_created_by    nvarchar(100) not null  default N'NA' 
   ,st_created_date  datetime2   not null default convert(datetime, '1970-01-01', 102)
   ,st_updated_by    nvarchar(100)
   ,st_updated_date  datetime2            --with time zone
   ,constraint pk_cleanuptableinfo primary key (st_id)
   ,constraint unq_cleanuptableinfo unique (appname,tabname)
   ,constraint con_isactive check (isactive in (0,1))
   ,constraint con_nr_days  check (days >= 0)
);
go
    
TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,cleanuptableinfo,tabname,The table to be processed (in this schema).);
go
TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,cleanuptableinfo,columnappname,The column name within the table ("tabname") on which "appname" resides.);
go
TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,cleanuptableinfo,columnappname,Whether or not this entry is active (1) or not (0).);
go
TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,cleanuptableinfo,appname ,The application to sync on. See also "message".);
go
TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,cleanuptableinfo,message,Sometimes the message contains sync information.);
go
TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,cleanuptableinfo,days,Number of days before processing is to take place.);
go
TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,cleanuptableinfo,syncColumn,The column to sync on. The column is to be of type date/timestamp.);
go

----------------------------------------
-- COMPRESS_LOG  (Table) 
----------------------------------------
drop table if exists COMPRESS_LOG; --; -- cascade constraints purge;
go

create table FRAMEWORK_SCHEMA.compress_log
(
    sde_id             integer not null
   ,server_id          integer not null
   ,direct_connect     char(1)
   ,compress_start     date
   ,start_state_count  integer
   ,compress_end       date
   ,end_state_count    integer
   ,compress_status    nvarchar(20)
   ,owner              nvarchar(75)
   ,nodename           nvarchar(100)
   ,st_id            int identity not null
   ,st_created_by nvarchar(100) not null default N'NA'  -- note capital "N"
   ,st_created_date datetime2   not null default convert(datetime, '1970-01-01', 102)
   ,st_updated_by    nvarchar(100)
   ,st_updated_date  datetime2            --with time zone
   ,constraint pk_compress_log primary key (st_id)  
);
go

-----------------------------------------------------
-- Jobs can have a fault tolerance before reporting an
-- error. The table epsilon can be used to set boundaries
-- for such.
-- Note the defaults
-----------------------------------------------------
drop table if exists FRAMEWORK_SCHEMA.epsilon; -- cascade constraints purge;
go
create table FRAMEWORK_SCHEMA.epsilon(
    name nvarchar(100) not null
   ,lower float default -1 not null
   ,lower_unit nvarchar(50) default 'NA' not null check(lower_unit in ('absolute','procent','NA'))
   ,upper float default -1 not null
   ,upper_unit nvarchar(50) default 'NA' not null check(upper_unit in ('absolute','procent','NA'))
   ,st_id int identity not null
   ,st_created_by nvarchar(100) not null default N'NA'  -- note capital "N"
   ,st_created_date datetime2   not null default convert(datetime, '1970-01-01', 102)
   ,st_updated_by nvarchar(100)
   ,st_updated_date datetime2   --with time zone
   ,constraint pk_epsilon primary key (st_id)
   ,constraint unq_epsilon unique (name)
);
go

exec sp_dropextendedproperty  
     @name = N'FRAMEWORK_SCHEMA.$2.$3'
    ,@level0type = N'Schema', @level0name = 'FRAMEWORK_SCHEMA'
    ,@level1type = N'Table', @level1name = 'epsilon';
go
exec sp_addextendedproperty 
     @name = N'FRAMEWORK_SCHEMA.$2.$3'
     ,@value = 'Intended for jobs so as to allow to evaluate whether or not to flag an error. 
If no limit is to be imposed, set value to -1 and unit to "NA". These are also the default values.
NOTE: defaults in place.'
    ,@level0type=N'Schema',@level0name = 'FRAMEWORK_SCHEMA'
    ,@level1type=N'Table',@level1name = 'epsilon';
go
TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,epsilon,lower,The lower tolerance permitted. A negative number indicates infinity.);
go
TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,epsilon,lower_unit,The lower_unit tolerance e.g procent.);
go
TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,epsilon,upper_unit,The upper_unit tolerance e.g procent.);
go
TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,epsilon,upper,The upper tolerance permitted. A negative number indicates infinity);
go

-----------------------------------------------------
-- t_basis_clienterrorlog  (table) 
-- should clientmessage_s be number rather than nvarchar(19)
-----------------------------------------------------
drop table if exists FRAMEWORK_SCHEMA.t_basis_clienterrorlog; -- cascade constraints purge;
go
create table FRAMEWORK_SCHEMA.t_basis_clienterrorlog
(
   --,clienterrorlog_s     nvarchar(19)        not null
    logid                integer                      null
   ,userregistered       nvarchar(40)            null
   ,dateregistered       date                         null
   ,messagecode          nvarchar(13)            null
   ,messagetext          nvarchar(4000)          null
   ,dberrorcode          integer                      null
   ,dberrortext          nvarchar(255)           null
   ,objecterroroccurred  nvarchar(40)            null
   ,rowerroroccurred     integer                      null
   ,applicationname      nvarchar(150)           null
   ,applicationversion   nvarchar(50)            null
   ,description          nvarchar(255)           null
   ,host                 nvarchar(255) default 'NA'   null
   ,st_id int identity not null
   ,st_created_by nvarchar(100) not null default N'NA'  -- note capital "N"
   ,st_created_date datetime2   not null default convert(datetime, '1970-01-01', 102)
   ,st_updated_by nvarchar(100)
   ,st_updated_date datetime2   --with time zone
   ,constraint pk_t_basis_clienterrorlog primary key (st_id)
);
go

TABLE_COMMENT(FRAMEWORK_SCHEMA,t_basis_clienterrorlog,To list errors for a particular batch job:
select *
from sde_it.t_basis_clienterrorlog l
  inner join sde_it.batch_status b
  on l.dateregistered between b.start_date and b.end_date
where b.name = ''cleanUpTransitTable''
order by l.dateregistered;);
go

-----------------------------------------------------
-- t_basis_clientmessage  (table) 
-----------------------------------------------------
drop table if exists FRAMEWORK_SCHEMA.t_basis_clientmessage; -- cascade constraints purge;
go
create table FRAMEWORK_SCHEMA.t_basis_clientmessage
(
   -- ,clientmessage_s  nvarchar(19)            not null
    messagecode      nvarchar(13)            not null
   ,messagetype      nvarchar(50)                 null
   ,messagetext      nvarchar(255)           not null
   ,titletext        nvarchar(40)                null
   ,iconcode         integer                       null
   ,buttoncode       integer                       null
   ,logerror         integer                       null
   ,application      nvarchar(100)  default 'GLOBAL'  null
   ,description      nvarchar(255)               null
   ,st_id int identity not null
   ,st_created_by nvarchar(100) not null default N'NA'  -- note capital "N"
   ,st_created_date datetime2   not null default convert(datetime, '1970-01-01', 102)
   ,st_updated_by nvarchar(100)
   ,st_updated_date datetime2   --with time zone
   ,constraint pk_t_basis_clientmessage primary key (st_id)
   ,constraint unq_t_basis_clientmessage unique (application, messagecode)
);
go

TABLE_COMMENT(FRAMEWORK_SCHEMA,t_basis_clientmessage,Reserved codes : 1-99. 
System specific errormessages are to start from 100 onwards.);
go

-----------------------------------------------------
-- batch_status  (table) 
-- Virtual column example:
--  TotalPrice AS (Price + Tax)  PERSISTED   stored
--  TotalPrice AS (Price + Tax) -- recalculate everytime
-----------------------------------------------------
drop table if exists FRAMEWORK_SCHEMA.batch_status; -- cascade constraints purge;
go
create table FRAMEWORK_SCHEMA.batch_status
(
    name                     nvarchar(150)   not null
   ,version                  integer              not null
   ,start_date               date                     null
   ,end_date                 date                     null
   ,nr_of_error              integer                  null
   ,nr_business_transaction  integer                  null
   ,message                  nvarchar(1000)      null
   ,host                     nvarchar(100)   DEFAULT 'NA'
   ,hour as datediff(hour,  start_date,end_date) persisted
   ,min  as datediff(minute,start_date,end_date) persisted
   ,sec  as datediff(second,start_date,end_date) persisted
   ,st_id            int identity not null
   ,st_created_by nvarchar(100) not null default N'NA'  -- note capital "N"
   ,st_created_date datetime2   not null default convert(datetime, '1970-01-01', 102)
   ,st_updated_by    nvarchar(100)
   ,st_updated_date  datetime2            --with time zone
   ,constraint pk_batch_status primary key (st_id)
   ,constraint unq_batch_status unique (name, version)
);
go

TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,batch_status,hour,The number of hours.);
go
TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,batch_status,min,The number of minutes.);
go
TABLE_COLUMN_COMMENT(FRAMEWORK_SCHEMA,batch_status,sec,The number of seconds.);
go

---------
drop table if exists FRAMEWORK_SCHEMA.r_table_def; -- cascade constraints purge;
go
create table FRAMEWORK_SCHEMA.r_table_def
(
    table_name       nvarchar(100)           not null
   ,table_kind       nvarchar(100)           not null
   ,column_name      nvarchar(100)           not null
   ,valid_value      nvarchar(250)
   ,st_id            int identity not null
   ,st_created_by nvarchar(100) not null default N'NA'  -- note capital "N"
   ,st_created_date datetime2   not null default convert(datetime, '1970-01-01', 102)
   ,st_updated_by    nvarchar(100)
   ,st_updated_date  datetime2   --with time zone
   ,constraint pk_r_table_def primary key (st_id)
   ,constraint unq_r_table_def unique (table_name, table_kind, column_name)
);
go

----
drop table if exists FRAMEWORK_SCHEMA.tab_variable; -- cascade constraints purge;
go
create table FRAMEWORK_SCHEMA.tab_variable
(
    category         nvarchar(100)           not null
   ,xkey           nvarchar(100)           not null
   ,valid_value      nvarchar(250) default 'NA' not null
   ,isactive         integer default 1 not null check(isactive in (0,1))
   ,xcomment         nvarchar(300)
   ,st_id            int identity not null
   ,st_created_by nvarchar(100) not null default N'NA'  -- note capital "N"
   ,st_created_date datetime2   not null default convert(datetime, '1970-01-01', 102)
   ,st_updated_by    nvarchar(100)
   ,st_updated_date  datetime2            --with time zone
   ,constraint pk_tab_variable primary key (st_id)  
      ,constraint unq_tab_variable unique (category,key)
);
go

----
drop table if exists FRAMEWORK_SCHEMA.client_version
go
create table FRAMEWORK_SCHEMA.client_version
(
    logon_time      datetime    not null
   ,sid             integer not null
   ,[serial#]       integer not null
   ,machine         nvarchar(64)
   ,program         nvarchar(48)
   ,client_version  nvarchar(40)
   ,osuser          nvarchar(30)
   ,client_driver   nvarchar(30)
   ,client_charset  nvarchar(40)
   ,module          nvarchar(64)
   ,status          nvarchar(3)
   ,st_id            int identity not null
   ,st_created_by nvarchar(100) not null default N'NA'  -- note capital "N"
   ,st_created_date datetime2   not null default convert(datetime, '1970-01-01', 102)
   ,st_updated_by    nvarchar(100)
   ,st_updated_date  datetime2   --with time zone
   ,constraint pk_ primary key (st_id)  
   ,constraint unq_client_version unique (logon_time, sid, [serial#])
);
go

exec sp_dropextendedproperty  
     @name = N'FRAMEWORK_SCHEMA.client_version'
    ,@level0type = N'Schema', @level0name = 'FRAMEWORK_SCHEMA'
    ,@level1type = N'Table', @level1name = 'client_version';
go
exec sp_addextendedproperty 
     @name = N'FRAMEWORK_SCHEMA.client_version'
     ,@value = 'select distinct machine, program, client_version, osuser, module, status
from FRAMEWORK_SCHEMA.client_version
where status like ''%FIX%'' and client_version not like ''%Unknown%''
order by status desc;

select logon_time,machine, program, client_version, osuser, module, status
from FRAMEWORK_SCHEMA.client_version
where status like ''%FIX%'' and client_version not like ''%Unknown%''
order by logon_time desc,status desc;'
    ,@level0type=N'Schema',@level0name = 'FRAMEWORK_SCHEMA'
    ,@level1type=N'Table',@level1name = 'client_version';  
go

--***************************************************************
--Sequences
--***************************************************************


--***************************************************************
-- Preload data
-- SDE_IT message codes reserved below 100 (not including 100).
-- All system specific messages should come from 100 onwards
--***************************************************************
begin
   insert into FRAMEWORK_SCHEMA.cleanuptableinfo(appname, tabname, message, days, synccolumn, isactive, columnappname)
      values('NA', 't_basis_clienterrorlog', NULL, 10, 'row_create_date', 1, 'NA');
   insert into FRAMEWORK_SCHEMA.cleanuptableinfo(appname, tabname, message, days, synccolumn,isactive, columnappname)
      values('NA', 'process_information_history', NULL, 90, 'start_time', 1, 'NA');
   insert into FRAMEWORK_SCHEMA.cleanuptableinfo(appname, tabname, message, days, synccolumn, isactive, columnappname)
      values('NA', 'runlog', NULL, 90, 'start_date', 0, 'NA');
   insert into FRAMEWORK_SCHEMA.cleanuptableinfo(appname, tabname, message, days, synccolumn, isactive, columnappname)
      values('NA', 'table_lock_history', NULL, 60, 'start_time', 1, 'NA');
   insert into FRAMEWORK_SCHEMA.cleanuptableinfo(appname, tabname, message, days, synccolumn, isactive, columnappname)
      values('NA', 'sync_state', NULL, 60, 'start_time', 0, 'NA');
   insert into FRAMEWORK_SCHEMA.cleanuptableinfo(appname, tabname, message, days, synccolumn, isactive, columnappname)
      values('NA', 'compress_log', NULL, 10, 'compress_start', 1, 'NA');
   insert into FRAMEWORK_SCHEMA.cleanuptableinfo(appname, tabname, message, days, synccolumn, isactive, columnappname)
      values('NA', 'client_version', NULL, 10, 'logon_time', 1, 'NA');
   commit;
end;

begin
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (1 ,'Failed to delete <=>1<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (2 ,'Failed to delete <=>1<@>. <=>1<@> has children in <=>2<@>');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (3 ,'Failed to delete <=>1<@>. <=>1<@> is a member of <=>2<@> in <=>3<@>');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (4 ,'Failed to insert <=>1<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (5 ,'Failed to insert <=>1<@>. A parent in <=>2<@> is mandatory.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (6 ,'An instance with the value <=>1<@> in <=>2<@> already exists.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (7 ,'Detail <=>1<@> in <=>2<@> does not have an owner in <=>3<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (8 ,'The value <<=>1<@>> is outside of range. Legal range is <=>2<@> to <=>3<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (9 ,'Illegal value <<=>1<@>>. Legal value(s): <=>2<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (10,'End date must be after start date.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (11,'The field <=>1<@> is mandatory and is to be supplied.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (12,'The <=>1<@> does not exist.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (13,'The <=>1<@> with key=<<=>2<@>> does not exist.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (14,'Failed to update <=>1<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (15,'Failed to update <=>1<@>. A parent in <=>2<@> is mandatory.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (16,'Failed to associate <=>1<@> with <=>2<@>. <=>3<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (17,'Failed to disassociate <=>1<@> from <=>2<@>. <=>3<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (18,'Illegal to update key value <=>1<@> in <=>2<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (19,'The <=>1<@> of <=>2<@> has been rejected. The instance has been updated by somebody else.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (20,'<=>1<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (21,'System error occurred. Please contact the system administrator.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (22,'Database error occurred. Please contact the system administrator.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (23,'The attributes <<=>1<@>> and <<=>2<@>> are mutually exclusive.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (24,'The supplied attribute <<=>1<@>> cannot be null.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (25,'Not implemented yet.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (26,'Missing data in <=>1<@>. Abs diff = <=>2<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (27,'Missing data in <=>1<@>. Procent diff = <=>2<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (28,'Missing data in <=>1<@>. Abs diff = <=>2<@>. Procent diff = <=>3<@>%.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (29,'Mulitple instances found for <=>1<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (30,'Arc: Table <=>1<@> violates constraint on <=>2<@>. Discriminator column ''<=>3<@>'' doesn''t have value ''<=>4<@>''.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (31,'Addtional data in <=>1<@>. Abs diff = <=>2<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (32,'Addtional data in <=>1<@>. Procent diff = <=>2<@>.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (33,'Addtional data in <=>1<@>. Abs diff = <=>2<@>. Procent diff = <=>3<@>%.');
   insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (34,'No data found for <=>1<@>.');
   commit;
/*   TABLE_COMMENT(FRAMEWORK_SCHEMA,t_basis_clientmessage is 'ARC explanation of paramenters for code #30
     1: current table<&>,<%> 2: table with discriminator<&>,<%> 3: discriminator column in table #2<&>,<%> 4: discriminator value
     Table (1)procurement_exp violates Arc constraint on Table (2)procurement - discriminator column (3)procurement_type doesn''t have value (4)''EXP''.');
*/     
end;

--=========================================================
-- Load errormessages into
--=========================================================



/*
--=========================================================
-- Oracle related code. Retained for historicale reasons.
--=========================================================

-----------------------------------------------------------------------
-- SMTP_SERVER_OUT mailhost.statoil.no
-- SMTP_PORT_OUT defaults are amongst others: 25, 465, 587, 2525
-- SMTP_DOMAIN
-----------------------------------------------------------------------
begin
   insert into FRAMEWORK_SCHEMA.r_table_def(table_name,table_kind,column_name,valid_value) values('SMTP_MAIL','MAILSERVER','SMTP_SERVER_OUT','mailhost.statoil.no');
   insert into FRAMEWORK_SCHEMA.r_table_def(table_name,table_kind,column_name,valid_value) values('SMTP_MAIL','MAILSERVER','SMTP_PORT_OUT','25');
   insert into FRAMEWORK_SCHEMA.r_table_def(table_name,table_kind,column_name,valid_value) values('SMTP_MAIL','MAILSERVER','SMTP_DOMAIN','NA');
   commit;
end;

-- NOTE: Remember to update the system name in SYSTEM_DETAIL.
begin
   insert into FRAMEWORK_SCHEMA.tab_variable(category,key,xcomment) values ('SYSTEM_DETAIL','NAME','This is the of the system e.g.IRIS21');
   insert into FRAMEWORK_SCHEMA.tab_variable(category,key,valid_value,xcomment) values ('SYSTEM_DETAIL','DELIMITER',';','Delimiter to use separating the chain of datasources.');
   insert into FRAMEWORK_SCHEMA.tab_variable(category,key,valid_value,xcomment) values ('SYSTEM_DETAIL','MAX_DATASOURCE_SET',5,'The max number of datasources in the chain. Those exceeding are removed from the chain.');
   commit;
end;


--***************************************************************
-- Initiate jobs (Oracle code)
-- to_date('04.11.2008 18:00:00','dd/mm/yyyy hh24:mi:ss')
--***************************************************************
set define on
set feed on
define lJobName = '/ *cleanup userlogs* /FRAMEWORK_SCHEMA.CleanupLogTable;';

declare
  cursor cur_job 
  is 
    select job
      from dba_jobs 
      where what = '&lJobName';
begin
  for i in cur_job  
  loop
    dbms_output.put_line('Removing job nr'||i.job||' name=&lJobName');
    dbms_job.remove(i.job);
  end loop;
  commit;
end;
go
declare
  x number;
begin
  sys.dbms_job.submit
    ( job       => x 
     ,what      => '&lJobName'
     ,next_date => trunc(sysdate+1)+18/24 
     ,interval  => 'trunc(sysdate+1)+18/24'
     ,no_parse  => true
    );
  sys.dbms_output.put_line('Job number is: ' || to_char(x));
end;
go
commit;

/ *define lJobName = '/ *cleanup userlogs* /FRAMEWORK_SCHEMA.cleanupTableLockHist;';

--declare
  cursor cur_job 
  is 
    select job
      from dba_jobs 
      where what = '&lJobName';
begin
  for i in cur_job  
  loop
    dbms_output.put_line('Removing job nr'||i.job||' name=&lJobName');
    dbms_job.remove(i.job);
  end loop;
  commit;
end;
go
declare
  x number;
begin
  sys.dbms_job.submit
    ( job       => x 
     ,what      => '&lJobName'
     ,next_date => trunc(sysdate+1)+18/24 
     ,interval  => 'trunc(sysdate+1)+18/24'
     ,no_parse  => true
    );
  sys.dbms_output.put_line('Job number is: ' || to_char(x));
--end;
--/
--commit;
* /

DECLARE
  X NUMBER;
BEGIN
    SYS.DBMS_JOB.SUBMIT
    ( job       => X 
     ,what      => '/*maintain_dba_audit_hist*/begin SDE_IT.maintain_dba_audit_hist; end;'
     ,next_date => trunc(sysdate+1)+1/24 
     ,interval  => 'trunc(sysdate+1)+1/24'
     ,no_parse  => FALSE
    );
    SYS.DBMS_OUTPUT.PUT_LINE('Job Number is: ' || to_char(x));
  COMMIT;
END;

prompt --> Consider activating scheduled jobs. See under directory Job
prompt --> Example. Job/ScheduledJob-Log_client_version.sql
prompt -->   This is used to populate table CLIENT_VERSION.
set feed off
set define off

--=========================================================
-- End of Oracle related code. Retained for historicale reasons.
--=========================================================


*/

