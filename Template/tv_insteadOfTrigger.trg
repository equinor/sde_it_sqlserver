CREATE_TRIGGER(tv_{view_table_name})
   instead of insert or update or delete 
   on {view_table_name}
/*****************************************************************
*  Package Info
*   Author          : $Author:  $
*   Original Date   : $Date:  $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*   Copyright       : $Equinor ASA: $
*****************************************************************
* Description
* When inserting, one has access to :new.
* When updating, one has access to both :new and :old.
* When deleting, one has access to :old only.
*****************************************************************
* Log
* Date   Description                                        Done by
*
*****************************************************************/
declare
   STANDARD_VARIABLE;
   lxxxId integer := null;
   lCount integer := 0;
begin
   if (inserting or updating) then
      select st_id into lxxxId
         from {yyy_table_name}
         where identifier = :new.xxx_identifier;
      if (inserting) then
         if (lCount != 0) then
            USERERROR(6,:new.xxx_identifier||,'{view_table_name}');
         end if;
         insert into {base_table_name}(block_id,conpart_id)
            values(lBlockID,lConpartID);
         DEBUG('Insert (new values: '||:new.xxx_identifier||'). Rows:'||sql%rowcount||'.');
      elsif (updating) then
         -- Dangerous as spatial has not been handled.
         update {base_table_name}
            set xxx_id = lxxxId;
         DEBUG('Updated (new values:'||:new.xxx||'). Rows:'||sql%rowcount||'.');         
         /*LOG(LEVEL_HIGH,'Updated block-conpart(old values:'||:old.block_identifier||').');*/
      end if;
   elsif (deleting) then
      select st_id into lBlockConpartId 
         from {view_table_name} 
         where xxx_id = lxxxId;
      delete from {base_table_name}
         where st_id = lxxxId;

      DEBUG('Deleted (values:'||:old.xxx_identifier||'). Rows:'||sql%rowcount||'.');
      /*LOG(LEVEL_HIGH,'Deleted {view_table_name} (old values:'||:old.xxx_identifier||').');*/
   end if;
EXCEPTION_BLOCK
   when no_data_found then
      case when lxxxId is null then
         USERERROR(12,xxx_identifier);
      else
         THROW_EXCEPTION;
      end case;
   THROW_EXCEPTION_HANDLER;
END_TRIGGER;
