-- Tabela vazia, não possui sobreposição

-----------
-- Regra --
-----------

-- 1. Utilizar os imóveis que tenham num_flag_ativo = ‘true’ e tx_status_imovel <> (‘CA’, 'SU');
-- 2. Utilizar os imóveis do tipo 'IRU’, 'PCT' e 'AST';
-- 3. area_over_ti = st_area(st_union(st_intersection(a.geom, b.geom_valid)))/10000;
-- 4. if area_over_ti > 0 then flag_ti = ‘true’ else ‘false’

---------
-- DDL --
---------

-- drop table if exists processado.f_detalhe_imovel_ti cascade;
--
-- create table processado.f_detalhe_imovel_ti (
--    id_f_detalhe_imovel_ti int8 NULL,
--   	id_imovel int4 not null,
--   	tx_cod_imovel varchar(255) null,
--   	area_calc_ir double precision null,
--   	area_calc_ir_ha double precision null,
--   	area_calc_ti double precision null,
--   	area_calc_ti_ha double precision null,
--   	area_over_ti double precision null,
--   	area_over_ti_ha double precision null,
--   	perc_over_ti double precision null,
--    id_terras_indigenas int4 null,
--   	data_ultima_analise timestamp null
-- );

------------
-- Script --
------------

--DROP SEQUENCE IF EXISTS processado.f_detalhe_imovel_ti_seq;
--
--CREATE SEQUENCE processado.f_detalhe_imovel_ti_seq
--    INCREMENT BY 1
--    MINVALUE 1
--    MAXVALUE 9223372036854775807
--    START 1
--    CACHE 1
--    NO CYCLE;
--
--ALTER SEQUENCE processado.f_detalhe_imovel_ti_seq RESTART WITH 1;

--ALTER TABLE processado.f_detalhe_imovel_ti DROP CONSTRAINT IF EXISTS f_detalhe_imovel_ti_pk;

truncate table processado.f_detalhe_imovel_ti;

with analise_espacial as (
select
  dia.id_imovel as id_imovel
, dia.tx_cod_imovel as tx_cod_imovel
, dia.area_calc_ir as area_calc_ir
, st_area(dtiupg.geom) as area_calc_ti
, st_area(processado.st_union_or_ignore(st_intersection(dig.geom, dtiupg.geom)))as area_over_ti
, dtiupg.id_terras_indigenas as id_terras_indigenas
, now() as data_ultima_analise
from processado.d_imoveis_geo dig
	 join processado.d_imoveis_alfa dia on dig.id_imovel = dia.id_imovel and dia.tx_tipo_imovel = 'IRU' and dia.num_flg_ativo = true,
	 processado.d_terras_indigenas_pa_geo dtiupg
where
    st_intersects(dig.geom, dtiupg.geom) and st_touches(dig.geom, dtiupg.geom) = FALSE
group by
dtiupg.id_terras_indigenas,
dia.id_imovel, dia.tx_cod_imovel,
dia.area_calc_ir)

insert into processado.f_detalhe_imovel_ti
select
  --nextval('processado.f_detalhe_imovel_ti_seq') as id_f_detalhe_imovel_ti,
  id_imovel,
  tx_cod_imovel,
  area_calc_ir,
  area_calc_ir / 10000 as area_calc_ir_ha,
  area_calc_ti,
  round((area_calc_ti / 10000)::numeric, 4) as area_calc_ti_ha,
  area_over_ti,
  round((area_over_ti / 10000)::numeric, 4) as area_over_ti_ha,
  round((area_over_ti / area_calc_ir)::numeric,4) as perc_over_ti,
  id_terras_indigenas,
  data_ultima_analise
from analise_espacial;

--ALTER TABLE processado.f_detalhe_imovel_ti ADD CONSTRAINT f_detalhe_imovel_ti_pk PRIMARY KEY (id_f_detalhe_imovel_ti);
