-- f_quantidade_deter_car: tabela que aramazena a quantidade de alertas DETER 
 -- que um determinado CAR sobrepõe

---------
-- DDL --
---------

--DROP TABLE processado.f_quantidade_deter_car;
--
--CREATE TABLE processado.f_quantidade_deter_car (
--	id_f_quantidade_deter_car int8 NULL,
--	id_imovel int4 NULL,
--	cont_deter int8 NULL
--);

------------
-- Script --
------------

DROP SEQUENCE IF EXISTS processado.f_quantidade_deter_car_seq;

CREATE SEQUENCE processado.f_quantidade_deter_car_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_quantidade_deter_car_seq RESTART WITH 1;


ALTER TABLE processado.f_quantidade_deter_car DROP CONSTRAINT IF EXISTS f_quantidade_deter_car_pk;

truncate table processado.f_quantidade_deter_car;


with quant_deter as (
	select
		fdiale.id_imovel, 
		count(*) AS qtd_total
	from processado.f_detalhe_imovel_alertas fdiale
		join processado.d_alertas_alfa daa on daa.id_alertas = fdiale.id_alertas
	where daa.tx_orgao_alerta = 'DETER'
		and (daa.ano_alerta = ANY (ARRAY[date_part('year', now()),
			date_part('year', now()) - 1]))
	group by fdiale.id_imovel
)	

insert into processado.f_quantidade_deter_car
select	
	nextval('processado.f_quantidade_deter_car_seq') as id_f_quantidade_deter_car,
	id_imovel, 
	qtd_total
from quant_deter;

ALTER TABLE processado.f_quantidade_deter_car ADD CONSTRAINT f_quantidade_deter_car_pk PRIMARY KEY (id_f_quantidade_deter_car);    

