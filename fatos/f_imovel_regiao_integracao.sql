-----------
-- Regra --
-----------
---------
-- DDL --
---------

--  drop table if exists processado.f_imovel_regiao_integracao cascade;
--
--  create table processado.f_imovel_regiao_integracao (
--  		id_imovel int4 null,
--		area_calc_ir double precision  null,
--		id_ri int4 not null,
--  		tx_nome varchar(255) null,
--		area_over_regiao_integracao double precision null
--
--  );


------------
-- Script --
------------


truncate table processado.f_imovel_regiao_integracao;


with analise_espacial as (

	select 
		dia.id_imovel,
		st_area(dig.geom) as area_calc_ir,
		ria.id_ri,
		ria.tx_nome,
		st_area(processado.st_union_or_ignore(st_intersection(dig.geom, rig.geom))) as area_over_regiao_integracao
	from 
	processado.d_imoveis_alfa dia
	inner join processado.d_imoveis_geo dig on (dia.id_imovel = dig.id_imovel),
	processado.d_regiao_integracao_alfa ria
	inner join processado.d_regiao_integracao_geo rig on (ria.id_ri = rig.id_ri)
	where
	st_intersects(dig.geom, rig.geom) and st_touches (dig.geom, rig.geom) = false
	and dia.num_flg_ativo = true
	group by dia.id_imovel, ria.id_ri, ria.tx_nome, dig.geom, rig.geom 

)

insert into processado.f_imovel_regiao_integracao
select
	q1.id_imovel,
	area_calc_ir,
	id_ri,
	tx_nome,
	area_over_regiao_integracao
from
	analise_espacial as q1
inner join (
	select 
	id_imovel, 
	MAX(area_over_regiao_integracao) as max_area_over_regiao_integracao
	from analise_espacial
	group by id_imovel
) q2
on q1.id_imovel = q2.id_imovel and q1.area_over_regiao_integracao = q2.max_area_over_regiao_integracao

;