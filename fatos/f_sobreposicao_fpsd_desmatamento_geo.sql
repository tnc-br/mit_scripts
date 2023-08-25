---------
-- DDL --
---------

--drop table if exists tm_sobreposicao.f_sobreposicao_fpsd_desmatamento_geo cascade;
--
--CREATE TABLE tm_sobreposicao.f_sobreposicao_fpsd_desmatamento_geo (
--	id_f_sobreposicao_fpsd_desmatamento_geo int8 NOT NULL,
--	id_florestas_publicas int8 NULL,
--	id_alertas int8 NULL,
--	area_over_florestas_publicas float8 NULL,
--	area_calc_florestas_publicas float8 NULL,
--	area_calc_florestas_publicas_ha float8 NULL,
--	area_intersecao float8 NULL,
--	area_intersecao_ha float8 NULL,
--	geom public.geometry NULL,
--	perc_intersecao float8 null
--);


------------
-- Script --
------------

DROP SEQUENCE IF EXISTS tm_sobreposicao.f_sobreposicao_fpsd_desmatamento_geo_seq;

CREATE SEQUENCE tm_sobreposicao.f_sobreposicao_fpsd_desmatamento_geo_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE tm_sobreposicao.f_sobreposicao_fpsd_desmatamento_geo_seq RESTART WITH 1;
ALTER TABLE tm_sobreposicao.f_sobreposicao_fpsd_desmatamento_geo DROP CONSTRAINT IF EXISTS f_sobreposicao_fpsd_desmatamento_geo_pk;

truncate table tm_sobreposicao.f_sobreposicao_fpsd_desmatamento_geo;

WITH analise_espacial_1 AS (
	SELECT
        fdfpa.id_florestas_publicas,
        fdfpa.id_alertas, 
		fdfpa.tx_orgao_alerta,
		fdfpa.area_calc_florestas_publicas,
		fdfpa.area_calc_florestas_publicas/10000 as area_calc_florestas_publicas_ha,
		fdfpa.area_over_florestas_publicas,    		
		count(distinct fdfpa.id_alertas) as qtd_alerta,
		processado.st_union_or_ignore(dag.geom) as geo_area_agregada
	FROM processado.f_detalhe_fpsd_desmatamento fdfpa  		 
   	JOIN processado.d_alertas_geo dag on fdfpa.id_alertas = dag.id_alertas
	GROUP BY
        fdfpa.id_florestas_publicas,
        fdfpa.id_alertas, 
		fdfpa.tx_orgao_alerta,
		fdfpa.area_calc_florestas_publicas,
		fdfpa.area_over_florestas_publicas
),

analise_espacial_2 AS (
	SELECT
      dfpg.id_florestas_publicas,  
      an1.id_alertas,
      an1.area_over_florestas_publicas,
	  an1.area_calc_florestas_publicas,
	  an1.area_calc_florestas_publicas_ha,
      st_area(an1.geo_area_agregada) as area_agregada,
      st_intersection(dfpg.geom,an1.geo_area_agregada) as geom_intersection
    FROM analise_espacial_1 an1
	JOIN processado.d_florestas_publicas_geo dfpg ON dfpg.id_florestas_publicas = an1.id_florestas_publicas
),

analise_espacial_3 AS (
    SELECT
    	an2.id_florestas_publicas,
    	an2.id_alertas,
    	st_area(an2.geom_intersection) as area_intersecao,
    	st_transform(an2.geom_intersection, 4674) as geom
    FROM
    	analise_espacial_2 an2
)
-- drop table tm_sobreposicao.f_sobreposicao_fpsd_desmatamento_geo cascade;
INSERT INTO tm_sobreposicao.f_sobreposicao_fpsd_desmatamento_geo
SELECT
	nextval('tm_sobreposicao.f_sobreposicao_fpsd_desmatamento_geo_seq') as id_f_sobreposicao_fpsd_desmatamento_geo,
   	a2.id_florestas_publicas,
   	a3.id_alertas,
   	a2.area_over_florestas_publicas,
   	a2.area_calc_florestas_publicas,
  	a2.area_calc_florestas_publicas_ha,
  	a3.area_intersecao,
   	a3.area_intersecao/10000 AS area_intersecao_ha,
   	a3.geom,
   	CASE WHEN a2.area_calc_florestas_publicas > 0 THEN
      	a3.area_intersecao / a2.area_calc_florestas_publicas
   	ELSE 0
   	END AS perc_intersecao
--INTO tm_sobreposicao.f_sobreposicao_fpsd_desmatamento_geo
FROM analise_espacial_2 a2
JOIN analise_espacial_3 a3 on a2.id_florestas_publicas = a3.id_florestas_publicas
						   and a2.id_alertas = a3.id_alertas;
						   

ALTER TABLE tm_sobreposicao.f_sobreposicao_fpsd_desmatamento_geo ADD CONSTRAINT f_sobreposicao_fpsd_desmatamento_geo_pk PRIMARY KEY (id_f_sobreposicao_fpsd_desmatamento_geo);
						 