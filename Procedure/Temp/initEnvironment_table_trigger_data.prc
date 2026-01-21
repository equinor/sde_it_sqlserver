------------------------------------------------------------------
-- Package Info
-- Author          : $Author: JOTHOR $
-- Original Date   : $Date: 2007/03/23 $
-- Last Modified   : $Modtime:  $
-- Archive Name    : $Archive:  $
-- Description     : $Header:  $
-- Revision History: $Revision:  $
-- Workfile        : $Workfile:  $
-- Copyright info  : Copyright (c), Equinor ASA,Norway. $Date: 2007/03/23 13:46:23 $
------------------------------------------------------------------
-- Description
--
------------------------------------------------------------------
-- LOG
-- Date   Description							                  Done by
-- 200815 Alterd length row_creator/updator to allow for		JOTHOR
--  "user/osuser" to be registered. This picks up username when
--  user uses a shared account.
-- 170418 Added calculated hour,min and second to batch_status table JOTHOR
-- 200418 Added table epsilon							            JOTHOR
-- 261119 Added table CLEANUPTABLEINFO                      JOTHOR
-- 281020 Altered column length in batch_status             JOTHOR
--  and t_basis_clienterrorlog
-- 140322 Added table user_administration                   JOTHOR
-- 160622 Added table CLIENT_VERSION                        JOTHOR
-- 200922 Added table ACCESSIT                              JOTHOR
-- 220922 Added maintain_dba_audit_hist (incl job)          JOTHOR
-- 290922 Upgraded tiu_cleanuptableinfo to trim values      JOTHOR
-- 051022 Added mail defaults in R_TABLE_DEF                JOTHOR
-- 251022 Altered table AccessIT to accessit_data           JOTHOR
--    st_dataset now type "date" and default sysdate.
-- 171122 Added table PROCESSING_SCRIPT and supporting      JOTHOR
--    elements
-- 060123 Added new messages 31-33 "Addtional data..."      JOTHOR
-- 030223 Added new message 34 "No data found..."           JOTHOR
------------------------------------------------------------------

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

create table FRAMEWORK_SCHEMA.dba_audit_hist
(
  os_username   varchar2(255 byte),
  username      varchar2(128 byte),
  current_user  varchar2(128 byte),
  owner         varchar2(128 byte),
  obj_name      varchar2(128 byte),
  action_name   varchar2(28 byte),
  report_day    date,
  cnt           integer
);

--drop table FRAMEWORK_SCHEMA.user_administration; 
create table FRAMEWORK_SCHEMA.user_administration(
 username varchar2(100)
,lock_date date
,open_date date
,isSystemUser integer default 0 check (isSystemUser in (0,1))
,st_created_by varchar2(100)
,st_created_date date
,st_updated_by varchar2(100)
,st_updated_date date
);

------------------------------------------------------------------
-- Transit table for AccessIT csv data
------------------------------------------------------------------
--drop table FRAMEWORK_SCHEMA.accessit_data cascade constraints purge;
create table FRAMEWORK_SCHEMA.accessit_data
(
  full_name         varchar2(100),
  short_name        varchar2(50),
  employee_no       varchar2(50),
  contract_date     varchar2(200),
  organization      varchar2(200),
  position          varchar2(200),
  business_process  varchar2(200),
  access_type       varchar2(50),
  xaccess           varchar2(100),
  xrole             varchar2(100),
  valid_to          varchar2(50),
  yearly_cost_nok   varchar2(20),
  st_dataset        date default sysdate
);

------------------------------------------------------------------
-- Processing_script  (table) 
------------------------------------------------------------------
create table FRAMEWORK_SCHEMA.processing_script
(
  id                integer                     not null,
  system_name       varchar2(100 byte),
  container_name    varchar2(100 byte),
  pre_create        varchar2(4000 byte),
  pre_create_type   varchar2(30 byte)           default 'sql',
  post_create       varchar2(4000 byte),
  post_create_type  varchar2(30 byte)           default 'sql',
  pre_delete        varchar2(4000 byte),
  pre_delete_type   varchar2(30 byte)           default 'sql',
  post_delete       varchar2(4000 byte),
  post_delete_type  varchar2(30 byte)           default 'sql',
  created_by        nvarchar2(75),
  created_date      timestamp(6),
  updated_by        nvarchar2(75),
  updated_date      timestamp(6)
);

comment on table FRAMEWORK_SCHEMA.processing_script is 'System_id and container_id are mutally exclusive.\ 
Providing a system_id implies all containers in the system are subject to these processing scripts.\
Providing a container_id overrides the processing scripts registered on the system (if any).\
All scripts are directly related to user. rbac is a system for handling user access to systems and containers.\
Therefore the create and delete scripts are related to the creation and deletion of users.\
Any parameter to be supplied to script is limited to the user in focus.\
\
Examples (newlines are represented as "\n", a command separator as "/"\
1)\
   begin\n\
      ....
   end;\n\
2)
create users ....;\n\
/\n\
create table...;\n\
/\n\
create seque ....;\n\
-- an optional "/\n" can be placed after last command\
';

comment on column FRAMEWORK_SCHEMA.processing_script.container_name IS 'Database name normally.';
create unique index xpkprocessing_script on FRAMEWORK_SCHEMA.processing_script (id);
create unique index processing_script_un on FRAMEWORK_SCHEMA.processing_script (system_name, container_name);
alter table FRAMEWORK_SCHEMA.processing_script add (constraint xpkprocessing_script primary key (id) using index xpkprocessing_script);

------------------------------------------------------------------
-- The procedure cleanUpLogTable (and the likes) use the information
-- is this table to perform its tasks.
------------------------------------------------------------------
--drop table FRAMEWORK_SCHEMA.cleanuptableinfo cascade constraints purge;
create table FRAMEWORK_SCHEMA.cleanuptableinfo (
    APPNAME VARCHAR2(130) default 'NA' NOT NULL
   ,COLUMNAPPNAME VARCHAR2(130) default 'NA' NOT NULL
   ,TABNAME VARCHAR2(60) NOT NULL
   ,MESSAGE VARCHAR2(130)
   ,DAYS INTEGER  NOT NULL
   ,SYNCCOLUMN VARCHAR2(60)  NOT NULL
   ,ISACTIVE INTEGER DEFAULT 0   NOT NULL
   ,created_by varchar2(50) not null
   ,created_date timestamp not null
   ,updated_by varchar2(50)
   ,updated_date timestamp
   ,CONSTRAINT PK_CLEANUPTABLEINFO
     PRIMARY KEY
     (APPNAME,TABNAME)
   ,CONSTRAINT CON_ISACTIVE
     CHECK (ISACTIVE IN ( 0,1))
   ,CONSTRAINT CON_NR_DAYS
     CHECK (DAYS >= 0)
);
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.tabname is 'The table to be processed (in this schema).';
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.columnappname is 'The column name within the table ("tabname") on which "appname" resides.';
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.isactive is 'Whether or not this entry is active (1) or not (0).';
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.appname  is 'The application to sync on. See also "message".';
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.message is 'Sometimes the message contains sync information.';
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.days is 'Number of days before processing is to take place.';
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.syncColumn is 'The column to sync on. The column is to be of type date/timestamp.';

----------------------------------------
-- COMPRESS_LOG  (Table) 
----------------------------------------
DROP TABLE COMPRESS_LOG cascade constraints purge;
CREATE TABLE COMPRESS_LOG
(
  SDE_ID             INTEGER                    NOT NULL,
  SERVER_ID          INTEGER                    NOT NULL,
  DIRECT_CONNECT     VARCHAR2(1 ),
  COMPRESS_START     DATE,
  START_STATE_COUNT  INTEGER,
  COMPRESS_END       DATE,
  END_STATE_COUNT    INTEGER,
  COMPRESS_STATUS    VARCHAR2(20 ),
  OWNER              VARCHAR2(75 ),
  NODENAME           VARCHAR2(100 )
);

-----------------------------------------------------
-- Jobs can have a fault tolerance before reporting an
-- error. The table epsilon can be used to set boundaries
-- for such.
-- Note the defaults
-----------------------------------------------------
--drop table epsilon cascade constraints purge;;

create table epsilon(
  name varchar2(100) not null
 ,lower float default -1 not null
 ,lower_unit varchar2(50) default 'NA' not null check(lower_unit in ('absolute','procent','NA'))
 ,upper float default -1 not null
 ,upper_unit varchar2(50) default 'NA' not null check(upper_unit in ('absolute','procent','NA'))
 );
 ALTER TABLE SDE_IT.EPSILON ADD CONSTRAINT pk_epsilon PRIMARY KEY (NAME)  ENABLE VALIDATE;
 
comment on table epsilon is 'Intended for jobs so as to allow to evaluate whether or not to flag an error. 
If no limit is to be imposed, set value to -1 and unit to "NA". These are also the default values.
NOTE: defaults in place.';
comment on column epsilon.lower is 'The lower tolerance permitted. A negative number indicates infinity.';
comment on column epsilon.lower_unit is 'The lower_unit tolerance e.g procent.';
comment on column epsilon.upper_unit is 'The upper_unit tolerance e.g procent.';
comment on column epsilon.upper is 'The upper tolerance permitted. A negative number indicates infinity';



-----------------------------------------------------
-- t_basis_clienterrorlog  (table) 
-- should clientmessage_s be number rather than varchar2(19)
-----------------------------------------------------
drop table FRAMEWORK_SCHEMA.t_basis_clienterrorlog cascade constraints purge;

create table FRAMEWORK_SCHEMA.t_basis_clienterrorlog
(
  clienterrorlog_s     varchar2(19)        not null,
  logid                integer                      null,
  userregistered       varchar2(40)            null,
  dateregistered       date                         null,
  messagecode          varchar2(13)            null,
  messagetext          varchar2(4000)          null,
  dberrorcode          integer                      null,
  dberrortext          varchar2(255)           null,
  objecterroroccurred  varchar2(40)            null,
  rowerroroccurred     integer                      null,
  applicationname      varchar2(150)           null,
  applicationversion   varchar2(50)            null,
  description          varchar2(255)           null,
  host                 varchar2(255) DEFAULT 'NA'   null,
  row_creator          varchar2(100)            null,
  row_create_date      date                         null,
  updator              varchar2(100)            null,
  update_date          date                         null,
  constraint xpkt_basis_clienterrorlog primary key (clienterrorlog_s)
);

comment on table FRAMEWORK_SCHEMA.t_basis_clienterrorlog is 'To list errors for a particular batch job:
select *
from sde_it.t_basis_clienterrorlog l
  inner join sde_it.batch_status b
  on l.dateregistered between b.start_date and b.end_date
where b.name = ''cleanUpTransitTable''
order by l.dateregistered;'

-----------------------------------------------------
-- t_basis_clientmessage  (table) 
-----------------------------------------------------
drop table FRAMEWORK_SCHEMA.t_basis_clientmessage cascade constraints purge;

create table FRAMEWORK_SCHEMA.t_basis_clientmessage
(
  clientmessage_s  varchar2(19)            not null,
  messagecode      varchar2(13)            not null,
  messagetype      varchar2(1)                 null,
  messagetext      varchar2(255)           not null,
  titletext        varchar2(40)                null,
  iconcode         float(126)                       null,
  buttoncode       float(126)                       null,
  logerror         float(126)                       null,
  application      varchar2(100)  default 'GLOBAL'  null,
  description      varchar2(255)               null,
  row_creator      varchar2(100)               null,
  row_create_date  date                             null,
  updator          varchar2(100)               null,
  update_date      date                             null,
  constraint xpkt_basis_clientmessage  primary key (clientmessage_s)
);

comment on table FRAMEWORK_SCHEMA.t_basis_clientmessage is'Reserved codes : 1-99. 
System specific errormessages are to start from 100 onwards';


-----------------------------------------------------
-- xak1t_basis_clientmessage  (index) 
--
--  dependencies: 
--   t_basis_clientmessage (table)
-----------------------------------------------------
create unique index FRAMEWORK_SCHEMA.xak1t_basis_clientmessage on FRAMEWORK_SCHEMA.t_basis_clientmessage
(application, messagecode);

-----------------------------------------------------
-- batch_status  (table) 
-----------------------------------------------------
drop table FRAMEWORK_SCHEMA.batch_status cascade constraints purge;

create table FRAMEWORK_SCHEMA.batch_status
(
  name                     varchar2(150)   not null,
  version                  integer              not null,
  start_date               date                     null,
  end_date                 date                     null,
  nr_of_error              integer                  null,
  nr_business_transaction  integer                  null,
  message                  varchar2(1000)      null,
  host                     VARCHAR2(100)   DEFAULT 'NA',
  hour generated always as (round((end_date-start_date)*24,1)),
  min  generated always as (round((end_date-start_date)*60*24,0)),
  sec  generated always as (round((end_date-start_date)*60*60*24,2)),
  constraint xpkbatch_status primary key (name, version)
);
/
comment on column FRAMEWORK_SCHEMA.batch_status.hour is 'The number of hours.';
comment on column FRAMEWORK_SCHEMA.batch_status.min is 'The number of minutes.';
comment on column FRAMEWORK_SCHEMA.batch_status.sec is 'The number of seconds.';

drop table FRAMEWORK_SCHEMA.r_table_def cascade constraints purge;
create table FRAMEWORK_SCHEMA.r_table_def
(
  id               number(38),
  table_name       varchar2(100)           not null,
  table_kind       varchar2(100)           not null,
  column_name      varchar2(100)           not null,
  valid_value      varchar2(250),
  row_creator      varchar2(40),
  row_create_date  date,
  updator          varchar2(40),
  update_date      date
);
CREATE UNIQUE INDEX SDE_IT.PK_r_table_def ON SDE_IT.R_TABLE_DEF
(TABLE_NAME, TABLE_KIND, COLUMN_NAME);

----
drop table FRAMEWORK_SCHEMA.tab_variable cascade constraints purge;
create table FRAMEWORK_SCHEMA.tab_variable
(
  id               number(38) not null,
  category         varchar2(100)           not null,
  key              varchar2(100)           not null,
  valid_value      varchar2(250) default 'NA' not null,
  isactive         integer default 1 not null check(isactive in (0,1)),
  xcomment         varchar2(300),
  st_created_by    varchar2(40)  not null,
  st_created_date  timestamp(6) /*with time zone*/ not null,
  st_updated_by     varchar2(40),
  st_updated_date   timestamp(6) /*with time zone*/,
 constraint xpktab_variable primary key (id)  
);

CREATE UNIQUE INDEX FRAMEWORK_SCHEMA.UNK_tab_variable ON FRAMEWORK_SCHEMA.tab_variable
(category,key);

----

create table FRAMEWORK_SCHEMA.client_version
(
  logon_time      date,
  sid             number,
  serial#         number,
  machine         varchar2(64),
  program         varchar2(48),
  client_version  varchar2(40),
  osuser          varchar2(30),
  client_driver   varchar2(30),
  client_charset  varchar2(40),
  module          varchar2(64),
  status          varchar2(3)
);

create unique index FRAMEWORK_SCHEMA.indx_client_version_pk 
   on FRAMEWORK_SCHEMA.client_version(logon_time, sid, serial#);

alter table FRAMEWORK_SCHEMA.client_version add (
  constraint FRAMEWORK_SCHEMA.indx_client_version_pk  primary key
  (logon_time, sid, serial#)
  using index indx_client_version_pk
  );
  
comment on table FRAMEWORK.client_version is 'select distinct machine, program, client_version, osuser, module, status
from FRAMEWORK.client_version
where status like ''%FIX%'' and client_version not like ''%Unknown%''
order by status desc;

select logon_time,machine, program, client_version, osuser, module, status
from FRAMEWORK.client_version
where status like ''%FIX%'' and client_version not like ''%Unknown%''
order by logon_time desc,status desc;';
  
--=====================

--***************************************************************
--Sequences
--***************************************************************
DROP SEQUENCE FRAMEWORK_SCHEMA.ITOPPSEQ;

--
-- ITOPPSEQ  (Sequence) 
--
CREATE SEQUENCE FRAMEWORK_SCHEMA.ITOPPSEQ
  START WITH 1
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER
  NOKEEP
  GLOBAL;

--***************************************************************
--Triggers
--***************************************************************
create or replace trigger FRAMEWORK_SCHEMA.tiud_user_administration
   before insert or update or delete
   on FRAMEWORK_SCHEMA.user_administration
   for each row
begin   
   if inserting then
     :new.st_created_by := user;
     :new.st_created_date := sys_extract_utc(current_timestamp);
   elsif updating then
    :new.st_updated_by := user;
    :new.st_updated_date := sys_extract_utc(current_timestamp);
   elsif deleting then
      null;
      --raise_application_error(-20003,SDE_IT.errorhandler.getMessage(20,'Illegal to delete.'));
   end if;
end trigger;
/

create or replace trigger FRAMEWORK_SCHEMA.tiu_tab_variable
   before insert or update
   on FRAMEWORK_SCHEMA.tab_variable
   for each row
begin   
   if inserting then
     :new.id := itoppseq.nextval;
     :new.category := upper(:new.category);
     :new.key := upper(:new.key);
     :new.st_created_by := user;
     :new.st_created_date := sys_extract_utc(current_timestamp);
   elsif updating then
     if (:new.category != :old.category) then 
        --U SERERROR(18,'Category','TAB_VARIABLE');
        raise_application_error(-20003,SDE_IT.errorhandler.getMessage(18,'Category','TAB_VARIABLE'));
     end if;
    :new.st_updated_by := user;
    :new.st_updated_date := sys_extract_utc(current_timestamp);
   end if;
end trigger;
/


CREATE_TRIGGER(FRAMEWORK_SCHEMA.tiu_cleanuptableinfo)
   before insert or update
   on FRAMEWORK_SCHEMA.cleanuptableinfo
   for each row
declare
   STANDARD_VARIABLE;
   lCount int := 0;   
begin   
   :new.appname := trim(:new.appname);
   :new.columnappname := trim(:new.columnappname);
   :new.tabname := trim(:new.tabname);
   :new.synccolumn := trim(:new.synccolumn);

   if (upper(:new.tabname) = upper('cleanuptableinfo') ) then
      USERERROR(20,'Illegal to register table "cleanuptableinfo".');
   end if;

   if inserting then
      :new.created_by := user;
      :new.created_date := sys_extract_utc(current_timestamp);
      select count(*) into lCount
         from user_tables
         where table_name = upper(:new.tabname);
      if (lCount != 1) then
         USERERROR(12,:new.tabname);
      end if;
   elsif updating then 
    :new.updated_by := user;
    :new.updated_date := sys_extract_utc(current_timestamp);
   end if;
END_TRIGGER;
/

-----------------------------------------------------------------------
create or replace trigger FRAMEWORK_SCHEMA.tiu_t_basis_clientmessage
   before insert or update
   on FRAMEWORK_SCHEMA.t_basis_clientmessage
   for each row
begin   
   if inserting then
      select to_char (itoppseq.nextval)
        into :new.clientmessage_s
        from sys.dual;
     :new.row_creator := user;
     :new.row_create_date := sysdate;
   elsif updating then 
    :new.clientmessage_s := :old.clientmessage_s;
    :new.updator := user;
    :new.update_date := sysdate;
   end if;
end trigger;
/

-----------------------------------------------------------------------
create or replace trigger FRAMEWORK_SCHEMA.ti_r_table_def
   before insert
   on FRAMEWORK_SCHEMA.r_table_def
   for each row
begin   
   if inserting then
     select to_char (itoppseq.nextval)
        into :new.id
        from sys.dual;
    :new.row_creator := user;
    :new.row_create_date := sysdate;
   end if;
end trigger;
/
-----------------------------------------------------------------------
create or replace trigger FRAMEWORK_SCHEMA.tiu_t_basis_clienterrorlog
   before insert or update
   on FRAMEWORK_SCHEMA.t_basis_clienterrorlog
   for each row
begin   
   if inserting then
      select to_char (itoppseq.nextval)
        into :new.clienterrorlog_s
        from sys.dual;
      :new.row_creator := user;
      :new.row_create_date := sysdate;
      :new.dateregistered := sysdate;
   elsif updating then
      :new.clienterrorlog_s := :old.clienterrorlog_s;
      :new.updator := user;
      :new.update_date := sysdate;
   end if;
end trigger;
/
-----------------------------------------------------------------------
create or replace trigger sde_it.tiu_R_TABLE_DEF
   before insert or update
   on sde_it.R_TABLE_DEF
   for each row
begin   
   if inserting then
      :new.id := itoppseq.nextval;
      :new.row_creator := user;
      :new.row_create_date := sysdate;
   elsif updating then
      :new.updator := user;
      :new.update_date := sysdate;
   end if;
end trigger;
/

CREATE_TRIGGER(tc_dba_audit_hist)
   for insert or update
   on FRAMEWORK_SCHEMA.dba_audit_hist
   --follows [trigger]   
   compound trigger    
/*****************************************************************
* Trigger info:
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 22.09.2022 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: $
* Description     :  $
* Revision History: $Revision: 1.1 $
* Workfile        : $Workfile: $
* Copyright       : Equinor ASA
*****************************************************************
* Description
* 
*****************************************************************
* Log
* Date   Description					 Done by
*
*****************************************************************/
   STANDARD_VARIABLE;

   ---------------------------------------------------------------
   -- Variables
   ---------------------------------------------------------------
   lReportDate date;
   
   ---------------------------------------------------------------
   -- Section for procedures and functions
   ---------------------------------------------------------------

   ---------------------------------------------------------------
   -- This is for tables. View related timing states to be removed
   ---------------------------------------------------------------
   before statement
   is
   begin
      select max(report_day) into lReportDate 
         from FRAMEWORK_SCHEMA.dba_audit_hist;
   end before statement;
--
   before each row 
   is
   begin
      if (inserting or updating) then
         if (lReportDate = :new.report_day) then
            USERERROR(20,'Error: Data for '||to_date(lReportDate,'dd.mm.yyyy')||' already loaded.');
         end if;
      end if;
   end before each row ;

/*   after each row 
      is
   begin
     null;
   end after each row ;

   after statement
   is
   begin
     null;   
   end after statement;
*/   
end; 
/

CREATE OR REPLACE TRIGGER tiu_PROCESSING_SCRIPT
  before insert or update
  on PROCESSING_SCRIPT
  for each row
declare
/*****************************************************************
*  Package Info
*   Author          : $Author:  $
*   Original Date   : $Date:  $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
*  Maintains the create and update columns in the table.
* System_name and container_name are mutually exclusive.
*****************************************************************
* Log
* Date   Description                                        Done by
* 240812 Only top level containers may have scripts attached JOTHOR
*****************************************************************/
    z_version varchar2(200) := '';
  z_isLogged boolean := false;
  z_status number := 0;
  z_errorText varchar2(255) := null;
  z_errorDate date := null ;
  lCount int := 0;
begin
  if (inserting or updating) then
    if (:new.system_name is not null and :new.container_name is not null) then
       null; -- Ok
    elsif (:new.system_name is null or :new.container_name is null) then
      z_errorText :=  substr('tiu_PROCESSING_SCRIPT: ' || SDE_IT.errorhandler.getMessage(11 ,'system_name or container_name but not both ,'    ),1,255);   z_errorDate := sysdate;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
    end if;
  end if;

  --goto le_end_goto;<<le_finish_goto>> null;<<le_end_goto>> null;
 exception
     when others then
    -- Start throw exception
    null;
    if (SQLCODE in (-20003,-20002,-20001)) then
      raise;
    end if;
    z_status := SQLCODE;
    z_errorText :=  substr('tiu_PROCESSING_SCRIPT: ' || SDE_IT.errorhandler.getMessage(20 ,SQLERRM     ),1,255);   z_errorDate := sysdate;    z_isLogged:=false;   raise_application_error(-20001,z_errorText);
end trigger  ;
/

CREATE OR REPLACE TRIGGER taud_PROCESSING_SCRIPT
  before insert or update
  on PROCESSING_SCRIPT
  for each row
declare
/*****************************************************************
* Audit trigger
*  Package Info
*   Author          : $Author:  $
*   Original Date   : $Date:  $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
*  Maintains the create and update columns in the table.
*
*****************************************************************
* Log
* Date   Description                  Done by
* 170812 Illegal to alter "create" information once data   JOTHOR
*  has been entered.
*****************************************************************/
    z_version varchar2(200) := '';
  z_isLogged boolean := false;
  z_status number := 0;
  z_errorText varchar2(255) := null;
  z_errorDate date := null ;
begin
  if (inserting) then
    :new.created_by := user;
    :new.created_date := sys_extract_utc(current_timestamp);
  elsif (updating) then
    if (:new.created_by is null or :new.created_by <> :old.created_by) then
       z_errorText :=  substr('taud_PROCESSING_SCRIPT: ' || SDE_IT.errorhandler.getMessage(19 ,'created_by' ,'XUSER'    ),1,255);   z_errorDate := sysdate;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
    elsif (:new.created_date is null or :new.created_date <> :old.created_date) then
       z_errorText :=  substr('taud_PROCESSING_SCRIPT: ' || SDE_IT.errorhandler.getMessage(19 ,'created_date' ,'XUSER'    ),1,255);   z_errorDate := sysdate;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
    elsif (:old.updated_date is null and :new.updated_date is null) then
       null; -- ok, this handles the first time the row is updated.
    elsif (:new.updated_date is null) then
       z_errorText :=  substr('taud_PROCESSING_SCRIPT: ' || SDE_IT.errorhandler.getMessage(11 ,'updated_date' ,'XUSER'    ),1,255);   z_errorDate := sysdate;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);  -- must supply
    elsif (:new.updated_date <> :old.updated_date) then
       z_errorText :=  substr('taud_PROCESSING_SCRIPT: ' || SDE_IT.errorhandler.getMessage(19 ,'updated_date' ,'XUSER'    ),1,255);   z_errorDate := sysdate;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
    end if;

    :new.updated_by := user;
    :new.updated_date := sys_extract_utc(current_timestamp);
  end if;

  --goto le_end_goto;<<le_finish_goto>> null;<<le_end_goto>> null;
 exception
     when others then
    -- Start throw exception
    null;
    if (SQLCODE in (-20003,-20002,-20001)) then
      raise;
    end if;
    z_status := SQLCODE;
    z_errorText :=  substr('taud_PROCESSING_SCRIPT: ' || SDE_IT.errorhandler.getMessage(20 ,SQLERRM     ),1,255);   z_errorDate := sysdate;    z_isLogged:=false;   raise_application_error(-20001,z_errorText);
end trigger  ;
/

--
-- SEQ_PROCESSING_SCRIPT  (Sequence) 
--
CREATE SEQUENCE SEQ_PROCESSING_SCRIPT
  START WITH 0
  MAXVALUE 9999999999999999999999999999
  MINVALUE 0
  NOCYCLE
  NOCACHE
  NOORDER
  NOKEEP
  GLOBAL;

CREATE OR REPLACE TRIGGER t_idPROCESSING_SCRIPT
  before insert or update
  on PROCESSING_SCRIPT
  for each row
declare
/*****************************************************************
*  Package Info
*   Author          : $Author:  $
*   Original Date   : $Date:  $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
*  Maintains the id column in the table.
*
*****************************************************************/
    z_version varchar2(200) := '';
  z_isLogged boolean := false;
  z_status number := 0;
  z_errorText varchar2(255) := null;
  z_errorDate date := null ;
begin
  if (inserting) then
    :new.id := seq_PROCESSING_SCRIPT.nextval;
  elsif (updating and :new.id != :old.id) then
    z_errorText :=  substr('t_idPROCESSING_SCRIPT: ' || SDE_IT.errorhandler.getMessage(18 ,'id' ,'PROCESSING_SCRIPT'    ),1,255);   z_errorDate := sysdate;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
  end if;

  --goto le_end_goto;<<le_finish_goto>> null;<<le_end_goto>> null;
 exception
     when others then
    -- Start throw exception
    null;
    if (SQLCODE in (-20003,-20002,-20001)) then
      raise;
    end if;
    z_status := SQLCODE;
    z_errorText :=  substr('t_idPROCESSING_SCRIPT: ' || SDE_IT.errorhandler.getMessage(20 ,SQLERRM     ),1,255);   z_errorDate := sysdate;    z_isLogged:=false;   raise_application_error(-20001,z_errorText);
end trigger  ;
/


--***************************************************************
-- Preload data
-- SDE_IT message codes reserved below 100 (not including 100).
-- All system specific messages should come from 100 onwards
--***************************************************************
Insert into FRAMEWORK_SCHEMA.CLEANUPTABLEINFO(appname, tabname, message, days, synccolumn, isactive, columnappname)
   Values('NA', 't_basis_clienterrorlog', NULL, 10, 'row_create_date', 1, 'NA');
Insert into FRAMEWORK_SCHEMA.CLEANUPTABLEINFO(appname, tabname, message, days, synccolumn,isactive, columnappname)
   Values('NA', 'process_information_history', NULL, 90, 'start_time', 1, 'NA');
Insert into FRAMEWORK_SCHEMA.CLEANUPTABLEINFO(appname, tabname, message, days, synccolumn, isactive, columnappname)
   Values('NA', 'runlog', NULL, 90, 'start_date', 0, 'NA');
Insert into FRAMEWORK_SCHEMA.CLEANUPTABLEINFO(appname, tabname, message, days, synccolumn, isactive, columnappname)
   Values('NA', 'table_lock_history', NULL, 60, 'start_time', 1, 'NA');
Insert into FRAMEWORK_SCHEMA.CLEANUPTABLEINFO(appname, tabname, message, days, synccolumn, isactive, columnappname)
   Values('NA', 'sync_state', NULL, 60, 'start_time', 0, 'NA');
Insert into FRAMEWORK_SCHEMA.CLEANUPTABLEINFO(appname, tabname, message, days, synccolumn, isactive, columnappname)
   Values('NA', 'compress_log', NULL, 10, 'compress_start', 1, 'NA');
Insert into FRAMEWORK_SCHEMA.CLEANUPTABLEINFO(appname, tabname, message, days, synccolumn, isactive, columnappname)
   Values('NA', 'client_version', NULL, 10, 'logon_time', 1, 'NA');


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
comment on table FRAMEWORK_SCHEMA.t_basis_clientmessage is 'ARC explanation of paramenters for code #30
  1: current table, 2: table with discriminator, 3: discriminator column in table #2, 4: discriminator value
  Table (1)procurement_exp violates Arc constraint on Table (2)procurement - discriminator column (3)procurement_type doesn''t have value (4)''EXP''.');

-----------------------------------------------------------------------
-- SMTP_SERVER_OUT mailhost.statoil.no
-- SMTP_PORT_OUT defaults are amongst others: 25, 465, 587, 2525
-- SMTP_DOMAIN
-----------------------------------------------------------------------
insert into FRAMEWORK_SCHEMA.R_TABLE_DEF(table_name,table_kind,column_name,valid_value) values('SMTP_MAIL','MAILSERVER','SMTP_SERVER_OUT','mailhost.statoil.no');
insert into FRAMEWORK_SCHEMA.R_TABLE_DEF(table_name,table_kind,column_name,valid_value) values('SMTP_MAIL','MAILSERVER','SMTP_PORT_OUT','25');
insert into FRAMEWORK_SCHEMA.R_TABLE_DEF(table_name,table_kind,column_name,valid_value) values('SMTP_MAIL','MAILSERVER','SMTP_DOMAIN','NA');
commit;


-- NOTE: Remember to update the system name in SYSTEM_DETAIL.
insert into FRAMEWORK_SCHEMA.tab_variable(category,key,xcomment) values ('SYSTEM_DETAIL','NAME','This is the of the system e.g.IRIS21');
insert into FRAMEWORK_SCHEMA.tab_variable(category,key,valid_value,xcomment) values ('SYSTEM_DETAIL','DELIMITER',';','Delimiter to use separating the chain of datasources.');
insert into FRAMEWORK_SCHEMA.tab_variable(category,key,valid_value,xcomment) values ('SYSTEM_DETAIL','MAX_DATASOURCE_SET',5,'The max number of datasources in the chain. Those exceeding are removed from the chain.');
commit;





--***************************************************************
-- Initiate jobs
-- to_date('04.11.2008 18:00:00','dd/mm/yyyy hh24:mi:ss')
--***************************************************************
set define on
set feed on
define lJobName = '/*cleanup userlogs*/FRAMEWORK_SCHEMA.CleanupLogTable;';

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
/
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
/
commit;

/*define lJobName = '/ *cleanup userlogs* /FRAMEWORK_SCHEMA.cleanupTableLockHist;';

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
/
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
*/

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


