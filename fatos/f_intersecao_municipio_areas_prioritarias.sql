truncate table processado.f_intersecao_municipio_areas_prioritarias;

with nuclear as (
select dptsa.id_municipio, dptsa.tx_nome_municipio,  count(fdts.id_estrutura_florestal)as  qtd_nuclear,  sum(fdts.area) as area_nuclear 
from processado.f_detalhe_municipio_estrutura2 fdts
join processado.d_malha_municipal_alfa dptsa on fdts.id_municipio = dptsa.id_municipio
join processado.d_estrutura_florestal_alfa defg on defg.id_estrutura_florestal = fdts.id_estrutura_florestal and defg.gridcode = 5
group by dptsa.id_municipio, dptsa.tx_nome_municipio
order by dptsa.id_municipio, dptsa.tx_nome_municipio
),
corredor as (
select dptsa.id_municipio, dptsa.tx_nome_municipio,  count(fdts.id_estrutura_florestal)as  qtd_corredor,  sum(fdts.area) as area_corredor 
from processado.f_detalhe_municipio_estrutura2 fdts
join processado.d_malha_municipal_alfa dptsa on fdts.id_municipio = dptsa.id_municipio
join processado.d_estrutura_florestal_alfa defg on defg.id_estrutura_florestal = fdts.id_estrutura_florestal and defg.gridcode = 6
group by dptsa.id_municipio, dptsa.tx_nome_municipio
order by dptsa.id_municipio, dptsa.tx_nome_municipio
)
insert into processado.f_intersecao_municipio_areas_prioritarias
select dcfa.id_municipio,dcfa.tx_nome_municipio,
	coalesce (n.area_nuclear,0) as area_nuclear,
	coalesce (n.qtd_nuclear,0) as qtd_nuclear,
	coalesce (c.area_corredor,0) as area_corredor,
	coalesce (c.qtd_corredor,0) as qtd_corredor,
	count(tsca.id_conectividade_funcional) AS qtd_areasprioritarias
--into processado.f_intersecao_municipio_areas_prioritarias
from 
(select * from processado.d_malha_municipal_alfa where tx_sigla_municipio = 'PA') dcfa 
left join processado.f_detalhe_municipio_conectividade_areasprioritarias tsca on	tsca.id_municipio = dcfa.id_municipio
left join nuclear n on	n.id_municipio = dcfa.id_municipio
left join corredor c on	c.id_municipio = dcfa.id_municipio
group by dcfa.id_municipio,dcfa.tx_nome_municipio, n.area_nuclear,n.qtd_nuclear,c.area_corredor,c.qtd_corredor;