/*****************************************************************
*  Package Info
*   Author          : $Author: JOTHOR $
*   Original Date   : $Date: 2026-03-18 $
*   Last Modified   : $Modtime: $
*   Archive Name    : $Archive: $
*   Description     : $Header:  $
*   Revision History: $Revision: $
*   Tag name        : $Name:  $
*   Workfile        : $Workfile: $
*   Copyright       : $Equinor ASA: $
*****************************************************************
* Description
* Displays actor role association
*****************************************************************
* Log
* Date   Description                                     Done by
* 
*****************************************************************/
CREATE_VIEW(SCHEMA.v_rbac_actor_role)
as
select ac.name as actor_name
      ,ac.is_active as actor_is_active
      ,r.name as role_name
      ,r.is_active as role_is_active
      ,r.is_system_role
      ,ac.st_id as actor_st_id
      ,r.st_id as role_st_id
      ,r.parent_st_id as role_parent_st_id
   from sde_it.rbac_actor ac
   left join sde_it.rbac_actor_role acr
      on ac.st_id = acr.rbac_actor_st_id
   left join sde_it.rbac_role r
      on acr.rbac_role_st_id = r.st_id