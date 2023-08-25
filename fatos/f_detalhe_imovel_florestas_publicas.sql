------------
-- Regras --
------------

-- 1. Utilizar os imóveis que tenham num_flag_ativo = ‘true’ e tx_status_imovel <> ‘CA’;
-- 2. Utilizar os imóveis do tipo 'IRU’, 'AST' e 'PCT';
-- 3. Utilizar florestas públicas do ‘tx_protecao’ = ‘SEM DESTINACAO’ 
-- 4. area_over_fpsd = st_area(st_union(st_intersection(a.geom, b.geom_valid)))/10000;
-- 5. if area_over_fpsd > 0 then flag_fpsd = ‘true’ else ‘false’

---------
-- DDL --
---------

-- drop table if exists processado.f_detalhe_imovel_florestas_publicas cascade;
--
-- create table processado.f_detalhe_imovel_florestas_publicas (
--  	id_f_detalhe_imovel_florestas_publicas int8 NULL,
--   	id_imovel int4 not null,
--   	id_floresta_publica int4 null,
--   	area_calc_imovel double precision null,
--   	area_calc_imovel_ha double precision null,
--   	area_calc_floresta_publica double precision null,
--   	area_calc_floresta_publica_ha double precision null,
--   	area_over_floresta_publica double precision null,
--   	area_over_floresta_publica_ha double precision null,
--   	perc_over_floresta_publica double precision null,
--   	data_ultima_analise timestamp null
-- );

------------
-- Script --
------------

--DROP SEQUENCE IF EXISTS processado.f_detalhe_imovel_florestas_publicas_seq;
--
--CREATE SEQUENCE processado.f_detalhe_imovel_florestas_publicas_seq
--    INCREMENT BY 1
--    MINVALUE 1
--    MAXVALUE 9223372036854775807
--    START 1
--    CACHE 1
--    NO CYCLE;
--
--ALTER SEQUENCE processado.f_detalhe_imovel_florestas_publicas_seq RESTART WITH 1;

--ALTER TABLE processado.f_detalhe_imovel_florestas_publicas DROP CONSTRAINT IF EXISTS f_detalhe_imovel_florestas_publicas_pk;

truncate table processado.f_detalhe_imovel_florestas_publicas;

with analise_espacial as (
	select 	B.id_imovel as id_imovel,
			B.tx_cod_imovel,
			C.id_florestas_publicas as id_florestas_publicas,
			st_area(A.geom) as area_calc_ir,
			st_area(C.geom) as area_calc_florestapublica,
			st_area(processado.st_union_or_ignore(st_intersection(A.geom, C.geom))) as area_over_florestas_publicas,
			now() as data_ultima_analise
		from processado.d_imoveis_geo A
	inner join processado.d_imoveis_alfa B on (A.id_imovel = B.id_imovel),
			 processado.d_florestas_publicas_geo C
	inner join processado.d_florestas_publicas_alfa D on (C.id_florestas_publicas = D.id_florestas_publicas)
	where B.num_flg_ativo = true
	  and B.tx_status_imovel <> 'CA'
	  and D.tx_protecao = 'SEM DESTINACAO'
	  and st_intersects(A.geom, C.geom) and st_touches(A.geom, C.geom) = false
	group by B.id_imovel, C.geom, C.id_florestas_publicas, A.geom
)

insert into processado.f_detalhe_imovel_florestas_publicas

select 	--nextval('processado.f_detalhe_imovel_florestas_publicas_seq') as id_f_detalhe_imovel_florestas_publicas,
		id_imovel,
		tx_cod_imovel,
		area_calc_ir,
		area_calc_ir / 10000 as area_calc_ir_ha,
		area_calc_florestapublica,
		area_calc_florestapublica / 10000 as areacalcflorestapublica_ha,
		area_over_florestas_publicas,
		area_over_florestas_publicas / 10000 as area_over_florestas_publicas_ha,
		round((area_over_florestas_publicas / area_calc_ir)::numeric,4) as perc_over_florestas_publicas,
		id_florestas_publicas,
		data_ultima_analise
	from analise_espacial
;

-- select into: cria a tabela que ainda não existe
-- insert into: insere em uma tabela que já existe

--ALTER TABLE processado.f_detalhe_imovel_florestas_publicas ADD CONSTRAINT f_detalhe_imovel_florestas_publicas_pk PRIMARY KEY (id_f_detalhe_imovel_florestas_publicas);
