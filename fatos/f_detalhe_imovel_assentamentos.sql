-----------
-- Regra --
-----------

-- 1. Gerar tabela de UNION dos assentamentos do ‘INCRA’, ‘ITERPA’ e ‘SEMAS’;
-- 2. Utilizar os imóveis que tenham num_flag_ativo = ‘true’ e tx_status_imovel <> ‘CA’ e tx_tipo_imovel = 'IRU’;
-- 3. area_over_assentamento = st_area(st_union(st_intersection(a.geom, b.geom_valid)))/10000;
-- 4. if area_over_assentamento > 0 then flag_over_assentamento = ‘true’ else ‘false’;


---------
-- DDL --
---------

--DROP TABLE IF EXISTS processado.f_detalhe_imovel_assentamentos CASCADE;
--
--CREATE TABLE processado.f_detalhe_imovel_assentamentos (
--  id_f_detalhe_imovel_assentamentos int8 NULL,
--	id_imovel int8 null,
--	tx_cod_imovel varchar(100) null,
--	area_calc_ir double precision null,
--	area_calc_ir_ha double precision null,
--	area_calc_assentamento double precision null,
--	area_calcassentamento_ha double precision null,
--	area_over_assentamentos double precision null,
--	area_over_assentamentos_ha double precision null,
--	perc_over_assentamentos double precision null,
--	id_assentamentos int8 null,
--	data_ultima_analise timestamp null
--);

------------
-- Script --
------------

--DROP SEQUENCE IF EXISTS processado.f_detalhe_imovel_assentamentos_seq;
--
--CREATE SEQUENCE processado.f_detalhe_imovel_assentamentos_seq
--    INCREMENT BY 1
--    MINVALUE 1
--    MAXVALUE 9223372036854775807
--    START 1
--    CACHE 1
--    NO CYCLE;
--
--ALTER SEQUENCE processado.f_detalhe_imovel_assentamentos_seq RESTART WITH 1;

--ALTER TABLE processado.f_detalhe_imovel_assentamentos DROP CONSTRAINT IF EXISTS f_detalhe_imovel_assentamentos_pk;

truncate table processado.f_detalhe_imovel_assentamentos;

with analise_espacial as (

select
  	dia.id_imovel as id_imovel,
  	dia.tx_cod_imovel as tx_cod_imovel,
  	dia.area_calc_ir as area_calc_ir,
  	st_area(dapg.geom) as area_calc_assentamento,
  	st_area(processado.st_union_or_ignore(st_intersection(dig.geom, dapg.geom)))as area_over_assentamentos,
	dapg.id_assentamentos as id_assentamentos,
	now() as data_ultima_analise
from (select t.id_imovel , geom  from processado.d_imoveis_geo t ) dig
	join processado.d_imoveis_alfa dia on dig.id_imovel = dia.id_imovel,
	(select t.id_assentamentos, geom from processado.d_assentamentos_geo t ) dapg 
where
	dia.tx_tipo_imovel in ('IRU', 'PCT')
	and dia.num_flg_ativo = true
	and st_intersects(dig.geom, dapg.geom)
	and st_touches(dig.geom, dapg.geom) = FALSE
group by dapg.id_assentamentos, dia.id_imovel, dia.tx_cod_imovel, dia.area_calc_ir, dig.geom,dapg.geom)


insert into processado.f_detalhe_imovel_assentamentos

select 
	--nextval('processado.f_detalhe_imovel_assentamentos_seq') as id_f_detalhe_imovel_assentamentos,
	id_imovel,
	tx_cod_imovel,
	area_calc_ir,
	area_calc_ir / 10000 as area_calc_ir_ha,
	area_calc_assentamento,
	round((area_calc_assentamento / 10000)::numeric, 4) as area_calcassentamento_ha,
	area_over_assentamentos,
	round((area_over_assentamentos/ 10000)::numeric, 4) as area_over_assentamentos_ha ,
	round((area_over_assentamentos / area_calc_ir)::numeric,4) as perc_over_assentamentos,
	id_assentamentos,
	data_ultima_analise
--into processado.f_detalhe_imovel_assentamentos
from analise_espacial
;

--ALTER TABLE processado.f_detalhe_imovel_assentamentos ADD CONSTRAINT f_detalhe_imovel_assentamentos_pk PRIMARY KEY (id_f_detalhe_imovel_assentamentos);

--Query OK, 224003 rows affected (execution time: 00:01:57; total time: 00:01:57)