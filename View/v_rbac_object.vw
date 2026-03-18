/*****************************************************************
*  Package Info
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: 2026-02-16 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*   Copyright       : $Equinor ASA: $
*****************************************************************
* Description
* 
*****************************************************************
* Log
* Date   Description                                     Done by
* 
*****************************************************************/
CREATE_VIEW(SCHEMA.v_rbac_object)
as
with xres as (select d.name as db_name
      ,sch.name as schema_name
      ,d.st_id as db_st_id
      ,sch.st_id as schema_st_id
       from SCHEMA.rbac_database d
   inner join SCHEMA.rbac_object as sch
      on d.st_id = sch.rbac_database_st_id
      and sch.parent_st_id is null
  )
select x.*, ob.* 
   from SCHEMA.rbac_object as ob
   inner join xres as x
    on x.schema_st_id = ob.parent_st_id;
