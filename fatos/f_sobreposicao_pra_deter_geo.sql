-- f_sobreposicao_pra_deter_geo: tabela que armazena as informações geográficas de interseção 
 -- entre CAR com PRA e alertas DETER 

---------
-- DDL --
---------

--DROP TABLE IF EXISTS tm_sobreposicao.f_sobreposicao_pra_deter_geo cascade;

--CREATE TABLE tm_sobreposicao.f_sobreposicao_pra_deter_geo (
--	id_f_sobreposicao_pra_deter_geo int8 NULL,
--	id_imovel int4 NULL,
--	cod_imovel varchar(100) NULL,
--	area_calc_ir float8 NULL,
--	area_calc_ir_ha float8 NULL,
--	qtd_alertas int8 NULL,
--	area_intersecao float8 NULL,
--	area_intersecao_ha float8 NULL,
--	geom public.geometry NULL,
--	perc_intersecao float8 NULL
--);

------------
-- Script --
------------

DROP SEQUENCE IF EXISTS tm_sobreposicao.f_sobreposicao_pra_deter_geo_seq;

CREATE SEQUENCE tm_sobreposicao.f_sobreposicao_pra_deter_geo_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE tm_sobreposicao.f_sobreposicao_pra_deter_geo_seq RESTART WITH 1;
ALTER TABLE tm_sobreposicao.f_sobreposicao_pra_deter_geo DROP CONSTRAINT IF EXISTS f_sobreposicao_pra_deter_geo_pk;


TRUNCATE TABLE tm_sobreposicao.f_sobreposicao_pra_deter_geo;

WITH analise_espacial_1 AS (
        SELECT
            fipd.id_imovel AS id_imovel,
            dia.tx_cod_imovel AS cod_imovel,            
            dia.tx_nome_imovel,
            dia.tx_des_condicao,
            dia.tx_status_imovel,
            dia.area_calc_ir,
            dia.area_calc_ir/10000 AS area_calc_ir_ha,             
            count(distinct fipd.id_alertas) AS qtd_alertas,
            processado.st_union_or_ignore(dag.geom) AS geo_area_agregada
        FROM      
            processado.f_imovel_pra_deter fipd
            JOIN processado.d_alertas_geo dag ON fipd.id_alertas = dag.id_alertas
            JOIN processado.d_pra_alfa dpa ON fipd.id_imovel = dpa.id_imovel AND dpa.flag_tca = TRUE
            JOIN processado.d_imoveis_alfa dia ON  fipd.id_imovel = dia.id_imovel AND dia.num_flg_ativo = TRUE          
        GROUP BY
            fipd.id_imovel,
            dia.tx_cod_imovel,
            dia.area_calc_ir,
            dia.tx_nome_imovel,
            dia.tx_des_condicao,
            dia.tx_status_imovel
            ),

analise_espacial_2 AS (
        SELECT
          ig.id_imovel,
          st_area(an1.geo_area_agregada) as area_agregada,
          st_intersection(ig.geom,an1.geo_area_agregada) as geom_intersection           
        FROM
        	analise_espacial_1 an1
        	JOIN processado.d_imoveis_geo ig ON ig.id_imovel = an1.id_imovel
),

analise_espacial_3 AS (
        SELECT
        	an2.id_imovel,
        	st_area(an2.geom_intersection) as area_intersecao,
        	st_transform(an2.geom_intersection,4674) as geom
        FROM
        	analise_espacial_2 an2
)

INSERT INTO tm_sobreposicao.f_sobreposicao_pra_deter_geo
SELECT
	   nextval('tm_sobreposicao.f_sobreposicao_pra_deter_geo_seq') as id_f_sobreposicao_pra_deter_geo,
       a1.id_imovel,
       a1.cod_imovel,
       a1.area_calc_ir,
       a1.area_calc_ir_ha,
       a1.qtd_alertas,
       a3.area_intersecao,
       a3.area_intersecao/10000 AS area_intersecao_ha,
       a3.geom,
       CASE WHEN a1.area_calc_ir > 0 THEN
          a3.area_intersecao / a1.area_calc_ir
       ELSE 0
       END AS perc_intersecao
FROM
    analise_espacial_1 a1
    JOIN analise_espacial_2 a2 ON a1.id_imovel = a2.id_imovel
    JOIN analise_espacial_3 a3 ON a1.id_imovel = a3.id_imovel;
   
    
ALTER TABLE tm_sobreposicao.f_sobreposicao_pra_deter_geo ADD CONSTRAINT f_sobreposicao_pra_deter_geo_pk PRIMARY KEY (id_f_sobreposicao_pra_deter_geo);
