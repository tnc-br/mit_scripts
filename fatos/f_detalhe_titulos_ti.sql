-----------
-- Regra --
-----------

-- 1. area_over_ti = st_area(st_union(st_intersection(a.geom, b.geom_valid)))/10000;
-- 2. WHERE fase_ti <> ‘Homologada’;

---------
-- DDL --
---------

--drop table if exists processado.f_detalhe_titulos_ti cascade;
--
--create table processado.f_detalhe_titulos_ti (
--  	id_f_detalhe_titulos_ti int8 NULL,
--	id_titulo int4 not null,
--  	id_terras_indigenas int4 null,
--  	area_calc_terras_indigenas varchar(255) null,
--  	area_calc_terras_indigenas_ha varchar(255) null,
--  	area_calc_alerta varchar(255) null,
--  	area_calc_alerta_ha varchar(255) null,
--  	area_over_imovel_titulado varchar(255) null,
--	area_over_imovel_titulado_ha varchar(255) null,
--  	perc_over_imovel_titulado varchar(255) null,
--  	data_ultima_analise timestamp null
--);

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS processado.f_detalhe_titulos_ti_seq;

CREATE SEQUENCE processado.f_detalhe_titulos_ti_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_titulos_ti_seq RESTART WITH 1;


ALTER TABLE processado.f_detalhe_titulos_ti DROP CONSTRAINT IF EXISTS f_detalhe_titulos_ti_pk;
truncate table processado.f_detalhe_titulos_ti;

insert into processado.f_detalhe_titulos_ti
with analise_espacial as (
	select 	B.id_titulo as id_titulo,
			C.id_terras_indigenas as id_terras_indigenas,
			st_area(A.geom) as area_calc_imovel_titulado,
			st_area(C.geom) as area_calc_terras_indigenas,
			st_area(processado.st_union_or_ignore(st_intersection(A.geom, C.geom))) as area_over_imovel_titulado,
			now() as data_ultima_analise
		from processado.d_imoveis_titulados_geo A
	inner join processado.d_imoveis_titulados_alfa B on (A.id_titulo = B.id_titulo),
			 processado.d_terras_indigenas_pa_geo C
	inner join processado.d_terras_indigenas_pa_alfa D on (C.id_terras_indigenas = D.id_terras_indigenas)
	where st_intersects(A.geom, C.geom) and st_touches(A.geom, C.geom) = false
	  and D.tx_fase <> 'Homologada'
	group by B.id_titulo, C.geom, C.id_terras_indigenas, A.geom, B.tx_parcela_co 
)
select 	nextval('processado.f_detalhe_titulos_ti_seq') as id_f_detalhe_titulos_ti,
		id_titulo,
		id_terras_indigenas, 
		area_calc_imovel_titulado,
		area_calc_imovel_titulado / 10000 as area_calc_imovel_titulado_ha,
		area_calc_terras_indigenas,
		area_calc_terras_indigenas / 10000 as area_calc_terras_indigenas_ha,
		area_over_imovel_titulado,
		area_over_imovel_titulado / 10000 as area_over_imovel_titulado_ha,
		round((area_over_imovel_titulado / area_calc_imovel_titulado)::numeric,4) as perc_over_imovel_titulado,
		data_ultima_analise
	from analise_espacial
;
ALTER TABLE processado.f_detalhe_titulos_ti ADD CONSTRAINT f_detalhe_titulos_ti_pk PRIMARY KEY (id_f_detalhe_titulos_ti);
