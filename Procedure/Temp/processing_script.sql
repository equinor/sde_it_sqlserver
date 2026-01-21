CREATE TABLE processing_script
( ID                INTEGER                     NOT NULL,
  SYSTEM_NAME         VARCHAR2(100),
  CONTAINER_NAME      VARCHAR2(100),
  PRE_CREATE        VARCHAR2(4000),
  PRE_CREATE_TYPE   VARCHAR2(30 BYTE)           DEFAULT 'SQL',
  POST_CREATE       VARCHAR2(4000),
  POST_CREATE_TYPE  VARCHAR2(30 BYTE)           DEFAULT 'SQL',
  PRE_DELETE        VARCHAR2(4000),
  PRE_DELETE_TYPE   VARCHAR2(30 BYTE)           DEFAULT 'SQL',
  POST_DELETE       VARCHAR2(4000),
  POST_DELETE_TYPE  VARCHAR2(30 BYTE)           DEFAULT 'SQL',
  CREATED_BY        NVARCHAR2(75),
  CREATED_DATE      TIMESTAMP(6),
  UPDATED_BY        NVARCHAR2(75),
  UPDATED_DATE      TIMESTAMP(6)
);
CREATE UNIQUE INDEX processing_script_UN ON processing_script
(SYSTEM_NAME, CONTAINER_NAME);

-- 
-- Non Foreign Key Constraints for Table processing_script 
-- 
ALTER TABLE processing_script ADD (
  CONSTRAINT XPKprocessing_script PRIMARY KEY (ID) );

/*create table process_script_detail
( id                integer                     not null,
  container_id      integer,
  script_timing   varchar2(20) not null check (script_timing in ('pre','post'))
  xsequence        integer,
  script   varchar2(4000)           default 'sql',
  xtype   varchar2(30 byte)           default 'sql',
  created_by        nvarchar2(75),
  created_date      timestamp(6),
  updated_by        nvarchar2(75),
  updated_date      timestamp(6)
);
*/

COMMENT ON COLUMN PROCESSING_SCRIPT.CONTAINER_NAME IS 'Database name normally.';
COMMENT ON TABLE PROCESSING_SCRIPT IS 'SYSTEM_ID AND CONTAINER_ID ARE MUTALLY EXCLUSIVE.\ 
PROVIDING A SYSTEM_ID IMPLIES ALL CONTAINERS IN THE SYSTEM ARE SUBJECT TO THESE PROCESSING SCRIPTS.\
PROVIDING A CONTAINER_ID OVERRIDES THE PROCESSING SCRIPTS REGISTERED ON THE SYSTEM (IF ANY).\
ALL SCRIPTS ARE DIRECTLY RELATED TO USER. RBAC IS A SYSTEM FOR HANDLING USER ACCESS TO SYSTEMS AND CONTAINERS.\
THEREFORE THE CREATE AND DELETE SCRIPTS ARE RELATED TO THE CREATION AND DELETION OF USERS.\
ANY PARAMETER TO BE SUPPLIED TO SCRIPT IS LIMITED TO THE USER IN FOCUS.\
\
EXAMPLES (NEWLINES ARE REPRESENTED AS "\N", A COMMAND SEPARATOR AS "/"\
1)\
   BEGIN\N\
      ....
   END;\N\
2)
CREATE USERS ....;\N\
/\N\
CREATE TABLE...;\N\
/\N\
CREATE SEQUE ....;\N\
-- AN OPTIONAL "/\N" CAN BE PLACED AFTER LAST COMMAND\
';


--============================================================
-- Create triggers
-- taud_PROCESSING_SCRIPT
-- tiu_PROCESSING_SCRIPT
-- tid_PROCESSING_SCRIPT
--============================================================
create sequence seq_PROCESSING_SCRIPT
  START WITH 0
  MAXVALUE 9999999999999999999999999999
  MINVALUE 0
  NOCYCLE
  NOCACHE
  NOORDER
  NOKEEP
  GLOBAL;
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
* Date   Description						Done by
* 170812 Illegal to alter "create" information once data	JOTHOR
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



SET DEFINE OFF;
Insert into PROCESSING_SCRIPT
   (system_name,container_name,pre_create, pre_create_type, post_create, post_create_type, pre_delete, 
    pre_delete_type, post_delete, post_delete_type)
 Values
   ('IRIS21','P080.STATOIL.NO',NULL, 'SQL', null, 'SQL', NULL, 
    'SQL', NULL, 'SQL');
update PROCESSING_SCRIPT
   set post_create='--************************************************************
--* Could be an idea to remove CR (carrige return) chr(13).
--* Do exceed 80 char pr line.
--* The {username} in the curly brackets is replaced by username
--***********************************************************
--**************************************************************************
--* We create the shared logfiles and associated objects. First we create the 
--* SDE_LOGFILES table.                                                       
--**************************************************************************
CREATE GLOBAL TEMPORARY 
TABLE {username}.sde_logfiles
(
    logfile_name         VARCHAR2(256) NOT NULL ,
    logfile_id           INTEGER NOT NULL ,
    logfile_data_id      INTEGER NOT NULL ,
    registration_id      INTEGER NOT NULL ,
    flags                INTEGER NOT NULL ,
    session_tag          INTEGER NOT NULL ,
    logfile_data_db      VARCHAR2(32),
    logfile_data_owner   VARCHAR2(32),
    logfile_data_table   VARCHAR2(98),
    column_name          NVARCHAR2(32)
)
ON COMMIT PRESERVE ROWS
/
--**************************************************************************
--* Create the required indexes for this table.
--**************************************************************************
CREATE UNIQUE INDEX 
  {username}.sde_logfiles_pk
  ON {username}.sde_logfiles(logfile_id)
/
CREATE UNIQUE INDEX 
   {username}.sde_logfils_uk
   ON {username}.sde_logfiles(logfile_name)
/
CREATE UNIQUE INDEX 
   {username}.sde_logfiles_uk2 
   ON {username}.sde_logfiles(logfile_data_id)
/

--**************************************************************************
--* Create the SDE_LOGFILE_DATA table.
--**************************************************************************
CREATE GLOBAL TEMPORARY 
TABLE {username}.sde_logfile_data
(
    logfile_data_id      INTEGER NOT NULL ,
    sde_row_id           INTEGER NOT NULL 
)
ON COMMIT PRESERVE ROWS
/

--**************************************************************************
--* Create the required indexes for this table. 
--**************************************************************************
CREATE INDEX {
  username}.sde_logfile_data_idx1 
  ON {username}.sde_logfile_data(logfile_data_id, sde_row_id)
/
CREATE INDEX 
  {username}.sde_logfile_data_idx2 
  ON {username}.sde_logfile_data(sde_row_id)
/

--**************************************************************************
--* Create sequence used for these logfiles.     
--**************************************************************************
CREATE SEQUENCE {username}.SDE_LOGFILE_LID_GEN 
INCREMENT BY 1 
START WITH 1 
NOCYCLE CACHE 20 
NOORDER
/');
    
begin
   Insert into PROCESSING_SCRIPT(system_name,container_name,pre_create, pre_create_type
      , post_create, post_create_type, pre_delete, 
       pre_delete_type, post_delete, post_delete_type)    
      select 'IRIS21','P080H.STATOIL.NO'    ,pre_create, pre_create_type, post_create, post_create_type, pre_delete, 
       pre_delete_type, post_delete, post_delete_type
       from PROCESSING_SCRIPT where container_name like 'P080.%';
   Insert into PROCESSING_SCRIPT(system_name,container_name,pre_create, pre_create_type
      , post_create, post_create_type, pre_delete, 
       pre_delete_type, post_delete, post_delete_type)    
      select 'IRIS21','T080AX.STATOIL.NO'    ,pre_create, pre_create_type, post_create, post_create_type, pre_delete, 
       pre_delete_type, post_delete, post_delete_type
       from PROCESSING_SCRIPT where container_name like 'P080.%';
   COMMIT;
end;



