---------
-- DDL --
---------

--DROP TABLE IF EXISTS tm_sobreposicao.f_sobreposicao_car_recem_declarado_desmatamento_geo cascade;

--CREATE TABLE tm_sobreposicao.f_sobreposicao_car_recem_declarado_desmatamento_geo (
--	id_f_sobreposicao_car_recem_declarado_desmatamento int8 NULL,
--	id_imovel int4 NULL,
--	cod_imovel varchar(255) NULL,
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
truncate table tm_sobreposicao.f_sobreposicao_car_recem_declarado_desmatamento_geo; 
DROP SEQUENCE IF EXISTS tm_sobreposicao.f_sobreposicao_car_recem_declarado_desmatamento_seq;

CREATE SEQUENCE tm_sobreposicao.f_sobreposicao_car_recem_declarado_desmatamento_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE tm_sobreposicao.f_sobreposicao_car_recem_declarado_desmatamento_seq RESTART WITH 1;
ALTER TABLE tm_sobreposicao.f_sobreposicao_car_recem_declarado_desmatamento_geo DROP CONSTRAINT IF EXISTS f_sobreposicao_car_recem_declarado_desmatamento_pk;