truncate table processado.f_intersecao_imoveis_areas_prioritarias;

with nuclear as (
select dptsa.id_imovel, dptsa.tx_cod_imovel,  count(fdts.id_estrutura_florestal)as  qtd_nuclear,  sum(fdts.area) as area_nuclear 
from processado.f_detalhe_imovel_estrutura2 fdts
join processado.d_imoveis_alfa dptsa on fdts.id_imovel = dptsa.id_imovel
join processado.d_estrutura_florestal_alfa defg on defg.id_estrutura_florestal = fdts.id_estrutura_florestal and defg.gridcode = 5
group by dptsa.id_imovel, dptsa.tx_cod_imovel
order by dptsa.id_imovel, dptsa.tx_cod_imovel
),
corredor as (
select dptsa.id_imovel, dptsa.tx_cod_imovel,  count(fdts.id_estrutura_florestal)as  qtd_corredor,  sum(fdts.area) as area_corredor 
from processado.f_detalhe_imovel_estrutura2 fdts
join processado.d_imoveis_alfa dptsa on fdts.id_imovel = dptsa.id_imovel
join processado.d_estrutura_florestal_alfa defg on defg.id_estrutura_florestal = fdts.id_estrutura_florestal and defg.gridcode = 6
group by dptsa.id_imovel, dptsa.tx_cod_imovel
order by dptsa.id_imovel, dptsa.tx_cod_imovel
)
insert into processado.f_intersecao_imoveis_areas_prioritarias
select dcfa.id_imovel,dcfa.tx_cod_imovel,
	coalesce (n.area_nuclear,0) as area_nuclear,
	coalesce (n.qtd_nuclear,0) as qtd_nuclear,
	coalesce (c.area_corredor,0) as area_corredor,
	coalesce (c.qtd_corredor,0) as qtd_corredor,
	count(tsca.id_conectividade_funcional) AS qtd_areasprioritarias
--into processado.f_intersecao_imoveis_areas_prioritarias
from 
(select * from processado.d_imoveis_alfa dcfa
  where dcfa.num_flg_ativo = true and dcfa.tx_status_imovel not in ('CA','RE','SU')) dcfa 
left join processado.f_detalhe_imoveis_conectividade_areasprioritarias tsca on	tsca.id_imovel = dcfa.id_imovel
left join nuclear n on	n.id_imovel = dcfa.id_imovel
left join corredor c on	c.id_imovel = dcfa.id_imovel
group by dcfa.id_imovel,dcfa.tx_cod_imovel, n.area_nuclear,n.qtd_nuclear,c.area_corredor,c.qtd_corredor;