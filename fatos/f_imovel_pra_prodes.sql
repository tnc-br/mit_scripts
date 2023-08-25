-- f_imovel_pra_prodes: tabela que guardas as informações dos CAR com PRA e dos alertas PRODES que se sobrepõem

---------
-- DDL --
---------

--DROP TABLE IF EXISTS processado.f_imovel_pra_prodes cascade;

--CREATE TABLE processado.f_imovel_pra_prodes (
--	id_f_imovel_pra_prodes int8 NULL,
--	id_f_detalhe_imovel_alertas int8 null,
--	id_imovel int4 NULL,
--   id_alertas int4 NULL,
--	area_calc_imovel float8 NULL,
--	area_calc_imovel_ha float8 NULL,
--	area_calc_alerta float8 NULL,
--	area_calc_alerta_ha float8 NULL,
--	area_over_alerta float8 NULL,
--	area_over_alerta_ha float8 NULL,
--	perc_over_alerta float8 NULL,
--	data_ultima_analise timestamp NULL
--);

------------
-- Script --
------------

DROP SEQUENCE IF EXISTS processado.f_imovel_pra_prodes_seq;

CREATE SEQUENCE processado.f_imovel_pra_prodes_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_imovel_pra_prodes_seq RESTART WITH 1;
ALTER TABLE processado.f_imovel_pra_prodes DROP CONSTRAINT IF EXISTS f_imovel_pra_prodes_pk;

TRUNCATE TABLE processado.f_imovel_pra_prodes;

INSERT INTO processado.f_imovel_pra_prodes
select
	nextval('processado.f_imovel_pra_prodes_seq') as id_f_imovel_pra_prodes,
	fdia.*
FROM processado.f_detalhe_imovel_alertas fdia 
	join processado.d_alertas_alfa daa on fdia.id_alertas = daa.id_alertas
	join processado.d_pra_alfa dpa on fdia.id_imovel = dpa.id_imovel and dpa.flag_tca = true
WHERE daa.tx_orgao_alerta = 'PRODES' 
	and daa.dat_alerta > dpa.data_emissao;
	

ALTER TABLE processado.f_imovel_pra_prodes ADD CONSTRAINT f_imovel_pra_prodes_pk PRIMARY KEY (id_f_imovel_pra_prodes);
