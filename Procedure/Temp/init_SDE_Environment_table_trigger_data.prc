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
  SDE_ID             INTEGER                    NOT NULL,
  SERVER_ID          INTEGER                    NOT NULL,
  DIRECT_CONNECT     VARCHAR2(1 BYTE),
  COMPRESS_START     DATE,
  START_STATE_COUNT  INTEGER,
  COMPRESS_END       DATE,
  END_STATE_COUNT    INTEGER,
  COMPRESS_STATUS    VARCHAR2(20 BYTE),
  OWNER VARCHAR2(75),
  NODENAME VARCHAR2(100)
);
grant select,insert,update,delete on compress_log to sde;

-------------------------------------------------------------------
-- Table PROCESS_INFORMATION_HISTORY
-------------------------------------------------------------------

--drop table process_information_history cascade constraints;

create table process_information_history
(
  sde_id          integer                       null,
  server_id       integer                       null,
  start_time      date                          null,
  rcount          integer                       null,
  wcount          integer                       null,
  opcount         integer                       null,
  numlocks        integer                       null,
  fb_partial      integer                       null,
  fb_count        integer                       null,
  fb_fcount       integer                       null,
  fb_kbytes       integer                       null,
  owner           nvarchar2(30)                 null,
  direct_connect  varchar2(1 byte)              null,
  sysname         nvarchar2(32)                 null,
  nodename        nvarchar2(256)                null,
  xdr_needed      varchar2(1 byte)              null,
parent_sde_id integer,
proxy_yn varchar2(1 byte)              null,
audsid integer,
  end_time        date
);
grant select,insert,update,delete on process_information_history to sde;

-------------------------------------------------------------------
-- Table TABLE_LOCK_HISTORY
-------------------------------------------------------------------
--drop table table_lock_history;
create table table_lock_history
(
  start_time       date,
  registration_id  number,
  table_name       varchar2(193 byte),
  nodename         varchar2(32 byte),
  direct_connect   varchar2(1 byte),
  process_owner    varchar2(30 byte),
  table_owner      varchar2(32 byte),
   lock_type varchar2(10),
   lock_time  date
);
grant select,insert,update,delete on table_lock_history to sde;





