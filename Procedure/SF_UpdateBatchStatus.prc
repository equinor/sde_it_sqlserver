CREATE_PROCEDURE(SCHEMA.sf_updatebatchstatus)(@pName nvarchar(250)
	,@pStartDate datetime
	,@pEndDate datetime
	,@pNrError integer = 0
	,@pNrBusinessTransaction integer = 0
	,@pMessage nvarchar(2000)
   ,@pRetainHistory BOOLEAN =FALSE_NR
   ,@pHost nvarchar(250) = 'NA'
   )
  --with execute as { CALLER | SELF | OWNER | 'user_name' } 
--with execute as owner
as
/***********************************************************************
* Package Info
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 2006/02/16 13:20:14 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: $
* Description     : $Header: F:/Private/Repository/dbr/Procedure/SF_UpdateBatchStatus.pcb,v 2.3 2006/02/16 13:20:14 JOTHOR Exp $
* Revision History: $Revision: 2.3 $
* Workfile        : $Workfile: $
* Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2006/02/16 13:20:14 $
*
*Description:
* https://learn.microsoft.com/en-us/sql/ssma/oracle/messages/o2ss0205?view=sql-server-ver16
* https://stackoverflow.com/questions/45731207/commit-transaction-outside-the-current-transaction-like-autonomous-transaction
* SQL Server 2014 does not support autonomous transactions. The only way to isolate a Transact-SQL block
* from a transaction context is to open a new connection.
* Use the xp_ora2ms_exec2 extended procedure and its extended version xp_ora2ms_exec2_ex,
*  bundled with the SSMA 6.0 Extension Pack, to open new transactions. The procedure's purpose
*  is to invoke any stored procedure in a new connection and help invoke a stored procedure 
*  within a function body. The xp_ora2ms_exec2 procedure has the following syntax:
*    xp_ora2ms_exec2
*    <active_spid> int,
*    <login_time> datetime,
*    <ms_db_name> varchar,
*    <ms_schema_name> varchar,
*    <ms_procedure_name> varchar,
*    <bind_to_transaction_flag> varchar,
*    [optional_parameters_for_procedure];
* Then you need to install on your server stored procedures and other scripts: 
*   SSMA for Oracle Extension Pack (only SSMA for Oracle Extension Pack.7.5.0.msi).
*
* Parameters
* ============
* @pName - the name of the batch job or application monitored (hereafter task)
* @pStartDate - the start time of task
* @pEndDate  - the end time of the task
* @pNrError  - the number of business transactions errors
* @pNrBusinessTransaction the total number of business transactions processed
* @pMessage  - informative message
* @pRetainHistory - default false. Should one desire to retain a history of
*    the previous lHistoryLimit entries, send in true and the system will
*    automatically maintain the history.
*
* Required table layout (oracle)
* =============================
* create table batch_status
* (
*   name                     varchar2(100) not null,
*   xversion                 integer not null,
*   start_date               date,
*   end_date                 date,
*   nr_of_error              integer,
*   nr_business_transaction  integer,
*   message                  varchar2(1000),
*   hour   generated always as (round(("end_date"-"start_date")*24,1)) virtual,
*   minute generated always as (round(("end_date"-"start_date")*60*24,0)) virtual,
*   sec    generated always as (round(("end_date"-"start_date")*60*60*24,2)) virtual
* );
* alter table batch_status add (primary key (name,xversion));
*
***********************************************************************
* Log
* Date   Description                                              Done by
* 140410 Added PRAGMA AUTONOMOUS_TRANSACTION;					      JOTHOR
* 141124 Changed to MS Sqlserver syntax                           JOTHOR    
* 090326 Altered column version to xversion                       JOTHOR     
***********************************************************************/
begin
   STANDARD_VARIABLE;
   DEBUG_ENTER;
   set nocount on;
   declare @lCount integer = 0;
   declare @lHistoryLimit integer = 5;

   if (GET_TRANCOUNT > 0)
   begin
      DEBUG('Trancount = '+cast(GET_TRANCOUNT as nvarchar(10)) + '.');
      USERERROR(20,'XFUNC_NAME: Please close transactions prior to calling this procedure.');
   end;
   
   BEGIN_EXCEPTION
      if (@pName is null)
      begin
        USERERROR(20,'Error occurred during update of batch_status table. @pName is null');
      end;

      set @lCount = 0;
      BEGIN_TRANSACTION(Tran_SF_UpdateBatchStatus);
         if (@pRetainHistory = TRUE_NR)
         begin
            -------------------------------------------     
            -- Move everything up one
            -------------------------------------------     
            update SCHEMA.batch_status
               set xversion = xversion + 1
               where name = @pName;
            set @lCount = GET_ROWCOUNT;
            DEBUG('retain - Update nr of rows for <'+@pName+'> : '+cast(@lCount as nvarchar(10)));

            -------------------------------------------     
            -- Delete everything above limit
            -------------------------------------------     
            if (@lCount > 0)
            begin
              delete SCHEMA.batch_status
                  where name = @pName
                  and xversion > @lHistoryLimit;
               DEBUG('retain - Deleted nr of rows for <'+@pName+'> : '+cast(GET_ROWCOUNT as nvarchar(10)));
            end;
         end;
         else
         begin
            delete SCHEMA.batch_status
               where name = @pName;
            DEBUG('No retain -Deleted nr of rows for <'+@pName+'> : '+cast(GET_ROWCOUNT as nvarchar(10)));
         end;

         insert into SCHEMA.batch_status (
             name
            ,xversion             
            ,start_date
            ,end_date
            ,nr_of_error
            ,nr_business_transaction
            ,message
            ,host
            )
            values (
             @pName
            ,1
            ,@pStartDate
            ,@pEndDate
            ,@pNrError
            ,@pNrBusinessTransaction
            ,@pMessage
           ,@pHost
            );
      END_TRANSACTION(Tran_SF_UpdateBatchStatus); -- Do not use macro C O M M I T as this will not expand for a SF_ procedure.
      DEBUG_EXIT;
   EXCEPTION
      DEBUG('Error: ' + coalesce(error_message(),'null') + '.');
      DEBUG_EXIT
      ROLLBACK;
      --S TD_EXCEPTION; -- Note, we are not using S T D_E X C E P T I O N_H A N D L E R
       select 1;
   END_EXCEPTION; 
END_PROCEDURE;

--graxxnt execute on sde_it.sf_updatebatchstatus to public;