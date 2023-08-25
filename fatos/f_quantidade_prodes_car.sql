-- f_quantidade_prodes_car: tabela que aramazena a quantidade de alertas PRODES
 -- que um determinado CAR sobrepõe

---------
-- DDL --
---------

-- DROP TABLE processado.f_quantidade_prodes_car;
--
--CREATE TABLE processado.f_quantidade_prodes_car (
--	id_f_quantidade_prodes_car int8 NULL,
--	id_imovel int4 NULL,
--	qtd_total int8 NULL,
--	qtd_ultimo_ano int8 NULL,
--	qtd_ultimos_5_anos int8 NULL,
--	qtd_depois_5_anos int8 NULL,
--	flag_ultimo_ano int4 NULL,
--	flag_ultimos_5_anos int4 NULL,
--	flag_depois_5_anos int4 NULL
--);

------------
-- Script --
------------

DROP SEQUENCE IF EXISTS processado.f_quantidade_prodes_car_seq;

CREATE SEQUENCE processado.f_quantidade_prodes_car_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_quantidade_prodes_car_seq RESTART WITH 1;



ALTER TABLE processado.f_quantidade_prodes_car DROP CONSTRAINT IF EXISTS f_quantidade_prodes_car_pk;

truncate table processado.f_quantidade_prodes_car;

with flags_qtd_prodes as(
	select
		fdiale.id_imovel,
		count(*) AS qtd_total,
		sum(
			CASE
				WHEN (date_part('year'::text, now()) - date_part('year'::text, daa.dat_alerta)) <= 1::double precision THEN 1
		        	ELSE 0
			END) AS qtd_ultimo_ano,
		sum(
		    CASE
		        WHEN (date_part('year', now()) - date_part('year', daa.dat_alerta)) <= 5 THEN 1
		        ELSE 0
		    END) AS qtd_ultimos_5_anos,
		sum(
		    CASE
		        WHEN (date_part('year', now()) - date_part('year', daa.dat_alerta)) > 5 THEN 1
		        ELSE 0
		    END) AS qtd_depois_5_anos,
		max(
			CASE
				WHEN (date_part('year'::text, now()) - date_part('year'::text, daa.dat_alerta)) <= 1::double precision THEN 1
		        	ELSE 0
			END) AS flag_ultimo_ano,
		max(
		    CASE
		        WHEN (date_part('year', now()) - date_part('year', daa.dat_alerta)) <= 5 THEN 1
		        ELSE 0
		    END) AS flag_ultimos_5_anos,
		max(
		    CASE
		        WHEN (date_part('year', now()) - date_part('year', daa.dat_alerta)) > 5 THEN 1
		        ELSE 0
		    END) AS flag_depois_5_anos
	from processado.f_detalhe_imovel_alertas fdiale
		join processado.d_alertas_alfa daa ON daa.id_alertas = fdiale.id_alertas
	where daa.tx_orgao_alerta = 'PRODES'
	group by fdiale.id_imovel
)

insert into processado.f_quantidade_prodes_car
select
	nextval('processado.f_quantidade_prodes_car_seq') as id_f_quantidade_prodes_car,
	id_imovel,
	qtd_total,
	qtd_ultimo_ano,
	qtd_ultimos_5_anos,
	qtd_depois_5_anos,
	flag_ultimo_ano,
	flag_ultimos_5_anos,
	flag_depois_5_anos
from flags_qtd_prodes;
    
ALTER TABLE processado.f_quantidade_prodes_car ADD CONSTRAINT f_quantidade_prodes_car_pk PRIMARY KEY (id_f_quantidade_prodes_car);    