---------
-- DDL --
---------

--drop table if exists processado.f_detalhe_fpsd_desmatamento cascade;
--
--CREATE TABLE processado.f_detalhe_fpsd_desmatamento (
--	id_f_detalhe_fpsd_desmatamento int8 NOT NULL,
--	id_florestas_publicas int8 NULL,
--	id_alertas int8 NULL,
--	tx_nome varchar(255) null,
--	tx_uf varchar(255) null,
--	area_calc_florestas_publicas float8 NULL,
--	area_calc_florestas_publicas_ha float8 NULL,
--	area_over_florestas_publicas float8 NULL,
--	area_over_florestas_publicas_ha float8 NULL,
--	dat_alerta timestamp NULL,
--	tx_orgao_alerta text NULL,
--	area_calc_alerta float8 NULL,
--	area_calc_alerta_ha float8 NULL
--);


------------
-- Script --
------------
DROP SEQUENCE IF EXISTS processado.f_detalhe_fpsd_desmatamento_seq;

CREATE SEQUENCE processado.f_detalhe_fpsd_desmatamento_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_fpsd_desmatamento_seq RESTART WITH 1;

ALTER TABLE processado.f_detalhe_fpsd_desmatamento DROP CONSTRAINT IF EXISTS f_detalhe_fpsd_desmatamento_pk;

truncate table processado.f_detalhe_fpsd_desmatamento;

with area_intersecao as (
select 
	dfpa.id_florestas_publicas,
	dag.id_alertas,
	dfpa.area_calc_florestas_publicas,
	dfpa.tx_nome,
	dfpa.tx_uf,
    st_area(st_union(st_intersection(dfpg.geom, dag.geom))) as area_over_florestas_publicas
	from processado.d_florestas_publicas_alfa dfpa
	inner join processado.d_florestas_publicas_geo dfpg on dfpa.id_florestas_publicas = dfpg.id_florestas_publicas
	inner join processado.d_alertas_geo dag on st_intersects(dfpg.geom, dag.geom)
	where dfpa.tx_uf = 'PA' 
	group by dfpa.id_florestas_publicas, dag.id_alertas),
	
alertas_deter as(
select  
	ai.id_florestas_publicas,
	daa.id_alertas,
	ai.tx_nome,
	ai.tx_uf,
	ai.area_calc_florestas_publicas,
	ai.area_calc_florestas_publicas/10000 as area_calc_florestas_publicas_ha,
	ai.area_over_florestas_publicas,
	ai.area_over_florestas_publicas/10000 as area_over_florestas_publicas_ha,
	daa.dat_alerta,
	daa.tx_orgao_alerta,
	daa.area_calc_alerta,
	daa.area_calc_alerta / 10000 as area_calc_alerta_ha
	from area_intersecao ai	
	join processado.d_alertas_alfa daa on ai.id_alertas = daa.id_alertas
	where daa.tx_orgao_alerta = 'DETER'
	and daa.ano_alerta in (DATE_PART('year', now()), (DATE_PART('year', now()) - 1) )),

alertas_prodes as(
select  
	ai.id_florestas_publicas,
	daa.id_alertas,
	ai.tx_nome,
	ai.tx_uf,
	ai.area_calc_florestas_publicas,
	ai.area_calc_florestas_publicas/10000 as area_calc_florestas_publicas_ha,
	ai.area_over_florestas_publicas,
	ai.area_over_florestas_publicas/10000 as area_over_florestas_publicas_ha,
	daa.dat_alerta,
	daa.tx_orgao_alerta,
	daa.area_calc_alerta,
	daa.area_calc_alerta / 10000 as area_calc_alerta_ha
	from area_intersecao ai	
	join processado.d_alertas_alfa daa on ai.id_alertas = daa.id_alertas
	where daa.tx_orgao_alerta = 'PRODES')

insert into processado.f_detalhe_fpsd_desmatamento

select
	nextval('processado.f_detalhe_fpsd_desmatamento_seq') as id_f_detalhe_fpsd_desmatamento,
	query_union.*

from (
	select * from alertas_prodes
	union all
	select * from alertas_deter) as query_union;



ALTER TABLE processado.f_detalhe_fpsd_desmatamento ADD CONSTRAINT f_detalhe_fpsd_desmatamento_pk PRIMARY KEY (id_f_detalhe_fpsd_desmatamento);