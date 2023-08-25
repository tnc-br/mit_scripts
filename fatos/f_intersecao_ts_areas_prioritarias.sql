truncate table processado.f_intersecao_ts_areas_prioritarias;

with nuclear as (
select dptsa.id_ps, dptsa.tx_nome,  count(fdts.id_estrutura_florestal)as  qtd_nuclear,  sum(fdts.area) as area_nuclear 
from processado.f_detalhe_ts_estrutura2 fdts
join processado.d_programa_territorios_sustentaveis_alfa dptsa on fdts.id_ps = dptsa.id_ps
join processado.d_estrutura_florestal_alfa defg on defg.id_estrutura_florestal = fdts.id_estrutura_florestal and defg.gridcode = 5
group by dptsa.id_ps 
order by dptsa.id_ps
),
corredor as (
select dptsa.id_ps, dptsa.tx_nome,  count(fdts.id_estrutura_florestal)as  qtd_corredor,  sum(fdts.area) as area_corredor 
from processado.f_detalhe_ts_estrutura2 fdts
join processado.d_programa_territorios_sustentaveis_alfa dptsa on fdts.id_ps = dptsa.id_ps
join processado.d_estrutura_florestal_alfa defg on defg.id_estrutura_florestal = fdts.id_estrutura_florestal and defg.gridcode = 6
group by dptsa.id_ps 
order by dptsa.id_ps
)
insert into processado.f_intersecao_ts_areas_prioritarias
select dcfa.*,
	coalesce (n.area_nuclear,0) as area_nuclear,
	coalesce (n.qtd_nuclear,0) as qtd_nuclear,
	coalesce (c.area_corredor,0) as area_corredor,
	coalesce (c.qtd_corredor,0) as qtd_corredor,
	count(tsca.id_conectividade_funcional) AS qtd_areasprioritarias
--into processado.f_intersecao_ts_areas_prioritarias
from processado.d_programa_territorios_sustentaveis_alfa dcfa
join processado.f_detalhe_ts_conectividade_areasprioritarias tsca on	tsca.id_ps = dcfa.id_ps
left join nuclear n on	n.id_ps = dcfa.id_ps
left join corredor c on	c.id_ps = dcfa.id_ps

group by dcfa.id_ps,n.area_nuclear,n.qtd_nuclear,c.area_corredor,c.qtd_corredor;
