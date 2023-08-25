-- Descrição
-- Cria a tabela de interseção entre um quadrante de conectividade e a estrutura florestal interna ao quadrante
-- Devem ser totalizadas as áreas agrupando por tipo de gridcode contar quantas áreas de cada tipo.
truncate TABLE processado.f_intersecao_conectividade_estrutura;

with ramo as (
select fdce.id_conectividade_funcional, count(fdce.id_estrutura_florestal)as  qtd_ramo,  sum(fdce.st_area) as area_ramo from 
processado.f_detalhe_conectividade_estrutura2 fdce
join processado.d_conectividade_funcional_alfa dcfg on fdce.id_conectividade_funcional = dcfg.id_conectividade_funcional 
join processado.d_estrutura_florestal_alfa defg on defg.id_estrutura_florestal = fdce.id_estrutura_florestal and defg.gridcode = 2
group by fdce.id_conectividade_funcional, defg.tx_tipo_fragmento
order by fdce.id_conectividade_funcional),

borda as (
select fdce.id_conectividade_funcional, count(fdce.id_estrutura_florestal)as  qtd_borda,  sum(fdce.st_area) as area_borda from 
processado.f_detalhe_conectividade_estrutura2 fdce
join processado.d_conectividade_funcional_alfa dcfg on fdce.id_conectividade_funcional = dcfg.id_conectividade_funcional 
join processado.d_estrutura_florestal_alfa defg on defg.id_estrutura_florestal = fdce.id_estrutura_florestal and defg.gridcode = 3
group by fdce.id_conectividade_funcional, defg.tx_tipo_fragmento
order by fdce.id_conectividade_funcional
),

ilha as (
select fdce.id_conectividade_funcional, count(fdce.id_estrutura_florestal)as  qtd_ilha,  sum(fdce.st_area) as area_ilha from 
processado.f_detalhe_conectividade_estrutura2 fdce
join processado.d_conectividade_funcional_alfa dcfg on fdce.id_conectividade_funcional = dcfg.id_conectividade_funcional 
join processado.d_estrutura_florestal_alfa defg on defg.id_estrutura_florestal = fdce.id_estrutura_florestal and defg.gridcode = 4
group by fdce.id_conectividade_funcional, defg.tx_tipo_fragmento
order by fdce.id_conectividade_funcional
),

nuclear as (
select fdce.id_conectividade_funcional, count(fdce.id_estrutura_florestal)as  qtd_nuclear,  sum(fdce.st_area) as area_nuclear from 
processado.f_detalhe_conectividade_estrutura2 fdce
join processado.d_conectividade_funcional_alfa dcfg on fdce.id_conectividade_funcional = dcfg.id_conectividade_funcional 
join processado.d_estrutura_florestal_alfa defg on defg.id_estrutura_florestal = fdce.id_estrutura_florestal and defg.gridcode = 5
group by fdce.id_conectividade_funcional, defg.tx_tipo_fragmento
order by fdce.id_conectividade_funcional
),

corredor as (
select fdce.id_conectividade_funcional, count(fdce.id_estrutura_florestal)as  qtd_corredor,  sum(fdce.st_area) as area_corredor from 
processado.f_detalhe_conectividade_estrutura2 fdce
join processado.d_conectividade_funcional_alfa dcfg on fdce.id_conectividade_funcional = dcfg.id_conectividade_funcional 
join processado.d_estrutura_florestal_alfa defg on defg.id_estrutura_florestal = fdce.id_estrutura_florestal and defg.gridcode = 6
group by fdce.id_conectividade_funcional, defg.tx_tipo_fragmento
order by fdce.id_conectividade_funcional
),

alca as (
select fdce.id_conectividade_funcional, count(fdce.id_estrutura_florestal)as  qtd_alca,  sum(fdce.st_area) as area_alca from 
processado.f_detalhe_conectividade_estrutura2 fdce
join processado.d_conectividade_funcional_alfa dcfg on fdce.id_conectividade_funcional = dcfg.id_conectividade_funcional 
join processado.d_estrutura_florestal_alfa defg on defg.id_estrutura_florestal = fdce.id_estrutura_florestal and defg.gridcode = 7
group by fdce.id_conectividade_funcional, defg.tx_tipo_fragmento
order by fdce.id_conectividade_funcional
)

insert into processado.f_intersecao_conectividade_estrutura
select
	dcfa.id_conectividade_funcional,
	coalesce (r.area_ramo,0) as area_ramo,
	coalesce (r.qtd_ramo,0) as qtd_ramo,
	coalesce (b.area_borda,0)  as area_borda,
	coalesce (b.qtd_borda,0) as qtd_borda,
	coalesce (i.area_ilha,0) as area_ilha,
	coalesce (i.qtd_ilha,0) as qtd_ilha,
	coalesce (n.area_nuclear,0) as area_nuclear,
	coalesce (n.qtd_nuclear,0) as qtd_nuclear,
	coalesce (c.area_corredor,0) as area_corredor,
	coalesce (c.qtd_corredor,0) as qtd_corredor,
	coalesce (a.area_alca,0) as area_alca,
	coalesce (a.qtd_alca,0) as qtd_alca
from
	processado.d_conectividade_funcional_alfa dcfa
left join ramo r on	r.id_conectividade_funcional = dcfa.id_conectividade_funcional
left join borda b on b.id_conectividade_funcional = dcfa.id_conectividade_funcional
left join ilha i on i.id_conectividade_funcional = dcfa.id_conectividade_funcional
left join nuclear n on	n.id_conectividade_funcional = dcfa.id_conectividade_funcional
left join corredor c on	c.id_conectividade_funcional = dcfa.id_conectividade_funcional
left join alca a on	a.id_conectividade_funcional = dcfa.id_conectividade_funcional
