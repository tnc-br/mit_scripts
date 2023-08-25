-----------
-- Regra --
-----------

-- 1. Utilizar os imóveis que tenham num_flag_ativo = ‘true’ e tx_status_imovel <> (‘CA’, 'SU');
-- 2. Utilizar os imóveis do tipo 'IRU’, 'AST' e 'PCT';
-- 3. Utilizar imóveis que tenham ‘flag_tca_ativo’ = ‘true’;
-- 4. area_over_alerta = st_area(st_union(st_intersection(a.geom, b.geom_valid)))/10000;
-- 5. if area_over_alerta > 0 and dat_alerta > dat_cadastro then flag_prodes = ‘true’ else ‘false’;

-- Obs
-- Essa vai ser a flag que tem lá na tabela d_pra, ai precisa pegar os casos que são true (Ponto 3). (Talvez levar para tabela de imoveis alfa)
-- Por enquanto pode desconsiderar todas essas que são flag, não sabemos ainda se vão ser na própria tabela, se vamos criar uma view pra isso (ponto 5).

---------
-- DDL --
---------

-- drop table if exists processado.f_detalhe_imovel_alertas cascade;
--
--  create table processado.f_detalhe_imovel_alertas (
--  	id_f_detalhe_imovel_alertas int8 NULL,
--  	id_imovel int4 not null,
--  	id_alertas int4 null,
--  	area_calc_imovel double precision null,
--  	area_calc_imovel_ha double precision null,
--  	area_calc_alerta double precision null,
--  	area_calc_alerta_ha double precision null,
--  	area_over_alerta double precision null,
--  	area_over_alerta_ha double precision null,
--  	perc_over_alerta double precision null,
--  	data_ultima_analise timestamp null
--  );

------------
-- Script --
------------

DROP SEQUENCE IF EXISTS processado.f_detalhe_imovel_alertas_seq;

CREATE SEQUENCE processado.f_detalhe_imovel_alertas_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_imovel_alertas_seq RESTART WITH 1;



ALTER TABLE processado.f_detalhe_imovel_alertas DROP CONSTRAINT IF EXISTS f_detalhe_imovel_alertas_pk;

truncate table processado.f_detalhe_imovel_alertas;


with analise_espacial as (
	select 	B.id_imovel as id_imovel,
			C.id_alertas as id_alertas,
			st_area(A.geom) as area_calc_imovel,
			st_area(C.geom) as area_calc_alerta,
			st_area(processado.st_union_or_ignore(st_intersection(A.geom, C.geom))) as area_over_alerta,
			now() as data_ultima_analise
		from processado.d_imoveis_geo A
	inner join processado.d_imoveis_alfa B on (A.id_imovel = B.id_imovel),
			processado.d_alertas_geo C
	where B.num_flg_ativo = true
	  and B.tx_status_imovel <> 'CA'
	  and st_intersects(A.geom, C.geom) and st_touches(A.geom, C.geom) = false
	group by B.id_imovel, C.geom, C.id_alertas, A.geom
)

insert into processado.f_detalhe_imovel_alertas

select 	nextval('processado.f_detalhe_imovel_alertas_seq') as id_f_detalhe_imovel_alertas,
		id_imovel,
		id_alertas, 
		area_calc_imovel,
		area_calc_imovel / 10000 as area_calc_imovel_ha,
		area_calc_alerta,
		area_calc_alerta / 10000 as area_calc_alerta_ha,
		area_over_alerta,
		area_over_alerta / 10000 as area_over_alerta_ha,
		round((area_over_alerta / area_calc_imovel)::numeric,4) as perc_over_alertas,
		data_ultima_analise
	from analise_espacial
;

ALTER TABLE processado.f_detalhe_imovel_alertas ADD CONSTRAINT f_detalhe_imovel_alertas_pk PRIMARY KEY (id_f_detalhe_imovel_alertas);
