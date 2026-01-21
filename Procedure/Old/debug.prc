CREATE_PROCEDURE(SCHEMA.debug)(@lLevel integer,@lMessage nvarchar(4000))
as
/*****************************************************************
* Package Info
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 2007/03/23 13:46:23 $
* Last Modified   : $Modtime: 15.12.05 14:35 $
* Archive Name    : $Archive:  $
* Description     : $Header:  Exp $
* Revision History: $Revision: 2.13 $
* Workfile        : $Workfile: ErrorHandler.pcb $
* Copyright info  : Copyright (c), Statoil ASA,Norway. $Date: 2007/03/23 13:46:23 $
*****************************************************************
* Description
*
* NOTE: Do not use usererrror,dberror or systemerror. Use e.g
*  raise_application_error(USERERROR_CODE,'my text explaining the situation');
* This because interaction with the database may be faulty, and
* database interaction should be kept to a minimum.
*
* It is vital that no expections are propagated when logging or debugging
* from this package.
*
* Delimiters.
* Please do not use delimiters which are the same as used in regular 
* expressions (e.g {,},$,^ etc
*****************************************************************
* Log
* Date  Description                                      Done by
*
*****************************************************************/
  STANDARD_VARIABLE;

  --ex_bufferLengthExceeded exception; 
  --P RAGMA EXCEPTION_INIT(ex_bufferLengthExceeded, -6502); 

   declare @lStr nvarchar(4000);
   declare @lMaxLen integer = 255;
   declare @xLevel integer = 5;
BEGIN_EXCEPTION
   if (@lLevel > @xLevel)
     MCR_RETURN;

   if (@lMessage is null or len(@lMessage) = 0)
      MCR_RETURN;

   -----------------------------------------------------------------
   -- When printing to standard output, the max line length is 255.
   -- If the message exceeds this length, it must be split and written
   -- over several lines.
   -----------------------------------------------------------------
   if if (len(@lMessage) <= @lMaxLen)
      print @lMessage;
   else
   begin
      set @lStr = @lMessage;
      while 1 = 1 and len(@lStr) > 0 
      begin
         print '->'+substring(@lStr,1, @lMaxLen);
         set @lStr = substring(@lStr,@lMaxLen+1,4000);
         if (len(@lStr) < @lMaxLen) break;
      end;
   end;
EXCEPTION
   CONSUME_EXCEPTION_HANDLER;
END_EXCEPTION
--E ND_CREATE_PROCEDURE;