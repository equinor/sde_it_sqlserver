select * from SDE_IT.DBA_AUDIT_HIST

select distinct fqn_object from SDE_IT.V_OBJECT_USAGE_STATISTIC where fqn_object like 'IA%'

select distinct  year,month,fqn_object,start_time from SDE_IT.V_OBJECT_USAGE_STATISTIC order by year,month,start_time,fqn_object

--with xres as (select distinct * from SDE_IT.V_OBJECT_USAGE_STATISTIC)
select year,month,fqn_object,count(*) from SDE_IT.V_OBJECT_USAGE_STATISTIC
where process_owner not in ('IRSDE','A_DHIL@STATOIL.NET','F_GIS_BATCH_TEST@STATOIL.NET','F_IRIS21_BATCH@STATOIL.NET','A_JEMOE@STATOIL.NET')
group by year,month,fqn_object 
order by year,month,count(*) 
--order by count(*) desc,year,month

with xres as (select distinct  process_owner,year,month,v.start_time
  ,case when fqn_object = 'IA.IA_BLOCKS' then  'IR_ISL.BLOCKS'
     when fqn_object = 'IA.IA_PLATFORMS' then     'IR_ISL.PLATFORMS'
     when fqn_object = 'IA.IA_BLOCKS_INT' then 'ISL.BLOCKS_INT'
     when fqn_object = 'IA.IA_ELECTRIC_PLANTS' then 'ISL.ELECTRIC_PLANTS'
     when fqn_object = 'IA.IA_FIELDS' then 'IR_ISL.FIELDS'
     when fqn_object = 'IA.IA_FIELDS_POINTS' then 'IR_ISL.FIELDS_POINT'
     when fqn_object = 'IA.IA_GAS_PLANTS' then 'IR_ISL.'
     when fqn_object = 'IA.IA_LIQUIFICATIONS' then 'IR_ISL.LIQUIFICATIONS'
     when fqn_object = 'IA.IA_METHANOLS' then 'IR_ISL.METHANOL_PLANTS'
     when fqn_object = 'IA.IA_PETROCHEM_PLANTS' then 'IR_ISL.PETROCHEM_PLANTS'
     when fqn_object = 'IA.IA_PIPELINES' then 'IR_ISL.PIPELINES'
     when fqn_object = 'IA.IA_PLATFORMS' then 'IR_ISL.PLATFORMS'
     when fqn_object = 'IA.IA_PORTS' then 'IR_ISL.PORTS'
     when fqn_object = 'IA.IA_PROSPECTS' then 'IR_ISL.PROSPECTS'
     when fqn_object = 'IA.IA_REFINERIES' then 'IR_ISL.REFINERIES'
     when fqn_object = 'IA.IA_REGASIFICATIONS' then 'IR_ISL.'
     when fqn_object = 'IA.IA_SURVEYS' then 'IR_ISL.REGASIFICATIONS'
     when fqn_object = 'IA.IA_WELLS' then 'IR_ISL.WELLS'
     else fqn_object
   end as fqn_object
    from SDE_IT.V_OBJECT_USAGE_STATISTIC  v
   where fqn_object not like 'SDE.%'
   and process_owner not like 'A\_%' escape '\'
   )
select distinct year,fqn_object,count(*) 
from xres --SDE_IT.V_OBJECT_USAGE_STATISTIC
where process_owner not in ('IRSDE','F_GIS_BATCH_TEST@STATOIL.NET','F_IRIS21_BATCH@STATOIL.NET')
group by year,fqn_object
--order by year,month,count(*) 
order by count(*) desc,year,fqn_object

select * from dba_users where username like  '%JEMOE@STATOIL.NET'

select distinct * from SDE_IT.V_OBJECT_USAGE_STATISTIC
where fqn_object in ('IR_ISL.PIPELINES')