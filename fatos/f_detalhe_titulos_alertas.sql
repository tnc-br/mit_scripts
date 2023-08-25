-----------
-- Regra --
-----------

-- 1. Realizar o cruzamento espacial entre a camada de imóveis titulados e alertas;
-- 2. Filtrar para os casos em que (dat_alerta - dat_aprovacao) < 1825 (dias);
-- 3. Filtrar para os casos em que area_over_titulo > 0

---------
-- DDL --
---------

-- drop table if exists processado.f_detalhe_titulos_alertas cascade;
--
-- create table processado.f_detalhe_titulos_alertas (
--  	id_f_detalhe_titulos_alertas int8 NULL,
--   	id_titulo int4 not null,
--   	id_alertas int4 null,
--   	area_calc_imovel_titulado double precision null,
--   	area_calc_imovel_titulado_ha double precision null,
--   	area_calc_alerta double precision null,
--   	area_calc_alerta_ha double precision null,
--   	area_over_imovel_titulado double precision null,
--   	area_over_imovel_titulado_ha double precision null,
--   	perc_over_imovel_titulado double precision null,
--   	data_ultima_analise timestamp null
-- );

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS processado.f_detalhe_titulos_alertas_seq;

CREATE SEQUENCE processado.f_detalhe_titulos_alertas_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_titulos_alertas_seq RESTART WITH 1;


ALTER TABLE processado.f_detalhe_titulos_alertas DROP CONSTRAINT IF EXISTS f_detalhe_titulos_alertas_pk;
truncate table processado.f_detalhe_titulos_alertas;

insert into processado.f_detalhe_titulos_alertas
with analise_espacial as (
	select 	B.id_titulo as id_titulo,
			C.id_alertas as id_alertas,
			st_area(A.geom) as area_calc_imovel_titulado,
			st_area(C.geom) as area_calc_alerta,
			st_area(processado.st_union_or_ignore(st_intersection(A.geom, C.geom))) as area_over_imovel_titulado,
			now() as data_ultima_analise
		from processado.d_imoveis_titulados_geo  A
	inner join processado.d_imoveis_titulados_alfa B on (A.id_titulo = B.id_titulo),
			 processado.d_alertas_geo C
	inner join processado.d_alertas_alfa D on (C.id_alertas = D.id_alertas)
	where st_intersects(A.geom, C.geom) and st_touches(A.geom, C.geom) = false
	  and (D.dat_alerta::timestamp - B.dat_aprovacao::timestamp) < '1825 days'
	group by B.id_titulo, C.geom, C.id_alertas, A.geom, B.tx_parcela_co 
)
select 	nextval('processado.f_detalhe_titulos_alertas_seq') as id_f_detalhe_titulos_alertas,
		id_titulo,
		id_alertas, 
		area_calc_imovel_titulado,
		area_calc_imovel_titulado / 10000 as area_calc_imovel_titulado_ha,
		area_calc_alerta,
		area_calc_alerta / 10000 as area_calc_alerta_ha,
		area_over_imovel_titulado,
		area_over_imovel_titulado / 10000 as area_over_imovel_titulado_ha,
		round((area_over_imovel_titulado / area_calc_imovel_titulado)::numeric,4) as perc_over_imovel_titulado,
		data_ultima_analise
	from analise_espacial
where area_over_imovel_titulado > 0
;

ALTER TABLE processado.f_detalhe_titulos_alertas ADD CONSTRAINT f_detalhe_titulos_alertas_pk PRIMARY KEY (id_f_detalhe_titulos_alertas);
