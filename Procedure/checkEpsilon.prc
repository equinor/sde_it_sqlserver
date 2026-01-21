CREATE_FUNCTION(checkEpsilon)(lName varchar2,lActualCount int,lExpectedCount int)
  return int
  authid definer  
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
*
*****************************************************************/  
is
   STANDARD_VARIABLE;
   @lLower  nvarchar(50);
   @lLower_unit nvarchar(50);
   @lUpper  nvarchar(50);
   @lUpper_unit nvarchar(50);
   @lDiff integer = 0;
   @lRetValue integer = 0;
   @lExpCount integer; -- used instead of lExpectedCount due to assignment.
begin
   set @lExpCount = lExpectedCount;
   if @lExpCount = 0 and @lActualCount = 0 then
      return 0;
   end if;
      
   select @lLower=lower
         ,@lLower_unit = lower_unit
         ,@lUpper = upper
         ,@lUpper_unit = upper_unit
      from sde_it.epsilon
      where lower(name) = lower(lName);

   ---------------------------------------------------------
   -- Doesn't work too well if  lExpectedCount=0
   -- Dirty trick: set lExpCount to 1 (one) if lExpectedCount=0
   ---------------------------------------------------------
   lDiff := lActualCount-lExpCount;
   DEBUG(lName||': Lower='||lLower||' Lower_unit='||lLower_unit||' lDiff='||lDiff);
   if (lLower >= 0 and lDiff <= 0) then
      if (lLower_unit in ('procent','absolute')) then
         if lLower_unit in ('procent') then
            DEBUG(lName||': Procent='||lDiff*100/lExpCount);
            if (lExpCount=0) then lExpCount:=1; end if;
            if (lExpCount > 0 and abs(lDiff)*100/lExpCount > lLower) then
               lRetValue := -1;
            end if;
         elsif (abs(lDiff) > lLower) then  -- absolute check
            lRetValue := -1;
         end if;
      end if;       
   end if;

   ----------------------------------------------
   -- Only do this if the lower-check did not uncover
   -- any issues.
   ----------------------------------------------
   DEBUG(lName||': Upper_unit='||lUpper_unit||' lDiff='||lDiff);
   if (lRetValue = 0 and lUpper >= 0 and lDiff >= 0) then
      if (lUpper_unit in ('procent','absolute')) then
         if lUpper_unit in ('procent') then
            DEBUG(lName||': Procent='||lDiff*100/lExpCount);
            if (lExpCount=0) then lExpCount:=1; end if;
            if (lExpCount > 0 and lDiff*100/lExpCount > lUpper) then
               lRetValue := 1;
            end if;
         elsif (lDiff > lUpper) then  -- absolute check
            lRetValue := 1;
         end if;
      end if;
   end if;
   return lRetValue;
EXCEPTION_BLOCK
   when no_data_found then
      DEBUG('logging '||lName);
      LOG(1,'No epsilon data found for '||coalesce(lName,'Name is null'));
      return null;
   THROW_EXCEPTION_HANDLER;
END_CREATE_FUNCTION;
