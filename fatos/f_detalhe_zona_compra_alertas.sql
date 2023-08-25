-----------
-- Regra --
-----------
---------
-- DDL --
---------

-- drop table if exists processado.f_detalhe_zona_compra_alertas cascade;
--
-- create table processado.f_detalhe_zona_compra_alertas (
--  	id_f_detalhe_zona_compra_alertas int8 NULL,
--   	id_zc int4 not null,
--   	tx_razao_social varchar(120) null,
--   	area_over_frigorifico double precision null,
--   	id_alertas int4 null,
--   	tx_orgao_resp varchar(120) null,
--   	data_ultima_analise timestamp null
-- );

------------
-- Script --
------------


DROP SEQUENCE IF EXISTS processado.f_detalhe_zona_compra_alertas_seq;

CREATE SEQUENCE processado.f_detalhe_zona_compra_alertas_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_zona_compra_alertas_seq RESTART WITH 1;


ALTER TABLE processado.f_detalhe_zona_compra_alertas DROP CONSTRAINT IF EXISTS f_detalhe_zona_compra_alertas_pk;

truncate table processado.f_detalhe_zona_compra_alertas;

with alertas_deter as (
	select
				zcfa.id_zc,
				zcfa.tx_razao_social,
				NULL::double precision as area_over_frigorifico,
				daa.id_alertas,
				'DETER' as tx_orgao_resp,
				now() as data_ultima_analise
	from
		processado.d_alertas_alfa daa
	inner join processado.d_alertas_geo dag on (daa.id_alertas  = dag.id_alertas),
		processado.d_zona_compra_frigorifico_alfa zcfa
	inner join (select * from processado.d_zona_compra_frigorifico_geo ) zcfg on (zcfa.id_zc = zcfg.id_zc)
	where
		st_intersects(dag.geom,zcfg.geom )	
		and daa.tx_orgao_alerta = 'DETER'
	    and daa.ano_alerta in (DATE_PART('year', now()), (DATE_PART('year', now()) - 1) )
		
	),

alertas_prodes as (
	select
				zcfa.id_zc,
				zcfa.tx_razao_social,
				st_area(st_intersection(dag.geom,zcfg.geom)) as area_over_frigorifico,
				daa.id_alertas,
				'PRODES' as tx_orgao_resp,
				now() as data_ultima_analise
	from
		processado.d_alertas_alfa daa
	inner join processado.d_alertas_geo dag on (daa.id_alertas  = dag.id_alertas),
		processado.d_zona_compra_frigorifico_alfa zcfa
	inner join (select * from processado.d_zona_compra_frigorifico_geo) zcfg on (zcfa.id_zc = zcfg.id_zc)
	where
		st_intersects(dag.geom,zcfg.geom )

		and daa.tx_orgao_alerta = 'PRODES'	
		
	)

insert into processado.f_detalhe_zona_compra_alertas

select 
nextval('processado.f_detalhe_zona_compra_alertas_seq') as id_f_detalhe_zona_compra_alertas,
* 
from (
		select
			* 
		from
			alertas_deter 
		union 
			select * from alertas_deter
		union 
			select * from alertas_prodes
) query_union
;

ALTER TABLE processado.f_detalhe_zona_compra_alertas ADD CONSTRAINT f_detalhe_zona_compra_alertas_pk PRIMARY KEY (id_f_detalhe_zona_compra_alertas);
