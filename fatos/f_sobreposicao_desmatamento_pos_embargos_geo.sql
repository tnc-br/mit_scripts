-- f_sobreposicao_desmatamento_pos_embargos_geo: tabela que armazena informações geográficas
 -- de interseção entre Embargos e alertas de desmatamento.

---------
-- DDL --
---------

--DROP TABLE IF EXISTS tm_sobreposicao.f_sobreposicao_desmatamento_pos_embargos_geo;

--CREATE TABLE tm_sobreposicao.f_sobreposicao_desmatamento_pos_embargos_geo (
--	id_f_sobreposicao_desmatamento_pos_embargos_geo int8 NULL,
--	id_embargos int8 NULL,
--	cod_embargo varchar NULL,
--	area_calc float8 NULL,
--	area_calc_ha float8 NULL,
--	qtd_alertas int8 NULL,
--	area_intersecao float8 NULL,
--	area_intersecao_ha float8 NULL,
--	geom public.geometry NULL,
--	perc_intersecao float8 NULL
--);


------------
-- Script --
------------

DROP SEQUENCE IF EXISTS tm_sobreposicao.f_sobreposicao_desmatamento_pos_embargos_geo_seq;

CREATE SEQUENCE tm_sobreposicao.f_sobreposicao_desmatamento_pos_embargos_geo_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE tm_sobreposicao.f_sobreposicao_desmatamento_pos_embargos_geo_seq RESTART WITH 1;
ALTER TABLE tm_sobreposicao.f_sobreposicao_desmatamento_pos_embargos_geo DROP CONSTRAINT IF EXISTS f_sobreposicao_desmatamento_pos_embargos_geo_pk;

truncate table tm_sobreposicao.f_sobreposicao_desmatamento_pos_embargos_geo;

with analise_espacial_1 as (
	select
		fddpe.id_embargos,
		dea.tx_codigo as cod_embargo,            
 		dea.num_area_calc as area_calc,
 		dea.num_area_calc/10000 as area_calc_ha,     		
		count(distinct fddpe.id_alertas) as qtd_alertas,
		processado.st_union_or_ignore(dag.geom) as geo_area_agregada
	from processado.f_detalhe_desmatamento_pos_embargos fddpe 
    join processado.d_alertas_geo dag on fddpe.id_alertas = dag.id_alertas 
    join processado.d_embargos_alfa dea on fddpe.id_embargos = dea.id_embargos           
	join processado.d_malha_estadual_geo dmeg on st_intersects(dmeg.geom, dag.geom)
    where dmeg.id_uf = 15
    group by
        fddpe.id_embargos,
		dea.tx_codigo,            
 		dea.num_area_calc
),
analise_espacial_2 as (
	select 
    	deg.id_embargos, 
    	st_intersection(ST_MakeValid(deg.geom_buffer), ST_MakeValid(an1.geo_area_agregada)) as geom_intersection           
    from analise_espacial_1 an1 
    	join processado.d_embargos_geo deg on an1.id_embargos = deg.id_embargos 
),
analise_espacial_3 as (
	select 
		an2.id_embargos, 
		st_area(an2.geom_intersection) as area_intersecao,
		st_transform(an2.geom_intersection, 4674) as geom
    from analise_espacial_2 an2
)

INSERT INTO tm_sobreposicao.f_sobreposicao_desmatamento_pos_embargos_geo
select 
	nextval('tm_sobreposicao.f_sobreposicao_desmatamento_pos_embargos_geo_seq') as id_f_sobreposicao_desmatamento_pos_embargos_geo,
	a1.id_embargos,
	a1.cod_embargo,            
 	a1.area_calc,
	a1.area_calc_ha,
	a1.qtd_alertas,
	a3.area_intersecao,
	a3.area_intersecao/10000 as area_intersecao_ha,
	a3.geom,
	case when a1.area_calc > 0 then 
		a3.area_intersecao / a1.area_calc
	else 0
	end as perc_intersecao
from
	analise_espacial_1 a1 
    join analise_espacial_2 a2 on a1.id_embargos = a2.id_embargos
    join analise_espacial_3 a3 on a1.id_embargos = a3.id_embargos;


    
ALTER TABLE tm_sobreposicao.f_sobreposicao_desmatamento_pos_embargos_geo ADD CONSTRAINT f_sobreposicao_desmatamento_pos_embargos_geo_pk PRIMARY KEY (id_f_sobreposicao_desmatamento_pos_embargos_geo);
   
