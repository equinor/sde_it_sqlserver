CREATE_FUNCTION(checkEpsilon)(@lName nvarchar
   ,@lActualCount integer
   ,@lExpectedCount integer
   )
  returns integer
  --authid definer  
/*****************************************************************
*  Function Info
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: 2018/04/28 10:32:56 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header: JOTHOR Exp $
*   Revision History: $Revision: 1.0 $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
* Checks if tolerance exceeds an epsilon. Epsilon can be either
* given as a percentage for a absolute tolerance.
*
* Should be executed as definer, since access to the table "epsilon"
* is accessed. The function, however, should be granted to public.
*
* Return values:
*  -1 the lower tolerance exceeded.
*   0 acceptable tolerance
*   1 the upper tolerance exceeded.
* null entry for "lName" not found. This is logged. No exception
*     is thrown.
*****************************************************************
* Log
* Date   Description                                        Done by
* 210126 Translated from Oracle to Sqlserver                JOTHOR
*****************************************************************/  
as
begin
   STANDARD_VARIABLE;
   declare @lLower  nvarchar(50)
      ,@lLower_unit nvarchar(50)
      ,@lUpper  nvarchar(50)
      ,@lUpper_unit nvarchar(50)
      ,@lDiff integer = 0
      ,@lRetValue integer = 0
      ,@lExpCount integer; -- used instead of lExpectedCount due to assignment.
      
   -- B EGIN_EXCEPTION
      set @lExpCount = @lExpectedCount;
      if @lExpCount = 0 and @lActualCount = 0 
      begin
         return 0;
      end;
         
      select @lLower=lower
            ,@lLower_unit = lower_unit
            ,@lUpper = upper
            ,@lUpper_unit = upper_unit
         from sde_it.epsilon
         where lower(name) = lower(@lName);
      if (GET_ROWCOUNT = 0)
      begin
         return 1;
         --THROW_DATA_NOT_FOUND_EXCEPTION('sde_it.epsilon');
      end;
      
      ---------------------------------------------------------
      -- Doesn't work too well if  lExpectedCount=0
      -- Dirty trick: set lExpCount to 1 (one) if lExpectedCount=0
      ---------------------------------------------------------
      set @lDiff = @lActualCount-@lExpCount;
      DEBUG(@lName+': Lower='+@lLower+' Lower_unit='+@lLower_unit+' lDiff='+@lDiff);
      if (@lLower >= 0 and @lDiff <= 0)
      begin
         if (@lLower_unit in ('procent','absolute')) 
         begin
            if @lLower_unit in ('procent')
            begin
               DEBUG(@lName+': Procent='+@lDiff*100/@lExpCount);
               if (@lExpCount=0)
               begin
                  set @lExpCount=1;
               end;
               
               if (@lExpCount > 0 and abs(@lDiff)*100/@lExpCount > @lLower)
               begin
                  set @lRetValue = -1;
               end;
            end
            else if (abs(@lDiff) > @lLower)  -- absolute check
            begin
               set @lRetValue = -1;
            end;
         end;       
      end;

      ----------------------------------------------
      -- Only do this if the lower-check did not uncover
      -- any issues.
      ----------------------------------------------
      DEBUG(@lName+': Upper_unit='+@lUpper_unit+' lDiff='+@lDiff);
      if (@lRetValue = 0 and @lUpper >= 0 and @lDiff >= 0)
      begin
         if (@lUpper_unit in ('procent','absolute'))
         begin
            if @lUpper_unit in ('procent')
            begin
               DEBUG(@lName+': Procent='+@lDiff*100/@lExpCount);
               if (@lExpCount=0) set @lExpCount=1;
               if (@lExpCount > 0 and @lDiff*100/@lExpCount > @lUpper)
               begin
                  set @lRetValue = 1;
               end;
            end
            else if (@lDiff > @lUpper)  -- absolute check
            begin
              set @lRetValue = 1;
            end;
         end;
      end;
      return @lRetValue;
  -- E-XCEPTION
         DEBUG('logging '+@lName);
         LOG(1,'No epsilon data found for '+coalesce(@lName,'Name is null'));
         return null;
      --T HROW_EXCEPTION_HANDLER;
   --E ND_EXCEPTION;
END_CREATE_FUNCTION;
