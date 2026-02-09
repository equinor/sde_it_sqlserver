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
------------------------------------------------------------------

/*************************************************
* Author: JOTHOR
* Date: 17.11.2015
*
* Deploy necessary DDL first and thereafter
* neccessary DDL on schema SDE.
*
**************************************************
* Log   
* Date   Description
* 150917 Alterd compress_log with 2 new attributes
**************************************************/



/*************************************************
* Table  COMPRESS_LOG
**************************************************/
--DROP TABLE COMPRESS_LOG CASCADE CONSTRAINTS;
CREATE TABLE COMPRESS_LOG
(
  SDE_ID INTEGER        NOT NULL,
  SERVER_ID          INTEGER        NOT NULL,
  DIRECT_CONNECT     nvarchar(1),
  COMPRESS_START     DATE,
  START_STATE_COUNT  INTEGER,
  COMPRESS_END       DATE,
  END_STATE_COUNT    INTEGER,
  COMPRESS_STATUS    nvarchar(20),
  OWNER nvarchar(75),
  NODENAME nvarchar(100)
);
grant select,insert,update,delete on compress_log to sde;

-------------------------------------------------------------------
-- Table PROCESS_INFORMATION_HISTORY
-------------------------------------------------------------------

--drop table FRAMEWORK_SCHEMA.process_information_history;

create table FRAMEWORK_SCHEMA.process_information_history
(  sde_id          integer           null
  ,server_id       integer           null
  ,start_time      datetime          null
  ,rcount          integer           null
  ,wcount          integer           null
  ,opcount         integer           null
  ,numlocks        integer           null
  ,fb_partial      integer           null
  ,fb_count        integer           null
  ,fb_fcount       integer           null
  ,fb_kbytes       integer           null
  ,owner           nnvarchar(30)     null
  ,direct_connect  nvarchar(1)       null
  ,sysname         nnvarchar(32)     null
  ,nodename        nnvarchar(256)    null
  ,xdr_needed      nvarchar(1)       null
  ,parent_sde_id   integer           null
  ,proxy_yn nvarchar(1)              null
  ,audsid integer                    null
  ,end_time        date              null
);
grant select,insert,update,delete 
   on FRAMEWORK_SCHEMA.process_information_history to sde;

-------------------------------------------------------------------
-- Table TABLE_LOCK_HISTORY
-------------------------------------------------------------------
--drop table FRAMEWORK_SCHEMA.table_lock_history;
create table FRAMEWORK_SCHEMA.table_lock_history
(  start_time       datetime
  ,registration_id  integer
  ,table_name       nvarchar(193)
  ,nodename         nvarchar(32)
  ,direct_connect   nvarchar(1)
  ,process_owner    nvarchar(30)
  ,table_owner      nvarchar(32)
  ,lock_type        nvarchar(10)
  ,lock_time        datetime
);
grant select,insert,update,delete 
   on FRAMEWORK_SCHEMA.table_lock_history to sde;
