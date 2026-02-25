CREATE_FUNCTION(SCHEMA.convertInteger2Binary_str)(@lNumber integer)
   returns nvarchar(40)
as
--with execute ???
--with execute as owner
/*****************************************************************
*  Program Info
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: 2026-02-25 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: 1.0 $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*   Copyright       : $Equinor ASA: $
*****************************************************************
* Description
* Converts an integer to a binary representes back as at string.
*  E.g. given 25 it returns, as a string': 11001
*****************************************************************
* Log
* Date   Description                                        Done by
* 
*****************************************************************/
begin
   STANDARD_VARIABLE;
   -- Recommended
   --set nocount on;
   if (@lNumber is null or @lNumber < 0)
   begin
      DEBUG('Number must be positive 0 or greater');
      return null;
   end;
   
   declare @intvalue int = @lNumber
      ,@binarystring nvarchar(100) = N'';

   while @intvalue > 0
   begin
       set @binarystring = cast(@intvalue % 2 as nvarchar(1)) + @binarystring;
       set @intvalue = @intvalue / 2;
   end;

   return @binarystring;
END_CREATE_FUNCTION;
