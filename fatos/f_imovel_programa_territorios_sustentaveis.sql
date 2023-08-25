-----------
-- Regra --
-----------
---------
-- DDL --
---------

--  drop table if exists processado.f_imovel_programa_territorios_sustentaveis cascade;
--
--  create table processado.f_imovel_programa_territorios_sustentaveis (
--  	id_imovel int4 null,
--		id_ps int4 not null,
--  	tx_nome varchar(255) null,
--		tx_nome_municipio varchar(255) null,
--		area_over_sobreposicao double precision null
--  );

------------
-- Script --
------------


truncate table processado.f_imovel_programa_territorios_sustentaveis;



with analise_espacial as (

select 
	dia.id_imovel,
	ptsa.id_ps,
	ptsa.tx_nome,
	ptsa.tx_nome_municipio,
	st_area(processado.st_union_or_ignore(st_intersection(dig.geom, ptsg.geom))) as area_over_sobreposicao
	from 
	processado.d_imoveis_alfa dia
	inner join processado.d_imoveis_geo dig on (dia.id_imovel = dig.id_imovel),
	processado.d_programa_territorios_sustentaveis_alfa ptsa
	inner join processado.d_programa_territorios_sustentaveis_geo ptsg on (ptsa.id_ps = ptsg.id_ps)
	where
		st_intersects(dig.geom, ptsg.geom) and st_touches (dig.geom, ptsg.geom) = false
		and dia.num_flg_ativo = true
group by dia.id_imovel, ptsa.id_ps, ptsa.tx_nome, ptsa.tx_nome_municipio, dig.geom, ptsg.geom 
)

insert into processado.f_imovel_programa_territorios_sustentaveis
select
	q1.id_imovel,
	id_ps,
	tx_nome,
	tx_nome_municipio, 
	area_over_sobreposicao
from
	analise_espacial as q1
inner join (
	select 
	id_imovel, 
	MAX(area_over_sobreposicao) as max_area_over_sobreposicao
	from analise_espacial
	group by id_imovel
) q2
on q1.id_imovel = q2.id_imovel and q1.area_over_sobreposicao = q2.max_area_over_sobreposicao

;
