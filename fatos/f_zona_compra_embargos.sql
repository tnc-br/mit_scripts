-----------
-- Regra --
-----------
---------
-- DDL --
---------

--DROP TABLE IF EXISTS processado.f_zona_compra_embargos;
--
--CREATE TABLE processado.f_zona_compra_embargos (
--  id_f_zona_compra_embargos int8 NULL,
--	id_zc int4 NULL,
--	tx_razao_social varchar(120) NULL,
--	area_over_frigorifico float8 NULL,
--	qtd_embargos int4 NULL,
--	tx_orgao_resp text NULL,
--	data_ultima_analise timestamptz NULL
--);

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS processado.f_zona_compra_embargos_seq;

CREATE SEQUENCE processado.f_zona_compra_embargos_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_zona_compra_embargos_seq RESTART WITH 1;



ALTER TABLE processado.f_zona_compra_embargos DROP CONSTRAINT IF EXISTS f_zona_compra_embargos_pk;
truncate table processado.f_zona_compra_embargos;


with embargos_semas as (
	select
				zcfa.id_zc,
				zcfa.tx_razao_social,
				st_area(processado.st_union_or_ignore(st_intersection(st_makevalid(deg.geom),st_makevalid(zcfg.geom)))) as area_over_frigorifico,
				count(dea.id_embargos)::int as qtd_embargos,
				'SEMAS' as tx_orgao_resp,
				now() as data_ultima_analise
	from
		processado.d_embargos_alfa dea
	inner join processado.d_embargos_geo deg on (dea.id_embargos  = deg.id_embargos),
		processado.d_zona_compra_frigorifico_alfa zcfa
	inner join processado.d_zona_compra_frigorifico_geo zcfg on (zcfa.id_zc = zcfg.id_zc)
	where
		st_intersects(st_makevalid(deg.geom),st_makevalid(zcfg.geom))
		and dea.tx_orgao_resp = 'SEMAS'
	group by zcfa.id_zc, zcfa.tx_razao_social	
		
	),

embargos_ibama as (
	select
				zcfa.id_zc,
				zcfa.tx_razao_social,
				st_area(processado.st_union_or_ignore(st_intersection(st_makevalid(deg.geom),st_makevalid(zcfg.geom)))) as area_over_frigorifico,
				count(dea.id_embargos)::int as qtd_embargos,
				'IBAMA' as tx_orgao_resp,
				now() as data_ultima_analise
	from
		processado.d_embargos_alfa dea
	inner join processado.d_embargos_geo deg on (dea.id_embargos  = deg.id_embargos),
		processado.d_zona_compra_frigorifico_alfa zcfa
	inner join processado.d_zona_compra_frigorifico_geo zcfg on (zcfa.id_zc = zcfg.id_zc)
	where
		st_intersects(st_makevalid(deg.geom),st_makevalid(zcfg.geom))
		and dea.tx_orgao_resp = 'IBAMA'
	group by zcfa.id_zc, zcfa.tx_razao_social	
		
	),
embargos_icmbio as (
	select
				zcfa.id_zc,
				zcfa.tx_razao_social,
				st_area(processado.st_union_or_ignore(st_intersection(st_makevalid(deg.geom),st_makevalid(zcfg.geom)))) as area_over_frigorifico,
				count(dea.id_embargos)::int as qtd_embargos,
				'ICMBIO' as tx_orgao_resp,
				now() as data_ultima_analise
	from
		processado.d_embargos_alfa dea
	inner join processado.d_embargos_geo deg on (dea.id_embargos  = deg.id_embargos),
		processado.d_zona_compra_frigorifico_alfa zcfa
	inner join processado.d_zona_compra_frigorifico_geo zcfg on (zcfa.id_zc = zcfg.id_zc)
	where
		st_intersects(st_makevalid(deg.geom),st_makevalid(zcfg.geom))
		and dea.tx_orgao_resp = 'ICMBIO'
	group by zcfa.id_zc, zcfa.tx_razao_social	
		
	)

insert into processado.f_zona_compra_embargos
select 
nextval('processado.f_zona_compra_embargos_seq') as id_f_zona_compra_embargos,
* from (
		select 
			*
		from
			embargos_semas 
		union 
			select * from embargos_ibama 
		union 
			select * from embargos_icmbio
		) query_union

;

ALTER TABLE processado.f_zona_compra_embargos ADD CONSTRAINT f_zona_compra_embargos_pk PRIMARY KEY (id_f_zona_compra_embargos);
