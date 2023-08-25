truncate table processado.f_detalhe_municipio_conectividade_areasprioritarias;

insert into processado.f_detalhe_municipio_conectividade_areasprioritarias
	
	select 
		q2.id_conectividade_funcional,		
		q1.id_municipio
--		into processado.f_detalhe_municipio_conectividade_areasprioritarias
from 
	(
	select
		dptsa.id_municipio,
		dptsg.geom
	from processado.d_malha_municipal_alfa dptsa
	join processado.d_malha_municipal_geo dptsg on dptsa.id_municipio = dptsg.id_municipio 
		) q1
	join 	
	(select dap.id_conectividade_funcional, tcef.geom 
	from processado.d_areas_prioritarias dap 
	join processado.d_conectividade_funcional_geo tcef on tcef.id_conectividade_funcional = dap.id_conectividade_funcional) 
	 q2 on st_intersects(q1.geom,q2.geom)
;