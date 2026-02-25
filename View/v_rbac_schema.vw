/*****************************************************************
* Audit trigger
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
CREATE_VIEW(SCHEMA.v_rbac_schema)
as
select d.name as db_name
      ,d.st_id as db_st_id
      ,sch.*
       from sde_it.rbac_database d
   inner join sde_it.rbac_object as sch
      on d.st_id = sch.rbac_database_st_id
      and sch.parent_st_id is null;

