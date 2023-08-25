-----------
-- Regra --
-----------

-- 1. area_over_ucpi = st_area(st_union(st_intersection(a.geom, b.geom_valid)))/10000;
-- 2. WHERE tx_tipo = "PI";
-- 3.
-- 4.
-- 5.
-- 6.
-- 7.
-- 8.
---------
-- DDL --
---------

--drop table if exists processado.f_detalhe_titulos_ucpi cascade;
--
--create table processado.f_detalhe_titulos_ucpi (
--  	id_f_detalhe_titulos_ucpi int8 NULL,
--  	id_titulo int4 not null,
--  	id_unidades_conservacao int4 null,
--  	area_calc_ucpi double precision null,
--  	area_calc_ucpi_ha double precision null,
--  	area_calc_alerta double precision null,
--  	area_calc_alerta_ha double precision null,
--  	area_over_imovel_titulado double precision null,
--	area_over_imovel_titulado_ha double precision null,
--  	perc_over_imovel_titulado double precision null,
--  	data_ultima_analise timestamp null
--);

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS processado.f_detalhe_titulos_ucpi_seq;

CREATE SEQUENCE processado.f_detalhe_titulos_ucpi_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_titulos_ucpi_seq RESTART WITH 1;


ALTER TABLE processado.f_detalhe_titulos_ucpi DROP CONSTRAINT IF EXISTS f_detalhe_titulos_ucpi_pk;
truncate table processado.f_detalhe_titulos_ucpi;

insert into processado.f_detalhe_titulos_ucpi
with analise_espacial as (
	select 	B.id_titulo as id_titulo,
			C.id_unidades_conservacao as id_unidades_conservacao,
			st_area(A.geom) as area_calc_imovel_titulado,
			st_area(C.geom) as area_calc_ucpi,
			st_area(processado.st_union_or_ignore(st_intersection(A.geom, C.geom))) as area_over_imovel_titulado,
			now() as data_ultima_analise
		from processado.d_imoveis_titulados_geo A
	inner join processado.d_imoveis_titulados_alfa B on (A.id_titulo = B.id_titulo),
			 processado.d_unidades_conservacao_geo  C
	inner join processado.d_unidades_conservacao_alfa  D on (C.id_unidades_conservacao = D.id_unidades_conservacao)
	where st_intersects(A.geom, C.geom) and st_touches(A.geom, C.geom) = false
	  and D.tx_tipo = 'PI'
	group by B.id_titulo, C.geom, C.id_unidades_conservacao, A.geom, B.tx_parcela_co 
)
select 	nextval('processado.f_detalhe_titulos_ucpi_seq') as id_f_detalhe_titulos_ucpi,
		id_titulo,
		id_unidades_conservacao, 
		area_calc_imovel_titulado,
		area_calc_imovel_titulado / 10000 as area_calc_imovel_titulado_ha,
		area_calc_ucpi,
		area_calc_ucpi / 10000 as area_calc_ucpi_ha,
		area_over_imovel_titulado,
		area_over_imovel_titulado / 10000 as area_over_imovel_titulado_ha,
		round((area_over_imovel_titulado / area_calc_imovel_titulado)::numeric,4) as perc_over_imovel_titulado,
		data_ultima_analise
	from analise_espacial
;
ALTER TABLE processado.f_detalhe_titulos_ucpi ADD CONSTRAINT f_detalhe_titulos_ucpi_pk PRIMARY KEY (id_f_detalhe_titulos_ucpi);
