/************************************************************
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: 2014/05/22 07:32:22 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header: F:\Private\Repository/ITOPP-UBA/Gis/Procedure/sde_WhoIsLocking.sql,v 1.5 2014/05/22 07:32:22 JOTHOR Exp $
*   Revision History: $Revision: 1.5 $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*****************************************************************
* Description
* Lists all tables which are locked and who is locking.
* Use http://arcgis.statoil.no/license/ to identify the actual username
*
* Queries available:
-- Who is locking
-- Provides the list of processes to kill
-- Phantom objects hunt? Uncertain if correct
************************************************************/

-------------------------------------------------------------
-- Who is locking
-------------------------------------------------------------
select distinct p.nodename,p.direct_connect,P.START_TIME,P.SDE_ID,t.*,l.* from sde.table_registry t,sde.table_locks l
,sde.process_information p
where t.REGISTRATION_ID = l.REGISTRATION_ID
and p.SDE_ID = l.SDE_ID
and p.nodename like '%'
--and p.start_time < to_date('01.06.2021','dd.mm.yyyy')
and t.owner = 'GLI_API'
and regexp_like(t.TABLE_NAME,'GLI_(WGS|[0-9])+.*(PNT|LN|PLY|AGG|MRG).*');

-------------------------------------------------------------
-- Provides the list of processes to kill
-- NOTE: The server_id (server process) is not of interest.
--    It is the SDE_ID which is of interest.
-------------------------------------------------------------
select distinct T.TABLE_NAME,'sdemon -o kill -t '||p.sde_id||' -N -p xxx'
,'delete from sde.table_locks where sde_id = '||p.sde_id||';'
,p.nodename
 from sde.table_registry t,sde.table_locks l
     ,sde.process_information p
where t.REGISTRATION_ID = l.REGISTRATION_ID
and p.SDE_ID = l.SDE_ID
and p.nodename like '%'
and t.owner = 'GLI_API'
and regexp_like(t.TABLE_NAME,'GLI_(WGS|[0-9])+.*(PNT|LN|PLY|AGG|MRG).*');

select distinct t.table_name
,'sdemon -o kill -t '||p.sde_id||' -N -p xxx'
,'delete from sde.layer_locks where sde_id = '||p.sde_id||';'
,p.nodename
 from sde.layers t,sde.layer_locks l
     ,sde.process_information p
where T.LAYER_ID = l.LAYER_ID
and p.SDE_ID = l.SDE_ID
and p.nodename like '%'
and t.owner = 'GLI_API'
and regexp_like(t.TABLE_NAME,'GLI_(WGS|[0-9])+.*(PNT|LN|PLY|AGG|MRG).*');

begin

COMMIT;
end;

declare
  cursor cur_data
    is select distinct t.table_name 
        ,'delete from sde.table_locks where sde_id = '||p.sde_id as del_statement
        from sde.table_registry t,sde.table_locks l,sde.process_information p
        where t.REGISTRATION_ID = l.REGISTRATION_ID and p.SDE_ID = l.SDE_ID
        and p.nodename like '%'
        and t.owner = 'GLI_API'
        and regexp_like(t.table_name,'GLI_(WGS|[0-9])+.*(PNT|LN|PLY|AGG|MRG).*')
      --and p.start_time < to_date('01.06.2021','dd.mm.yyyy')
        order by t.table_name;
begin
  for i in cur_data
  loop
    dbms_output.put_line('Deleting table lock on >'||i.table_name||'<.');
    execute immediate i.del_statement;
    commit;
  end loop;
exception
  when others then rollback;raise;  
end;

-------------------------------------------------------------
-- Phantom objects hunt? Uncertain if correct
-------------------------------------------------------------
select * from dba_objects d
   inner join sde.table_registry t 
   on d.owner=t.owner
where d.owner='GLI_API'    
and d.object_type in ('TABLE','VIEW')
and regexp_like(d.object_name,'[FS]'||t.registration_id)