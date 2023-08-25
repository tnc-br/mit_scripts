-- f_imovel_pra_deter: tabela que guardas as informações dos CAR com PRA e dos alertas DETER que se sobrepõem

---------
-- DDL --
---------

--DROP TABLE IF EXISTS processado.f_imovel_pra_deter cascade;

--CREATE TABLE processado.f_imovel_pra_deter (
--	id_f_imovel_pra_deter int8 NULL,
--	id_f_detalhe_imovel_alertas int8 null,
--	id_imovel int4 NULL,
--	id_alertas int4 NULL,
--	area_calc_imovel double precision NULL,
--	area_calc_imovel_ha double precision NULL,
--	area_calc_alerta double precision NULL,
--	area_calc_alerta_ha double precision NULL,
--	area_over_alerta double precision NULL,
--	area_over_alerta_ha double precision NULL,
--	perc_over_alerta double precision NULL,
--	data_ultima_analise timestamp NULL
--);

------------
-- Script --
------------

DROP SEQUENCE IF EXISTS processado.f_imovel_pra_deter_seq;

CREATE SEQUENCE processado.f_imovel_pra_deter_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_imovel_pra_deter_seq RESTART WITH 1;
ALTER TABLE processado.f_imovel_pra_deter DROP CONSTRAINT IF EXISTS f_imovel_pra_deter_pk;

TRUNCATE TABLE processado.f_imovel_pra_deter;

INSERT INTO processado.f_imovel_pra_deter
select
	nextval('processado.f_imovel_pra_deter_seq') as id_f_imovel_pra_deter,
	fdia.*
FROM processado.f_detalhe_imovel_alertas fdia 
	join processado.d_alertas_alfa daa on fdia.id_alertas = daa.id_alertas
	join processado.d_pra_alfa dpa on fdia.id_imovel = dpa.id_imovel and dpa.flag_tca = true
WHERE daa.tx_orgao_alerta = 'DETER' 
	and daa.dat_alerta > dpa.data_emissao
	and (daa.ano_alerta = ANY (ARRAY[date_part('year', now()) - 1, date_part('year', now())]));
	
ALTER TABLE processado.f_imovel_pra_deter ADD CONSTRAINT f_imovel_pra_deter_pk PRIMARY KEY (id_f_imovel_pra_deter);

