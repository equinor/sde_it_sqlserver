CREATE_PROCEDURE(FRAMEWORK_SCHEMA.logError)(@lLevel integer
      ,@lApplication nvarchar
      ,@lVersion nvarchar
      ,@lMessage nvarchar
      ,@lHost nvarchar = 'NA'
      )
   as
/*****************************************************************
* Package Info
* Author          : $Author: JOTHOR $
* Original Date   : $Date: 2007/03/23 13:46:23 $
* Last Modified   : $Modtime:  $
* Archive Name    : $Archive:  $
* Description     : $Header: 2.13 2007/03/23 13:46:23 JOTHOR Exp $
* Revision History: $Revision: 2.13 $
* Workfile        : $Workfile: Oracle ErrorHandler.pcb $
* Copyright info  : Copyright (c), Equinor ASA,Norway. $Date: 2024-11-14 $
*****************************************************************
* Description
* Read about "xp_ora2ms_exec2_ex" for details on autonomous transactions.
* NOTE: ERRORHANDLER$LOGERROR.prc is a translation of Oracle autonomous transaction
*  code. Doesn't compile/work. However should it work, alter this procedure
*  to use it.
*
* Log errors of level high regardless of setting.
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
* Date   Description                                        Done by
* 141124 Translated from Oracle                             JOTHOR
*****************************************************************/
      STANDARD_VARIABLE;
      --P RAGMA AUTONOMOUS_TRANSACTION;
      declare @lStr nvarchar(500)
             ,@lVer nvarchar(100)
             ,@lUser nvarchar(100)
             ,@lGetMaxMessageLength integer = 255;
   BEGIN_EXCEPTION
      if (@lLevel != LEVEL_HIGH and @lLevel > 4) --xLevel) -- xLevel is 
       MCR_RETURN;
      --end;

      if (@lMessage is null)
         set @lStr = 'N/A';
      else if (len(@lMessage) > @lGetMaxMessageLength)
         set @lStr = substring(@lMessage,1,@lGetMaxMessageLength);
      else
         set @lStr = @lMessage;
      --end;

      if (@lVersion is null)
         set @lVer = 'N/A';
      else
         set @lVer = @lVersion;
      --end;
      
      BEGIN_TRANSACTION
         insert into FRAMEWORK_SCHEMA.t_basis_clienterrorlog(
             applicationname
            ,applicationversion
            ,userregistered
            ,messagecode
            ,messagetext
            ,host
            )
            values (
             @lApplication
            ,@lVer
            ,@lUser
            ,@lLevel
            ,@lStr
            ,@lHost
            );

      END_TRANSACTION; --commit;
  EXCEPTION
    -- Start consume exception. Best effort-> print.
    set @z_debug_str = '4: 0:'+'Consume exception:'+error_message();print @z_debug_str;
    -- End consume exception;
  END_EXCEPTION;
--E ND_PROCEDURE;