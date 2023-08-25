-----------
-- Regra --
-----------
---------
-- DDL --
---------

--drop table if exists processado.f_zona_compra_alertas cascade;
--
-- create table processado.f_zona_compra_alertas (
--  	id_f_zona_compra_alertas int8 NULL,
--   	id_zc int4 not null,
--   	tx_razao_social varchar(120) null,
--    tx_orgao_resp varchar(120) null,
--   	area_over_frigorifico double precision null,
--    area_over_frigorifico_ha double precision null,
--    qtd_alertas int4 null,
--   	data_ultima_analise timestamp null
-- );

------------
-- Script --
------------


DROP SEQUENCE IF EXISTS processado.f_zona_compra_alertas_seq;

CREATE SEQUENCE processado.f_zona_compra_alertas_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_zona_compra_alertas_seq RESTART WITH 1;


ALTER TABLE processado.f_zona_compra_alertas DROP CONSTRAINT IF EXISTS f_zona_compra_alertas_pk;

truncate table processado.f_zona_compra_alertas;



insert into processado.f_zona_compra_alertas
select
			nextval('processado.f_zona_compra_alertas_seq') as id_f_zona_compra_alertas,
            fdzca.id_zc,
			fdzca.tx_razao_social,
            fdzca.tx_orgao_resp,
            SUM(fdzca.area_over_frigorifico) as area_over_frigorifico,
            SUM(fdzca.area_over_frigorifico) / 10000 as area_over_frigorifico_ha,
			CASE
                WHEN fdzca.tx_orgao_resp = 'DETER' THEN count(daa.id_alertas)::int 
                ELSE NULL
            END AS  qtd_alertas,
			now() as data_ultima_analise
	from
		processado.f_detalhe_zona_compra_alertas fdzca
        inner join processado.d_alertas_alfa daa on (fdzca.id_alertas  = daa.id_alertas)
	group by fdzca.id_zc, fdzca.tx_razao_social, fdzca.tx_orgao_resp;
		

ALTER TABLE processado.f_zona_compra_alertas ADD CONSTRAINT f_zona_compra_alertas_pk PRIMARY KEY (id_f_zona_compra_alertas);
