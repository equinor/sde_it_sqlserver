CREATE_PROCEDURE(SCHEMA.cleanUpLogTable) (@lDryrun char(1) = FALSE_CHAR)
/*****************************************************************
* Package Info
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 2016/08/16 13:20:13 $
* Last Modified   : $Modtime: $
* Archive Name    : $Archive: $
* Description     : $Header:   $
* Revision History: $Revision: 2.3 $
* Workfile        : $Workfile: $
* Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2016/08/16 13:20:13 $
*****************************************************************
* Description
* TO-DO: filter syncolumn on valid datetime value. Use reg_exp to filter.
*
* Relates to registered tables in cleanUpTableInfo. 
* Date conversion:
*  https://learn.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?view=sql-server-ver17

-- See: https://learn.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?view=sql-server-ver17

-- See: https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-executesql-transact-sql?view=sql-server-ver17
*****************************************************************
* Log
* Date  Description                                         Done by
* 250919 Up'ed process_information_history to 366 days      JOTHOR
* 100622 Relates to registered tables in cleanUpTableInfo.  JOTHOR
* 200126 Started job upgrading to sqlserver                 JOTHOR
*****************************************************************/
as
begin
   set nocount on; 
   STANDARD_VARIABLE;

/*****************************************************
* @lDays   the number of days to start deletion from
* @lDeletion_lDate   calculated date from which everything older
*   shall be delete
* lStartDate the time this proc started
* @lEndDate the time this proc ended
* @lCount  counter.
* @lErrText error text
* @lMessage message text
* @lErrCount the number of errors encountered
*****************************************************/  
   DECLARE_CURSOR(cur_data)
       for select appname,xschema,tabname,days
         ,synccolumn,isactive
         ,additional_condition
         ,st_id
      from SCHEMA.cleanUpTableInfo
      where isactive = TRUE_CHAR
      order by appname,tabname;
   
   declare @LogTable table(
       lLevel integer
      ,lMessage nvarchar(500) 
      );
    
   declare @lSql nvarchar(1000) = null
      ,@lAppname nvarchar(150) = null
      ,@lSchema nvarchar(150)  = null
      ,@lTabname nvarchar(250) = null
      ,@lFQN_Tabname nvarchar(250) = null
      ,@lDays integer = 0
      ,@lSynccolumn nvarchar(250)
      ,@lAdditional_condition nvarchar(400)
      ,@lIsactive char(1) = FALSE_CHAR
      ,@lSt_id integer 
      ,@lDeletion_lDate datetime = null
      ,@lStartDate datetime = getutcdate()
      ,@lEndDate datetime = null
      ,@lTabCount integer = 0
      ,@lCount integer = 0
      ,@lErrCount integer = 0
      ,@lErrText nvarchar(1000)= null
      ,@lMessage nvarchar(300) = null
      ,@lLog_level integer = LEVEL_INFO
      ,@lParmDefinition nvarchar(100);

  /********************************************
  * Cleanup Block 1:
  * Calculate the date to delete from
  * List of all the actions/tables to be cleaned.
  * To be kept in own block
  * Register the occasion in the batch status
  * table.
  * The getstatus refers to the cleanup block. The
  * consume_exception_handler set the status flag,
  * should an error have occurred.
  ********************************************/
DEBUG_START;
  if (@lDryrun = TRUE_CHAR)
  begin
    DEBUG('Dry run engaged.');
  end;
DEBUG_END;  
  
   set @lTabCount = 0;
   set @lErrCount = 0;
   OPEN_CURSOR(cur_data);
   fetch next from cur_data into @lAppname,@lSchema,@lTabname
      ,@lDays,@lSynccolumn,@lIsactive,@lAdditional_condition
      ,@lSt_id;
   
   while GET_FETCH_STATUS = 0
   begin
      SETSTATUS(0);
      set @lTabCount = @lTabCount + 1;
      set @lFQN_Tabname = @lSchema + '.' + @lTabname;
      DEBUG('Processing '+@lFQN_Tabname+'.');
      
      ----------------------------------------------
      -- Check if table still exists
      ----------------------------------------------
      if not exists (select 1 
               from information_schema.tables
               where lower(table_schema)=lower(@lSchema)
               and lower(table_name)=lower(@lTabname)
               )
      BEGIN_EXCEPTION
         BEGIN_TRANSACTION
            DEBUG('Table >'+@lTabname+'< does not exist. Setting to inactive.');
            update cleanUpTableInfo
               set isactive=FALSE_CHAR
                   ,message='Table >'+@lTabname+'< does not exist. Setting to inactive.'
               where st_id = @lSt_id;
            DEBUG('Setting to inactive. Rowcount='+cast(GET_ROWCOUNT as nvarchar(10))+'.');
         END_TRANSACTION;
         
         SET_TEMP_STR('Table '+@lFQN_Tabname+' does not exist - setting to inactive')
         insert into @LogTable(lLevel,lMessage) 
            values(LEVEL_INFO,GET_TEMP_STR); 
         set @lErrCount = @lErrCount + 1;            
         goto Cont;
      EXCEPTION
         ROLLBACK;
         SETSTATUS(1);
         set @lErrCount = @lErrCount + 1;
         --C ONSUME_EXCEPTION_HANDLER;
         SET_TEMP_STR('Error: '+@lFQN_Tabname+': ' + error_message() );
         insert into @LogTable(lLevel,lMessage)
            values(LEVEL_HIGH,GET_TEMP_STR); 
         goto Cont;
      END_EXCEPTION;

      ----------------------------------------------
      -- Perform cleanup
      ----------------------------------------------
      DEBUG('Perform cleanup.');
      BEGIN_EXCEPTION
         set @lCount = 0;
         DEBUG('Delete: 1');
         select @lDeletion_lDate = dateadd(day,-@lDays,getutcdate());
         DEBUG('Deletion date set to: '+convert(nvarchar(50),@lDeletion_lDate,120)+'.');
         
         set @lSql = 'delete from ' + @lFQN_Tabname
                +' where convert(datetime2,'+@lSynccolumn+',120) < @lDeletion_lDate';
         if @lAdditional_condition is not null
         begin
            set @lSql = @lSql + ' and '+@lAdditional_condition;
         end;
         DEBUG('Delete: '+@lSql);

         BEGIN_TRANSACTION
            set @lParmDefinition = N'@lDeletion_lDate datetime';
            if (@lDryrun = FALSE_CHAR)
            begin
               exec sp_executesql @lSql, @lParmDefinition, @lDeletion_lDate;
               set @lCount = GET_ROWCOUNT;
               DEBUG('Deleted rowcount='+cast(@lCount as nvarchar(10))+'.');
            end
            else
            begin
               DEBUG('Dry run-Execute: Days= '+convert(nvarchar(10),@lDays) + ' date=' + convert(nvarchar(50),@lDeletion_lDate,121) + ': '+ @lSql+'.');
            end;
         END_TRANSACTION;

         DEBUG('Deleted '+ cast(@lCount as nvarchar(10)) + ' rows exceeding nr days = ' + cast(@lDays as nvarchar(10))+'. Sql='+@lSql);
      EXCEPTION
         ROLLBACK;
         SETSTATUS(1);
         set @lErrCount = @lErrCount + 1;
         SET_TEMP_STR('Error: '+@lFQN_Tabname+': ' + error_message() );
         insert into @LogTable(lLevel,lMessage)
            values(LEVEL_HIGH,GET_TEMP_STR);  
         CONSUME_EXCEPTION_HANDLER;
         goto Cont;
      END_EXCEPTION;

      if (GETSTATUS = 0)
      begin
         SET_TEMP_STR('Removed rows older than '+ convert(nvarchar(50),@lDeletion_lDate,120) + ' in table = ' + @lFQN_Tabname+'.');
         insert into @LogTable(lLevel,lMessage)
            values(LEVEL_INFO,GET_TEMP_STR);             
      end;

      Cont:
      fetch next from cur_data into @lAppname,@lSchema,@lTabname
         ,@lDays,@lSynccolumn,@lIsactive,@lAdditional_condition
         ,@lSt_id;
   end; -- end while
   
   CLOSE_DEALLOCATE_CURSOR(cur_data);
   DEBUG('Exiting cleanup sequence.');
   
   if exists(select 1 from @LogTable)
   begin
     DECLARE_CURSOR(cur_log)
         for select lLevel,lMessage from @LogTable;
      OPEN_CURSOR(cur_log);
      fetch next from cur_log into @lLog_level,@lMessage;
      BEGIN_TRANSACTION;
         while GET_FETCH_STATUS = 0
         begin
            LOG(@lLog_level,@lMessage);
            fetch next from cur_log into @lLog_level,@lMessage;
         end;
      END_TRANSACTION;
      CLOSE_DEALLOCATE_CURSOR(cur_log);
   end;
   
   DEBUG('Transaction count: '+cast(@@trancount as nvarchar(10))+'.');
   set @lEndDate = getutcdate()
   exec FRAMEWORK_SCHEMA.SF_UpdateBatchStatus
       'XFUNC_NAME'
      ,@lStartDate
      ,@lEndDate
      ,@lErrCount
      ,@lTabCount
      ,'Cleaned out active tables mentioned in SCHEMA.CleanUpTableInfo.'
      ,TRUE_NR
      ,default;
END_PROCEDURE;
