------------------------------------------------------------------
-- Package Info
-- Author          : $Author: JOTHOR $
-- Original datetime   : $datetime: 2007/03/23 $
-- Last Modified   : $Modtime:  $
-- Archive Name    : $Archive:  $
-- Description     : $Header:  $
-- Revision History: $Revision:  $
-- Workfile        : $Workfile:  $
-- Copyright info  : Copyright (c), Equinor ASA,Norway. $datetime: 2007/03/23 13:46:23 $
------------------------------------------------------------------
-- Description
--
------------------------------------------------------------------
-- LOG
-- datetime   Description							                  Done by
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
--    st_dataset now type "datetime" and default current_timestamp.
-- 171122 Added table PROCESSING_SCRIPT and supporting      JOTHOR
--    elements
-- 060123 Added new messages 31-33 "Addtional data..."      JOTHOR
-- 030223 Added new message 34 "No data found..."           JOTHOR
-- 120623 Added table Applicationmessage                    JOTHOR
-- 130623 Added ADDITIONAL_CONDITION to cleanUpLogTable     JOTHOR
-- 260923 Added "maildistribution" and applicationmessage   JOTHOR
--    setup
------------------------------------------------------------------

/* --Populate 
merge into user_administration ud
  USING (select
      case when account_status='OPEN' then
         current_datetime
      else
         null
      end as xopen 
      ,case when account_status='LOCKED' then
         lock_datetime
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
   when matched then updatetime set ud.open_datetime=u.xopen
                                ,ud.lock_datetime=u.xlock
                                ,isSystemUser = u.isSystemUser
   when not matched then insert(username,open_datetime,lock_datetime,isSystemUser)
      values(u.username,u.xopen,u.xlock,u.isSystemUser)
*/

create table FRAMEWORK_SCHEMA.dba_audit_hist
(
  os_username   nvarchar(255),
  username      nvarchar(128),
  current_user  nvarchar(128),
  owner         nvarchar(128),
  obj_name      nvarchar(128),
  action_name   nvarchar(28),
  report_day    datetime,
  cnt           integer
);

--drop table FRAMEWORK_SCHEMA.user_administration; 
create table FRAMEWORK_SCHEMA.user_administration(
    username nvarchar(100)
   ,lock_datetime datetime
   ,open_datetime datetime
   ,isSystemUser integer default 0 check (isSystemUser in (0,1))
   ,st_created_by nvarchar(100) not null default 'NA'
   ,st_created_datetime datetime not null default convert([datetime],'1970-01-01',(102))
   ,st_updatetimed_by nvarchar(100)
   ,st_updatetimed_datetime datetime
);

------------------------------------------------------------------
-- Transit table for AccessIT csv data
-- Note: when using "sqlldr" include "TRAILING NULLCOLS" in the
-- control file. This due to the column "st_dataset" not in the data file.
------------------------------------------------------------------
--drop table FRAMEWORK_SCHEMA.accessit_data cascade constraints purge;
create table FRAMEWORK_SCHEMA.accessit_data
(
  full_name         nvarchar(100)
  ,short_name        nvarchar(50)
  ,employee_no       nvarchar(50)
  ,contract_datetime nvarchar(200)
  ,organization      nvarchar(200)
  ,position          nvarchar(200)
  ,business_process  nvarchar(200)
  ,access_type       nvarchar(50)
  ,xaccess           nvarchar(100)
  ,xrole             nvarchar(100)
  ,valid_to          nvarchar(50)
  ,yearly_cost_nok   nvarchar(20)
  ,st_dataset        datetime default current_timestamp
);

------------------------------------------------------------------
-- Processing_script  (table) 
------------------------------------------------------------------
create table FRAMEWORK_SCHEMA.processing_script
(
  id                integer                     not null
  ,system_name       nvarchar(100)
  ,container_name    nvarchar(100)
  ,pre_create        nvarchar(4000)
  ,pre_create_type   nvarchar(30)           default 'sql'
  ,post_create       nvarchar(4000)
  ,post_create_type  nvarchar(30)           default 'sql'
  ,pre_delete        nvarchar(4000)
  ,pre_delete_type   nvarchar(30)           default 'sql'
  ,post_delete       nvarchar(4000)
  ,post_delete_type  nvarchar(30)           default 'sql'
  ,created_by        nnvarchar(75)
  ,created_datetime  datetime2
  ,updatetimed_by    nnvarchar(75)
  ,updatetimed_datetime      datetime2
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
    appname nvarchar(130) default 'NA' not null
   ,columnappname nvarchar(130) default 'NA' not null
   ,tabname nvarchar(60) not null
   ,message nvarchar(130)
   ,days integer  not null
   ,synccolumn nvarchar(60)  not null
   ,isactive integer default 0   not null
   ,additional_condition  nvarchar(1000)
   ,created_by nvarchar(50) not null
   ,created_datetime timestamp not null
   ,updatetimed_by nvarchar(50)
   ,updatetimed_datetime timestamp
   ,constraint pk_cleanuptableinfo
     primary key
     (appname,tabname)
   ,constraint con_isactive
     check (isactive in ( 0,1))
   ,constraint con_nr_days
     check (days >= 0)
);
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.tabname is 'The table to be processed (in this schema).';
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.columnappname is 'The column name within the table ("tabname") on which "appname" resides.';
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.isactive is 'Whether or not this entry is active (1) or not (0).';
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.appname  is 'The application to sync on. See also "message".';
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.message is 'Sometimes the message contains sync information.';
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.days is 'Number of days before processing is to take place.';
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.syncColumn is 'The column to sync on. The column is to be of type datetime/timestamp.';
comment on column FRAMEWORK_SCHEMA.cleanUpTableInfo.ADDITIONAL_CONDITION is 'This is addition to the current where clause. Start with "and/or/(".';
----------------------------------------
-- COMPRESS_LOG  (Table) 
----------------------------------------
--drop table FRAMEWORK_SCHEMA.compress_log cascade constraints purge;
create table FRAMEWORK_SCHEMA.compress_log
(
  sde_id             integer                    not null
  ,server_id          integer                    not null
  ,direct_connect     nvarchar(1 )
  ,compress_start     datetime
  ,start_state_count  integer
  ,compress_end       datetime
  ,end_state_count    integer
  ,compress_status    nvarchar(20 )
  ,owner              nvarchar(75 )
  ,nodename           nvarchar(100 )
);

-----------------------------------------------------
-- Jobs can have a fault tolerance before reporting an
-- error. The table epsilon can be used to set boundaries
-- for such.
-- Note the defaults
-----------------------------------------------------
--drop table FRAMEWORK_SCHEMA.epsilon cascade constraints purge;;

create table FRAMEWORK_SCHEMA.epsilon(
  name nvarchar(100) not null
 ,lower float default -1 not null
 ,lower_unit nvarchar(50) default 'NA' not null check(lower_unit in ('absolute','procent','NA'))
 ,upper float default -1 not null
 ,upper_unit nvarchar(50) default 'NA' not null check(upper_unit in ('absolute','procent','NA'))
 );
 ALTER TABLE FRAMEWORK_SCHEMA..EPSILON ADD CONSTRAINT pk_epsilon PRIMARY KEY (NAME);
 
comment on table epsilon is 'Intended for jobs so as to allow to evaluate whether or not to flag an error. 
If no limit is to be imposed, set value to -1 and unit to "NA". These are also the default values.
NOTE: defaults in place.';
comment on column epsilon.lower is 'The lower tolerance permitted. A negative number indicates infinity.';
comment on column epsilon.lower_unit is 'The lower_unit tolerance e.g procent.';
comment on column epsilon.upper_unit is 'The upper_unit tolerance e.g procent.';
comment on column epsilon.upper is 'The upper tolerance permitted. A negative number indicates infinity';



-----------------------------------------------------
-- t_basis_clienterrorlog  (table) 
-- should clientmessage_s be number rather than nvarchar(19)
-----------------------------------------------------
drop table FRAMEWORK_SCHEMA.t_basis_clienterrorlog cascade constraints purge;

create table FRAMEWORK_SCHEMA.t_basis_clienterrorlog
(
  clienterrorlog_s      nvarchar(19)    not null
  ,logid                integer
  ,userregistered       nvarchar(40)
  ,datetimeregistered   datetime
  ,messagecode          nvarchar(13)
  ,messagetext          nvarchar(4000)
  ,dberrorcode          integer
  ,dberrortext          nvarchar(255)
  ,objecterroroccurred  nvarchar(40)
  ,rowerroroccurred     integer
  ,applicationname      nvarchar(150)
  ,applicationversion   nvarchar(50)
  ,description          nvarchar(255)
  ,host                 nvarchar(255) default 'NA'
  ,st_created_by nvarchar(100) not null default 'NA'
  ,st_created_datetime datetime not null default convert([datetime],'1970-01-01',(102)) 
  ,st_updated_by nvarchar(100)
  ,st_updated_by       datetime 
  ,constraint xpkt_basis_clienterrorlog primary key (clienterrorlog_s)
);

comment on table FRAMEWORK_SCHEMA.t_basis_clienterrorlog is 'To list errors for a particular batch job:
select *
from FRAMEWORK_SCHEMA.t_basis_clienterrorlog l
  inner join FRAMEWORK_SCHEMA.batch_status b
  on l.datetimeregistered between b.start_datetime and b.end_datetime
where b.name = ''cleanUpTransitTable''
order by l.datetimeregistered;'

-----------------------------------------------------
-- t_basis_clientmessage  (table) 
-----------------------------------------------------
drop table FRAMEWORK_SCHEMA.t_basis_clientmessage cascade constraints purge;

create table FRAMEWORK_SCHEMA.t_basis_clientmessage
(
  clientmessage_s  nvarchar(19)  not null
  ,messagecode      nvarchar(13) not null
  ,messagetype      nvarchar(1) 
  ,messagetext      nvarchar(255) not null
  ,titletext        nvarchar(40)
  ,iconcode         float(126)
  ,buttoncode       float(126)
  ,logerror         float(126)
  ,application      nvarchar(100)  default 'GLOBAL'
  ,description      nvarchar(255)
  ,st_created_by nvarchar(100) not null default 'NA'
  ,st_created_datetime datetime not null default convert([datetime],'1970-01-01',(102)) 
  ,st_updated_by nvarchar(100)
  ,st_updated_by       datetime 
  ,constraint xpkt_basis_clientmessage  primary key (clientmessage_s)
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
  name                     nvarchar(150)   not null
  ,version                  integer              not null
  ,start_datetime           datetime
  ,end_datetime             datetime
  ,nr_of_error              integer
  ,nr_business_transaction  integer
  ,message                  nvarchar(1000)
  ,host                     nvarchar(100)   default 'NA'
  ,hour generated always as (round((end_datetime-start_datetime)*24,1))
  ,min  generated always as (round((end_datetime-start_datetime)*60*24,0))
  ,sec  generated always as (round((end_datetime-start_datetime)*60*60*24,2))
  ,constraint xpkbatch_status primary key (name, version)
);
/
comment on column FRAMEWORK_SCHEMA.batch_status.hour is 'The number of hours.';
comment on column FRAMEWORK_SCHEMA.batch_status.min is 'The number of minutes.';
comment on column FRAMEWORK_SCHEMA.batch_status.sec is 'The number of seconds.';

drop table FRAMEWORK_SCHEMA.r_table_def cascade constraints purge;
create table FRAMEWORK_SCHEMA.r_table_def
(
  id               number(38)
  ,table_name       nvarchar(100)           not null
  ,table_kind       nvarchar(100)           not null
  ,column_name      nvarchar(100)           not null
  ,valid_value      nvarchar(250)
  ,st_created_by nvarchar(100) not null default 'NA'
  ,st_created_datetime datetime not null default convert([datetime],'1970-01-01',(102)) 
  ,st_updated_by nvarchar(100)
  ,st_updated_by       datetime 
);
CREATE UNIQUE INDEX FRAMEWORK_SCHEMA.PK_r_table_def ON FRAMEWORK_SCHEMA.R_TABLE_DEF
(TABLE_NAME, TABLE_KIND, COLUMN_NAME);

----
drop table FRAMEWORK_SCHEMA.tab_variable cascade constraints purge;
create table FRAMEWORK_SCHEMA.tab_variable
(
  id               number(38) not null
  ,category         nvarchar(100)           not null
  ,key              nvarchar(100)           not null
  ,valid_value      nvarchar(250) default 'NA' not null
  ,isactive         integer default 1 not null check(isactive in (0,1))
  ,xcomment         nvarchar(300)
  ,st_created_by    nvarchar(40)  not null
  ,st_created_datetime  datetime2 /*with time zone*/ not null
  ,st_updatetimed_by     nvarchar(40)
  ,st_updatetimed_datetime   datetime2 /*with time zone*/
  ,constraint xpktab_variable primary key (id)  
);

CREATE UNIQUE INDEX FRAMEWORK_SCHEMA.UNK_tab_variable ON FRAMEWORK_SCHEMA.tab_variable
(category,key);

----

create table FRAMEWORK_SCHEMA.client_version
(
  logon_time      datetime
  ,sid             number
  ,serial#         number
  ,machine         nvarchar(64)
  ,program         nvarchar(48)
  ,client_version  nvarchar(40)
  ,osuser          nvarchar(30)
  ,client_driver   nvarchar(30)
  ,client_charset  nvarchar(40)
  ,module          nvarchar(64)
  ,status          nvarchar(3)
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

------------
drop table FRAMEWORK_SCHEMA.applicationmessage;
create table FRAMEWORK_SCHEMA.applicationmessage
(
  st_id     integer not null
  ,xcode   varchar(70) not null
  ,xsubject nvarchar(255) not null
  ,xmessage  nclob not null
  ,xcomment  nvarchar(255 )
  ,xtype     nvarchar(255 )
  ,isactive char(1) default 'N' not null  check (isactive in ('N','Y'))
  ,st_created_by varchar(100) not null
  ,st_created_datetime datetime not null default convert([datetime],'1970-01-01',(102)) not null
  ,st_updatetimed_by varchar(100)  null
  ,st_updatetimed_datetime datetime  null 
);

comment on table FRAMEWORK_SCHEMA.applicationmessage is 'Useful for email contents.';

create unique index FRAMEWORK_SCHEMA.applicationmessage_unq on FRAMEWORK_SCHEMA.applicationmessage
(xcode);

create unique index FRAMEWORK_SCHEMA.applicationmessage_pk on FRAMEWORK_SCHEMA.applicationmessage
(st_id);

alter table FRAMEWORK_SCHEMA.applicationmessage add (
  constraint applicationmessage_pk
  primary key
  (st_id)
  using index FRAMEWORK_SCHEMA.applicationmessage_pk);

alter table FRAMEWORK_SCHEMA.applicationmessage add (
  constraint applicationmessage_unq
  unique (xcode)
  using index FRAMEWORK_SCHEMA.applicationmessage_unq);

create or replace trigger FRAMEWORK_SCHEMA.tiu_applicationmessage
   before insert or updatetime
   on FRAMEWORK_SCHEMA.applicationmessage
   for each row
declare
    z_version nvarchar(200) := '';
  z_isLogged boolean := false;
  z_status number := 0;
  z_errorText nvarchar(255) := null;
  z_errordatetime datetime := null ;   
begin
   if inserting then
     select itoppseq.nextval
        into :new.st_id
        from sys.dual;
    --:new.st_created_by := user;
    --:new.st_created_datetime := current_timestamp;
    :new.xcode := trim(lower(:new.xcode));
   elsif updating then
      if (:new.st_id != :old.st_id) then
       z_errorText :=  substr('tiu_APPLICATIONMESSAGE: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(18,'st_id,','APPLICATIONMESSAGE'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
       --U SERERROR(18,'ST_ID,','APPLICATIONMESSAGE');
      elsif (:new.xcode != :old.xcode) then
       z_errorText :=  substr('tiu_APPLICATIONMESSAGE: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(18,'xcode,','APPLICATIONMESSAGE'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
       --U SERERROR(18,'ST_ID,','APPLICATIONMESSAGE');
      end if;
     :new.st_updatetimed_by := user;
     :new.st_updatetimed_datetime := current_timestamp;    
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
    z_errorText :=  substr('tiu_applicationmessage: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(20 ,SQLERRM     ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20001,z_errorText);
end trigger  ;
/

create or replace trigger FRAMEWORK_SCHEMA.taud_applicationmessage
    before insert or updatetime
    on applicationmessage
    for each row
declare
/*****************************************************************
* Audit trigger
*  Package Info
*   Author          : $Author:  $
*   Original datetime   : $datetime:  $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*   Copyright       : $Equinor ASA $
*****************************************************************
* Description
*  Maintains the create and updatetime columns in the table.
*
* Could extend auditing by including
*  os-user (255 char) -  sys_context('userenv','os_user')
*  os-host (128 char) -  sys_context('userenv','host')
* Why? ths "user" is not always the actual user. Using "os-user"
* pinpoint the user who is logged in on the PC. This user may use
* a common login user (e.g RBAC) thereby camouflaging their identify.
*****************************************************************
* Log
* datetime   Description                        Done by
* 170812 Illegal to alter "create" information once data    JOTHOR
*  has been entered.
*****************************************************************/
     z_version nvarchar(200) := '';
  z_isLogged boolean := false;
  z_status number := 0;
  z_errorText nvarchar(255) := null;
  z_errordatetime datetime := null ;
begin
   if (inserting) then
      :new.st_created_by   := user;
      :new.st_created_datetime := sys_extract_utc(current_timestamp);
      :new.st_updatetimed_by   := null;
      :new.st_updatetimed_datetime := null;
   elsif (updating) then
      if (:new.st_created_by is null or :new.st_created_by <> :old.st_created_by) then
         z_errorText :=  substr('taud_applicationmessage: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(19  ,'st_created_by'  ,'XUSER'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
          --U SERERROR(19,'st_created_by,','APPLICATIONMESSAGE');
      elsif (:new.st_created_datetime is null or :new.st_created_datetime <> :old.st_created_datetime) then
         z_errorText :=  substr('taud_applicationmessage: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(19  ,'st_created_datetime'  ,'XUSER'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
         --U SERERROR(19,'st_created_datetime,','APPLICATIONMESSAGE');
      elsif (:old.st_updatetimed_datetime is null and :new.st_updatetimed_datetime is null) then
         null; /* ok, this handles the first time the row is updatetimed.*/
/* This is wrong!     elsif (:new.st_updatetimed_datetime is null) then
         z_errorText :=  substr('taud_applicationmessage: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(11  ,'st_updatetimed_datetime'  ,'XUSER'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
         --U SERERROR(11,'st_updatetimed_datetime,','APPLICATIONMESSAGE');
*/      elsif (:new.st_updatetimed_datetime <> :old.st_updatetimed_datetime) then
         z_errorText :=  substr('taud_applicationmessage: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(19  ,'st_updatetimed_datetime'  ,'XUSER'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
         --U SERERROR(19,'st_updatetimed_datetime,','APPLICATIONMESSAGE');
      end if;

      :new.st_updatetimed_by := user;
      :new.st_updatetimed_datetime := sys_extract_utc(current_timestamp);
   end if;

--goto le_end_goto;<<le_finish_goto>> null;<<le_end_goto>> null;
 exception    when others then
    -- Start throw exception
    FRAMEWORK_SCHEMA.errorhandler.debug(4,'0:'||'Throw exception:'||SQLERRM);
    if (SQLCODE in (-20003,-20002,-20001)) then
      raise;
    end if;
    z_status := SQLCODE;
    z_errorText :=  substr('taud_applicationmessage: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(20 ,SQLERRM     ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20001,z_errorText);
end trigger  ;
/
  
--======== End of applicationmessage =============


-- FRAMEWORK_SCHEMA.maildist..bution definition

create table FRAMEWORK_SCHEMA.maildistribution 
   (	st_id number(*,0) not null , 
	xcode nvarchar(70) not null , 
	recipient nvarchar(100) not null , 
   reply_to nvarchar(100) default 'noreply@equinor.com' not null,
	xsubject nvarchar(255) not null , 
	xmessage nclob not null , 
	xepilog nvarchar(400), 
	xstatus char(1) default 'N' check (xstatus in ('N','Y')), 
	xtype nvarchar(255) default 'email', 
	xdatetime_received timestamp (6) not null , 
	xdatetime_sent timestamp (6), 
	xcomment nvarchar(255), 
	st_created_by nvarchar(100) not null default 'NA' not null , 
	st_created_datetime datetime not null default convert([datetime],'1970-01-01',(102)) not null , 
	st_updatetimed_by nvarchar(100), 
	st_updatetimed_datetime datetime
   );
alter table FRAMEWORK_SCHEMA.maildistribution add constraint maildistribution_pk primary key (st_id)
  using index FRAMEWORK_SCHEMA.maildistribution_pk  ;
alter table FRAMEWORK_SCHEMA.maildistribution add constraint maildistribution_unq unique (xcode, xdatetime_received)
  using index FRAMEWORK_SCHEMA.maildistribution_unq  ;

create unique index FRAMEWORK_SCHEMA.maildistribution_pk on FRAMEWORK_SCHEMA.maildistribution (st_id) ;
create unique index FRAMEWORK_SCHEMA.maildistribution_unq on FRAMEWORK_SCHEMA.maildistribution (xcode, xdatetime_received);

comment on table FRAMEWORK_SCHEMA.maildistribution is 'To be used either to batch sending or as a register of what has been sent.
Registers mails to be sent.
xcode => grouping of various topics
Status = N => not sent and Y implies message has been sent.
xdatetime_received and xdatetime_sent provide time information.
   datetimes are set as: sys_extract_utc(current_timestamp)
xepilog => use this as a footnote below xmessage';

create or replace trigger FRAMEWORK_SCHEMA.taud_maildistribution 
    before insert or updatetime
    on maildistribution
    for each row
declare
/*****************************************************************
* Audit trigger
*  Package Info
*   Author          : $Author: JOTHOR $
*   Original datetime   : $datetime: 25.09.2023
*   Last Modified   : $Modtim.e: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*   Copyright       : $Equinor ASA $
*****************************************************************
* Description
*  Maintains the create and updatetime columns in the table.
*
* Could extend auditing by including
*  os-user (255 char) -  sys_context('userenv','os_user')
*  os-host (128 char) -  sys_context('userenv','host')
* Why? ths user is not always the actual user. Using os-user
* pinpoint the user who is logged in on the PC. This user may use
* a common login user (e.g RBAC) thereby camouflaging their identify.
*****************************************************************
* Log
* datetime   Description                        Done by
* 170812 Illegal to alter create information once data    JOTHOR
*  has been entered.
*****************************************************************/
     z_version nvarchar(200) := '';
  z_isLogged boolean := false;
  z_status number := 0;
  z_errorText nvarchar(255) := null;
  z_errordatetime datetime := null ;
begin
   if (inserting) then
      :new.st_created_by   := user;
      :new.st_created_datetime := sys_extract_utc(current_timestamp);
      :new.st_updatetimed_by   := null;
      :new.st_updatetimed_datetime := null;
   elsif (updating) then
      if (:new.st_created_by is null or :new.st_created_by <> :old.st_created_by) then
         z_errorText :=  substr('taud_maildistribution: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(19  ,'st_created_by'  ,'XUSER'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
      elsif (:new.st_created_datetime is null or :new.st_created_datetime <> :old.st_created_datetime) then
         z_errorText :=  substr('taud_maildistribution: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(19  ,'st_created_datetime'  ,'XUSER'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
      elsif (:old.st_updatetimed_datetime is null and :new.st_updatetimed_datetime is null) then
         null; /* ok, this handles the first time the row is updatetimed.*/
      elsif (:new.st_updatetimed_datetime is null) then
         z_errorText :=  substr('taud_maildistribution: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(11  ,'st_updatetimed_datetime'  ,'XUSER'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
      elsif (:new.st_updatetimed_datetime <> :old.st_updatetimed_datetime) then
         z_errorText :=  substr('taud_maildistribution: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(19  ,'st_updatetimed_datetime'  ,'XUSER'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
      end if;

      :new.st_updatetimed_by := user;
      :new.st_updatetimed_datetime := sys_extract_utc(current_timestamp);
   end if;

--goto le_end_goto;<<le_finish_goto>> null;<<le_end_goto>> null;
 exception    when others then
    -- Start throw exception
    FRAMEWORK_SCHEMA.errorhandler.debug(4,'0:'||'Throw exception:'||SQLERRM);
    if (SQLCODE in (-20003,-20002,-20001)) then
      raise;
    end if;
    z_status := SQLCODE;
    z_errorText :=  substr('taud_maildistribution: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(20 ,SQLERRM     ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20001,z_errorText);
end trigger  ;
/

create or replace trigger FRAMEWORK_SCHEMA.tiu_maildistribution 
   before insert or updatetime
   on maildistribution
   for each row
declare
/*****************************************************************
*  Package Info
*   Author          : $Author: JOTHOR $
*   Original datetime   : $datetime: 25.09.2023
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*   Copyright       : $Equinor ASA $
*****************************************************************
* Description
* Housecleaning: Only sent emails outliving time should be deleted.
* NOTE: Fail safe trigger. Errors are logged and exception consumed.
*****************************************************************
* Log
* datetime   Description										Done by
*
*****************************************************************/
     z_version nvarchar(200) := '';
  z_isLogged boolean := false;
  z_status number := 0;
  z_errorText nvarchar(255) := null;
  z_errordatetime datetime := null ;
   lMyClobData nclob;
   lSourceName nvarchar(100) :='NA';
   lSource nvarchar(100) := 'Generated by ...';
   lSubject nvarchar(255);
   lApprovalUser nvarchar(100);
begin
   if inserting then
      if (:new.recipient is null) then
         z_errorText :=  substr('tiu_maildistribution: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(11 ,'recipient'     ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
      end if;

      :new.st_id := itoppseq.nextval;
      :new.xcode := trim(:new.xcode);
      :new.recipient := trim(:new.recipient);
      :new.xsubject := trim(:new.xsubject);
      :new.xtype := trim(:new.xtype);
      :new.xdatetime_received := sys_extract_utc(current_timestamp);
   elsif updating then
      null;
      --:new.xdatetime_sent := sys_extract_utc(current_timestamp);
      --:new.xstatus := 'N';
   end if;
--goto le_end_goto;<<le_finish_goto>> null;<<le_end_goto>> null;
 exception    when others then
    -- Start consume exception
    FRAMEWORK_SCHEMA.errorhandler.debug(4,'0:'||'Consume exception:'||SQLERRM);
    if (SQLCODE not in (-20003,-20002,-20001)) then
              z_status := SQLCODE;
       if (z_errorText is null) then
         z_errorText :=  substr('tiu_maildistribution: ' || SQLERRM,1,255);
       end if;
    end if;
    z_isLogged := true;
    FRAMEWORK_SCHEMA.errorhandler.logError(1,'XL_TOPLEVELNAME.tiu_maildistribution',z_version,SQLERRM);
end trigger  ;
/

--======== End of maildistribution ============

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
   before insert or updatetime or delete
   on FRAMEWORK_SCHEMA.user_administration
   for each row
begin   
   if inserting then
     :new.st_created_by := user;
     :new.st_created_datetime := sys_extract_utc(current_timestamp);
   elsif updating then
    :new.st_updatetimed_by := user;
    :new.st_updatetimed_datetime := sys_extract_utc(current_timestamp);
   elsif deleting then
      null;
      --raise_application_error(-20003,FRAMEWORK_SCHEMA.errorhandler.getMessage(20,'Illegal to delete.'));
   end if;
end trigger;
/

create or replace trigger FRAMEWORK_SCHEMA.tiu_tab_variable
   before insert or updatetime
   on FRAMEWORK_SCHEMA.tab_variable
   for each row
begin   
   if inserting then
     :new.id := itoppseq.nextval;
     :new.category := upper(:new.category);
     :new.key := upper(:new.key);
     :new.st_created_by := user;
     :new.st_created_datetime := sys_extract_utc(current_timestamp);
   elsif updating then
     if (:new.category != :old.category) then 
        --U SERERROR(18,'Category','TAB_VARIABLE');
        raise_application_error(-20003,FRAMEWORK_SCHEMA.errorhandler.getMessage(18,'Category','TAB_VARIABLE'));
     end if;
    :new.st_updatetimed_by := user;
    :new.st_updatetimed_datetime := sys_extract_utc(current_timestamp);
   end if;
end trigger;
/


CREATE_TRIGGER(FRAMEWORK_SCHEMA.tiu_cleanuptableinfo)
   before insert or updatetime
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
      :new.created_datetime := sys_extract_utc(current_timestamp);
      select count(*) into lCount
         from user_tables
         where table_name = upper(:new.tabname);
      if (lCount != 1) then
         USERERROR(12,:new.tabname);
      end if;
   elsif updating then 
    :new.updatetimed_by := user;
    :new.updatetimed_datetime := sys_extract_utc(current_timestamp);
   end if;
END_TRIGGER;
/

-----------------------------------------------------------------------
create or replace trigger FRAMEWORK_SCHEMA.tiu_t_basis_clientmessage
   before insert or updatetime
   on FRAMEWORK_SCHEMA.t_basis_clientmessage
   for each row
begin   
   if inserting then
      select to_char (itoppseq.nextval)
        into :new.clientmessage_s
        from sys.dual;
     :new.row_creator := user;
     :new.row_create_datetime := current_timestamp;
   elsif updating then 
    :new.clientmessage_s := :old.clientmessage_s;
    :new.updator := user;
    :new.updatetime_datetime := current_timestamp;
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
    :new.row_create_datetime := current_timestamp;
   end if;
end trigger;
/
-----------------------------------------------------------------------
create or replace trigger FRAMEWORK_SCHEMA.tiu_t_basis_clienterrorlog
   before insert or updatetime
   on FRAMEWORK_SCHEMA.t_basis_clienterrorlog
   for each row
begin   
   if inserting then
      select to_char (itoppseq.nextval)
        into :new.clienterrorlog_s
        from sys.dual;
      :new.row_creator := user;
      :new.row_create_datetime := current_timestamp;
      :new.datetimeregistered := current_timestamp;
   elsif updating then
      :new.clienterrorlog_s := :old.clienterrorlog_s;
      :new.updator := user;
      :new.updatetime_datetime := current_timestamp;
   end if;
end trigger;
/
-----------------------------------------------------------------------
create or replace trigger FRAMEWORK_SCHEMA.tiu_R_TABLE_DEF
   before insert or updatetime
   on FRAMEWORK_SCHEMA.R_TABLE_DEF
   for each row
begin   
   if inserting then
      :new.id := itoppseq.nextval;
      :new.row_creator := user;
      :new.row_create_datetime := current_timestamp;
   elsif updating then
      :new.updator := user;
      :new.updatetime_datetime := current_timestamp;
   end if;
end trigger;
/

CREATE_TRIGGER(tc_dba_audit_hist)
   for insert or updatetime
   on FRAMEWORK_SCHEMA.dba_audit_hist
   --follows [trigger]   
   compound trigger    
/*****************************************************************
* Trigger info:
* Author          : $Author: JOTHOR $
* Original datetime   : $datetime: 22.09.2022 $
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
* datetime   Description					 Done by
*
*****************************************************************/
   STANDARD_VARIABLE;

   ---------------------------------------------------------------
   -- Variables
   ---------------------------------------------------------------
   lReportdatetime datetime;
   
   ---------------------------------------------------------------
   -- Section for procedures and functions
   ---------------------------------------------------------------

   ---------------------------------------------------------------
   -- This is for tables. View related timing states to be removed
   ---------------------------------------------------------------
   before statement
   is
   begin
      select max(report_day) into lReportdatetime 
         from FRAMEWORK_SCHEMA.dba_audit_hist;
   end before statement;
--
   before each row 
   is
   begin
      if (inserting or updating) then
         if (lReportdatetime = :new.report_day) then
            USERERROR(20,'Error: Data for '||to_datetime(lReportdatetime,'dd.mm.yyyy')||' already loaded.');
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
  before insert or updatetime
  on PROCESSING_SCRIPT
  for each row
declare
/*****************************************************************
*  Package Info
*   Author          : $Author:  $
*   Original datetime   : $datetime:  $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
*  Maintains the create and updatetime columns in the table.
* System_name and container_name are mutually exclusive.
*****************************************************************
* Log
* datetime   Description                                        Done by
* 240812 Only top level containers may have scripts attached JOTHOR
*****************************************************************/
    z_version nvarchar(200) := '';
  z_isLogged boolean := false;
  z_status number := 0;
  z_errorText nvarchar(255) := null;
  z_errordatetime datetime := null ;
  lCount int := 0;
begin
  if (inserting or updating) then
    if (:new.system_name is not null and :new.container_name is not null) then
       null; -- Ok
    elsif (:new.system_name is null or :new.container_name is null) then
      z_errorText :=  substr('tiu_PROCESSING_SCRIPT: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(11 ,'system_name or container_name but not both ,'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
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
    z_errorText :=  substr('tiu_PROCESSING_SCRIPT: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(20 ,SQLERRM     ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20001,z_errorText);
end trigger  ;
/

CREATE OR REPLACE TRIGGER taud_PROCESSING_SCRIPT
  before insert or updatetime
  on PROCESSING_SCRIPT
  for each row
declare
/*****************************************************************
* Audit trigger
*  Package Info
*   Author          : $Author:  $
*   Original datetime   : $datetime:  $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
*  Maintains the create and updatetime columns in the table.
*
*****************************************************************
* Log
* datetime   Description                  Done by
* 170812 Illegal to alter "create" information once data   JOTHOR
*  has been entered.
*****************************************************************/
    z_version nvarchar(200) := '';
  z_isLogged boolean := false;
  z_status number := 0;
  z_errorText nvarchar(255) := null;
  z_errordatetime datetime := null ;
begin
  if (inserting) then
    :new.created_by := user;
    :new.created_datetime := sys_extract_utc(current_timestamp);
  elsif (updating) then
    if (:new.created_by is null or :new.created_by <> :old.created_by) then
       z_errorText :=  substr('taud_PROCESSING_SCRIPT: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(19 ,'created_by' ,'XUSER'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
    elsif (:new.created_datetime is null or :new.created_datetime <> :old.created_datetime) then
       z_errorText :=  substr('taud_PROCESSING_SCRIPT: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(19 ,'created_datetime' ,'XUSER'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
    elsif (:old.updatetimed_datetime is null and :new.updatetimed_datetime is null) then
       null; -- ok, this handles the first time the row is updatetimed.
    elsif (:new.updatetimed_datetime is null) then
       z_errorText :=  substr('taud_PROCESSING_SCRIPT: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(11 ,'updatetimed_datetime' ,'XUSER'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);  -- must supply
    elsif (:new.updatetimed_datetime <> :old.updatetimed_datetime) then
       z_errorText :=  substr('taud_PROCESSING_SCRIPT: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(19 ,'updatetimed_datetime' ,'XUSER'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
    end if;

    :new.updatetimed_by := user;
    :new.updatetimed_datetime := sys_extract_utc(current_timestamp);
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
    z_errorText :=  substr('taud_PROCESSING_SCRIPT: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(20 ,SQLERRM     ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20001,z_errorText);
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
  before insert or updatetime
  on PROCESSING_SCRIPT
  for each row
declare
/*****************************************************************
*  Package Info
*   Author          : $Author:  $
*   Original datetime   : $datetime:  $
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
    z_version nvarchar(200) := '';
  z_isLogged boolean := false;
  z_status number := 0;
  z_errorText nvarchar(255) := null;
  z_errordatetime datetime := null ;
begin
  if (inserting) then
    :new.id := seq_PROCESSING_SCRIPT.nextval;
  elsif (updating and :new.id != :old.id) then
    z_errorText :=  substr('t_idPROCESSING_SCRIPT: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(18 ,'id' ,'PROCESSING_SCRIPT'    ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20003,z_errorText);
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
    z_errorText :=  substr('t_idPROCESSING_SCRIPT: ' || FRAMEWORK_SCHEMA.errorhandler.getMessage(20 ,SQLERRM     ),1,255);   z_errordatetime := current_timestamp;    z_isLogged:=false;   raise_application_error(-20001,z_errorText);
end trigger  ;
/


--***************************************************************
-- Preload data
-- SDE_IT message codes reserved below 100 (not including 100).
-- All system specific messages should come from 100 onwards
--***************************************************************
Insert into FRAMEWORK_SCHEMA.CLEANUPTABLEINFO(appname, tabname, message, days, synccolumn, isactive, columnappname)
   Values('NA', 't_basis_clienterrorlog', NULL, 10, 'row_create_datetime', 1, 'NA');
Insert into FRAMEWORK_SCHEMA.CLEANUPTABLEINFO(appname, tabname, message, days, synccolumn,isactive, columnappname)
   Values('NA', 'process_information_history', NULL, 90, 'start_time', 1, 'NA');
Insert into FRAMEWORK_SCHEMA.CLEANUPTABLEINFO(appname, tabname, message, days, synccolumn, isactive, columnappname)
   Values('NA', 'runlog', NULL, 90, 'start_datetime', 0, 'NA');
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
insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (10,'End datetime must be after start datetime.');
insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (11,'The field <=>1<@> is mandatory and is to be supplied.');
insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (12,'The <=>1<@> does not exist.');
insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (13,'The <=>1<@> with key=<<=>2<@>> does not exist.');
insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (14,'Failed to updatetime <=>1<@>.');
insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (15,'Failed to updatetime <=>1<@>. A parent in <=>2<@> is mandatory.');
insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (16,'Failed to associate <=>1<@> with <=>2<@>. <=>3<@>.');
insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (17,'Failed to disassociate <=>1<@> from <=>2<@>. <=>3<@>.');
insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (18,'Illegal to updatetime key value <=>1<@> in <=>2<@>.');
insert into FRAMEWORK_SCHEMA.t_basis_clientmessage(messagecode,messagetext) values (19,'The <=>1<@> of <=>2<@> has been rejected. The instance has been updatetimed by somebody else.');
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


-- NOTE: Remember to updatetime the system name in SYSTEM_DETAIL.
insert into FRAMEWORK_SCHEMA.tab_variable(category,key,xcomment) values ('SYSTEM_DETAIL','NAME','This is the of the system e.g.IRIS21');
insert into FRAMEWORK_SCHEMA.tab_variable(category,key,valid_value,xcomment) values ('SYSTEM_DETAIL','DELIMITER',';','Delimiter to use separating the chain of datasources.');
insert into FRAMEWORK_SCHEMA.tab_variable(category,key,valid_value,xcomment) values ('SYSTEM_DETAIL','MAX_DATASOURCE_SET',5,'The max number of datasources in the chain. Those exceeding are removed from the chain.');
commit;





--***************************************************************
-- Initiate jobs
-- to_datetime('04.11.2008 18:00:00','dd/mm/yyyy hh24:mi:ss')
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
     ,next_datetime => trunc(current_timestamp+1)+18/24 
     ,interval  => 'trunc(current_timestamp+1)+18/24'
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
     ,next_datetime => trunc(current_timestamp+1)+18/24 
     ,interval  => 'trunc(current_timestamp+1)+18/24'
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
     ,what      => '/*maintain_dba_audit_hist*/begin FRAMEWORK_SCHEMA.maintain_dba_audit_hist; end;'
     ,next_datetime => trunc(current_timestamp+1)+1/24 
     ,interval  => 'trunc(current_timestamp+1)+1/24'
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


