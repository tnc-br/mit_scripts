truncate table processado.f_detalhe_ts_conectividade_areasprioritarias;

insert into processado.f_detalhe_ts_conectividade_areasprioritarias
	
	select 
		q2.id_conectividade_funcional,		
		q1.id_ps
--		into processado.f_detalhe_ts_conectividade_areasprioritarias
from 
	(
	select
		dptsa.id_ps,
		dptsg.geom
	from processado.d_programa_territorios_sustentaveis_alfa dptsa
	join processado.d_programa_territorios_sustentaveis_geo dptsg on dptsa.id_ps = dptsg.id_ps 
		) q1
	join 	
	(select dap.id_conectividade_funcional, tcef.geom 
	from processado.d_areas_prioritarias dap 
	join processado.d_conectividade_funcional_geo tcef on tcef.id_conectividade_funcional = dap.id_conectividade_funcional) 
	 q2 on st_intersects(q1.geom,q2.geom)
;
     
