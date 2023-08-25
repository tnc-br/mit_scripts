-----------
-- Regra --
-----------

-- 1. Utilizar os imóveis que tenham num_flag_ativo = ‘true’ e tx_status_imovel <> (‘CA’, 'SU');
-- 2. Utilizar os imóveis do tipo 'IRU’, 'AST', 'PCT';
-- 3. Utilizar somente UC’s do tx_tipo = ‘PI’;
-- 4. area_over_ucpi= st_area(st_union(st_intersection(a.geom, b.geom_valid)))/10000;
-- 5. if area_over_ucpi > 0 then flag_ucpi = ‘true’ else ‘false’

---------
-- DDL --
---------

-- drop table if exists processado.f_detalhe_imovel_ucpi_mit cascade;
--
-- create table processado.f_detalhe_imovel_ucpi_mit (
--  	id_f_detalhe_imovel_ucpi_mit int8 NULL,
--   	id_imovel int4 not null,
--   	id_unidades_conservacao int4 null,
--   	area_calc_ir double precision null,
--   	area_calc_ir_ha double precision null,
--   	area_calc_unidadeconservacao double precision null,
--   	area_calc_unidadeconservacao_ha double precision null,
--   	area_over_uc double precision null,
--   	area_over_uc_ha double precision null,
--   	perc_over_uc double precision null,
--   	data_ultima_analise timestamp null
-- );

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS processado.f_detalhe_imovel_ucpi_mit_seq;

CREATE SEQUENCE processado.f_detalhe_imovel_ucpi_mit_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_imovel_ucpi_mit_seq RESTART WITH 1;


ALTER TABLE processado.f_detalhe_imovel_ucpi_mit DROP CONSTRAINT IF EXISTS f_detalhe_imovel_ucpi_mit_pk;
truncate table processado.f_detalhe_imovel_ucpi_mit;

insert into processado.f_detalhe_imovel_ucpi_mit
with analise_espacial as (
	select 	B.id_imovel as id_imovel,
			C.id_unidades_conservacao as id_unidades_conservacao,
			st_area(A.geom) as area_calc_ir,
			st_area(C.geom) as area_calc_unidadeconservacao,
			st_area(processado.st_union_or_ignore(st_intersection(A.geom, C.geom))) as area_over_uc,
			now() as data_ultima_analise
		from processado.d_imoveis_geo A
	inner join processado.d_imoveis_alfa B on (A.id_imovel = B.id_imovel),
			 processado.d_unidades_conservacao_geo C
	inner join processado.d_unidades_conservacao_alfa D on (C.id_unidades_conservacao = D.id_unidades_conservacao)
	where B.num_flg_ativo = true
	  and B.tx_status_imovel <> 'CA'
	  and st_intersects(A.geom, C.geom) and st_touches(A.geom, C.geom) = false
	  --and D.tx_categoria != 'Refúgio de Vida Silvestre'
	  --and D.tx_categoria != 'Monumento Natural'
	  and D.tx_tipo = 'PI'
	  and C.geom is not null
	group by B.id_imovel, C.geom, C.id_unidades_conservacao, A.geom
)
select 	nextval('processado.f_detalhe_imovel_ucpi_mit_seq') as id_f_detalhe_imovel_ucpi_mit,
		id_imovel,
		id_unidades_conservacao, 
		area_calc_ir,
		area_calc_ir / 10000 as area_calc_ir_ha,
		area_calc_unidadeconservacao,
		area_calc_unidadeconservacao / 10000 as area_calc_unidadeconservacao_ha,
		area_over_uc,
		round((area_over_uc/ 10000)::numeric, 4) as area_over_uc_ha,
		round((area_over_uc / area_calc_ir)::numeric,4) as perc_over_uc,
		data_ultima_analise
	from analise_espacial
;

ALTER TABLE processado.f_detalhe_imovel_ucpi_mit ADD CONSTRAINT f_detalhe_imovel_ucpi_mit_pk PRIMARY KEY (id_f_detalhe_imovel_ucpi_mit);



