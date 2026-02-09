/************************************************************
*  Procedure Info
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: 06.12.2022 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
* See 
* Perform maintenance on sde_it.t_basis_clientmessage as the associate
*  trigger will update the sys.messages table correctly
* https://learn.microsoft.com/en-us/sql/t-sql/language-elements/throw-transact-sql?view=sql-server-ver16
* 
* Raiseerror - do not use
* https://learn.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql?view=sql-server-ver16

Raiseerror
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

* Severity levels
* https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-error-severities?view=sql-server-ver17
************************************************************/
/*begin tran
   exec sp_addmessage @msgnum = 50001,@severity = 11, @msgtext= N'Failed to delete %s.';
   exec sp_addmessage @msgnum = 50002,@severity = 11, @msgtext= N'Failed to delete %s. %s has children in %s';
   exec sp_addmessage @msgnum = 50003,@severity = 11, @msgtext= N'Failed to delete %s. %s is a member of %s in %s';
   exec sp_addmessage @msgnum = 50004,@severity = 11, @msgtext= N'Failed to insert %s.';
   exec sp_addmessage @msgnum = 50005,@severity = 11, @msgtext= N'Failed to insert %s. A parent in %s is mandatory.';
   exec sp_addmessage @msgnum = 50006,@severity = 11, @msgtext= N'An instance with the value %s in %s already exists.';
   exec sp_addmessage @msgnum = 50007,@severity = 11, @msgtext= N'Detail %s in %s does not have an owner in %s.';
   exec sp_addmessage @msgnum = 50008,@severity = 11, @msgtext= N'The value <%s> is outside of range. Legal range is %s to %s.';
   exec sp_addmessage @msgnum = 50009,@severity = 11, @msgtext= N'Illegal value <%s>. Legal value(s): %s.';
   exec sp_addmessage @msgnum = 50010,@severity = 11, @msgtext= N'End date must be after start date.';
   exec sp_addmessage @msgnum = 50011,@severity = 11, @msgtext= N'The field %s is mandatory and is to be supplied.';
   exec sp_addmessage @msgnum = 50012,@severity = 11, @msgtext= N'The %s does not exist.';
   exec sp_addmessage @msgnum = 50013,@severity = 11, @msgtext= N'The %s with key=<%s> does not exist.';
   exec sp_addmessage @msgnum = 50014,@severity = 11, @msgtext= N'Failed to update %s.';
   exec sp_addmessage @msgnum = 50015,@severity = 11, @msgtext= N'Failed to update %s. A parent in %s is mandatory.';
   exec sp_addmessage @msgnum = 50016,@severity = 11, @msgtext= N'Failed to associate %s with %s. %s.';
   exec sp_addmessage @msgnum = 50017,@severity = 11, @msgtext= N'Failed to disassociate %s from %s. %s.';
   exec sp_addmessage @msgnum = 50018,@severity = 11, @msgtext= N'Illegal to update key value %s in %s.';
   exec sp_addmessage @msgnum = 50019,@severity = 11, @msgtext= N'The %s of %s has been rejected. The instance has been updated by somebody else.';
   exec sp_addmessage @msgnum = 50020,@severity = 11, @msgtext= N'%s.';
   exec sp_addmessage @msgnum = 50021,@severity = 11, @msgtext= N'System error occurred. Please contact the system administrator.';
   exec sp_addmessage @msgnum = 50022,@severity = 11, @msgtext= N'Database error occurred. Please contact the system administrator.';
   exec sp_addmessage @msgnum = 50023,@severity = 11, @msgtext= N'The attributes <%s> and <%s> are mutually exclusive.';
   exec sp_addmessage @msgnum = 50024,@severity = 11, @msgtext= N'The supplied attribute <%s> cannot be null.';
   exec sp_addmessage @msgnum = 50025,@severity = 11, @msgtext= N'Not implemented yet.';
   exec sp_addmessage @msgnum = 50026,@severity = 11, @msgtext= N'Missing data in %s. Abs diff = %s.';
   exec sp_addmessage @msgnum = 50027,@severity = 11, @msgtext= N'Missing data in %s. Procent diff = %s.';
   exec sp_addmessage @msgnum = 50028,@severity = 11, @msgtext= N'Missing data in %s. Abs diff = %s. Procent diff = %s%.';
   exec sp_addmessage @msgnum = 50029,@severity = 11, @msgtext= N'Mulitple instances found for %s.';
   exec sp_addmessage @msgnum = 50030,@severity = 11, @msgtext= N'Arc: Table %s violates constraint on %s. Discriminator column ''%s'' doesn''t have value ''%s''.';
   exec sp_addmessage @msgnum = 50031,@severity = 11, @msgtext= N'Addtional data in %s. Abs diff = %s.';
   exec sp_addmessage @msgnum = 50032,@severity = 11, @msgtext= N'Addtional data in %s. Procent diff = %s.';
   exec sp_addmessage @msgnum = 50033,@severity = 11, @msgtext= N'Addtional data in %s. Abs diff = %s. Procent diff = %s%.';
   exec sp_addmessage @msgnum = 50034,@severity = 11, @msgtext= N'No data found for %s.';
commit;
*/
/*comment on table FRAMEWORK_SCHEMA.t_basis_clientmessage is 'ARC explanation of paramenters for code #30
  1: current table, 2: table with discriminator, 3: discriminator column in table #2, 4: discriminator value
  Table (1)procurement_exp violates Arc constraint on Table (2)procurement - discriminator column (3)procurement_type doesn''t have value (4)''EXP''.';
*/