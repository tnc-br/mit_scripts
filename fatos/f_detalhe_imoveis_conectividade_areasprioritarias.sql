truncate table  processado.f_detalhe_imoveis_conectividade_areasprioritarias;

insert into processado.f_detalhe_imoveis_conectividade_areasprioritarias
	
select 
		q2.id_conectividade_funcional,		
		q1.id_imovel
--		into processado.f_detalhe_imoveis_conectividade_areasprioritarias
from 
	(
	select
		dia.id_imovel,
		dig.geom
	from processado.d_imoveis_alfa dia 
	join processado.d_imoveis_geo dig   on dia.id_imovel = dig.id_imovel 
	where dia.num_flg_ativo = true and dia.tx_status_imovel not in ('CA','RE','SU')
--	LIMIT 1000
		) q1
	join 	
	(select dap.id_conectividade_funcional, tcef.geom 
	from processado.d_areas_prioritarias dap 
	join processado.d_conectividade_funcional_geo tcef on tcef.id_conectividade_funcional = dap.id_conectividade_funcional) 
	 q2 on st_intersects(q1.geom,q2.geom)
;
     
