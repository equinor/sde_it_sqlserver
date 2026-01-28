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
* Throw
* https://learn.microsoft.com/en-us/sql/t-sql/language-elements/throw-transact-sql?view=sql-server-ver16
* 
* Raiseerror - do not use
* https://learn.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql?view=sql-server-ver16

* Severity levels
* https://learn.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-error-severities?view=sql-server-ver17
************************************************************/
begin tran
   exec sp_addmessage @msgnum = 1+50000,@severity = 11, @msgtext= N'Failed to delete %s.';
   exec sp_addmessage @msgnum = 2+50000,@severity = 11, @msgtext= N'Failed to delete %s. %s has children in %s';
   exec sp_addmessage @msgnum = 3+50000,@severity = 11, @msgtext= N'Failed to delete %s. %s is a member of %s in %s';
   exec sp_addmessage @msgnum = 4+50000,@severity = 11, @msgtext= N'Failed to insert %s.';
   exec sp_addmessage @msgnum = 5+50000,@severity = 11, @msgtext= N'Failed to insert %s. A parent in %s is mandatory.';
   exec sp_addmessage @msgnum = 6+50000,@severity = 11, @msgtext= N'An instance with the value %s in %s already exists.';
   exec sp_addmessage @msgnum = 7+50000,@severity = 11, @msgtext= N'Detail %s in %s does not have an owner in %s.';
   exec sp_addmessage @msgnum = 8+50000,@severity = 11, @msgtext= N'The value <%s> is outside of range. Legal range is %s to %s.';
   exec sp_addmessage @msgnum = 9+50000,@severity = 11, @msgtext= N'Illegal value <%s>. Legal value(s): %s.';
   exec sp_addmessage @msgnum = 10+50000,@severity = 11, @msgtext= N'End date must be after start date.';
   exec sp_addmessage @msgnum = 11+50000,@severity = 11, @msgtext= N'The field %s is mandatory and is to be supplied.';
   exec sp_addmessage @msgnum = 12+50000,@severity = 11, @msgtext= N'The %s does not exist.';
   exec sp_addmessage @msgnum = 13+50000,@severity = 11, @msgtext= N'The %s with key=<%s> does not exist.';
   exec sp_addmessage @msgnum = 14+50000,@severity = 11, @msgtext= N'Failed to update %s.';
   exec sp_addmessage @msgnum = 15+50000,@severity = 11, @msgtext= N'Failed to update %s. A parent in %s is mandatory.';
   exec sp_addmessage @msgnum = 16+50000,@severity = 11, @msgtext= N'Failed to associate %s with %s. %s.';
   exec sp_addmessage @msgnum = 17+50000,@severity = 11, @msgtext= N'Failed to disassociate %s from %s. %s.';
   exec sp_addmessage @msgnum = 18+50000,@severity = 11, @msgtext= N'Illegal to update key value %s in %s.';
   exec sp_addmessage @msgnum = 19+50000,@severity = 11, @msgtext= N'The %s of %s has been rejected. The instance has been updated by somebody else.';
   exec sp_addmessage @msgnum = 20+50000,@severity = 11, @msgtext= N'%s.';
   exec sp_addmessage @msgnum = 21+50000,@severity = 11, @msgtext= N'System error occurred. Please contact the system administrator.';
   exec sp_addmessage @msgnum = 22+50000,@severity = 11, @msgtext= N'Database error occurred. Please contact the system administrator.';
   exec sp_addmessage @msgnum = 23+50000,@severity = 11, @msgtext= N'The attributes <%s> and <%s> are mutually exclusive.';
   exec sp_addmessage @msgnum = 24+50000,@severity = 11, @msgtext= N'The supplied attribute <%s> cannot be null.';
   exec sp_addmessage @msgnum = 25+50000,@severity = 11, @msgtext= N'Not implemented yet.';
   exec sp_addmessage @msgnum = 26+50000,@severity = 11, @msgtext= N'Missing data in %s. Abs diff = %s.';
   exec sp_addmessage @msgnum = 27+50000,@severity = 11, @msgtext= N'Missing data in %s. Procent diff = %s.';
   exec sp_addmessage @msgnum = 28+50000,@severity = 11, @msgtext= N'Missing data in %s. Abs diff = %s. Procent diff = %s%.';
   exec sp_addmessage @msgnum = 29+50000,@severity = 11, @msgtext= N'Mulitple instances found for %s.';
   exec sp_addmessage @msgnum = 30+50000,@severity = 11, @msgtext= N'Arc: Table %s violates constraint on %s. Discriminator column ''%s'' doesn''t have value ''%s''.';
   exec sp_addmessage @msgnum = 31+50000,@severity = 11, @msgtext= N'Addtional data in %s. Abs diff = %s.';
   exec sp_addmessage @msgnum = 32+50000,@severity = 11, @msgtext= N'Addtional data in %s. Procent diff = %s.';
   exec sp_addmessage @msgnum = 33+50000,@severity = 11, @msgtext= N'Addtional data in %s. Abs diff = %s. Procent diff = %s%.';
   exec sp_addmessage @msgnum = 34+50000,@severity = 11, @msgtext= N'No data found for %s.';
commit;
/*comment on table FRAMEWORK_SCHEMA.t_basis_clientmessage is 'ARC explanation of paramenters for code #30
  1: current table, 2: table with discriminator, 3: discriminator column in table #2, 4: discriminator value
  Table (1)procurement_exp violates Arc constraint on Table (2)procurement - discriminator column (3)procurement_type doesn''t have value (4)''EXP''.';
*/