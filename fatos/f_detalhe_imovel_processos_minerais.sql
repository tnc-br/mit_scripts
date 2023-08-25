-----------
-- Regra --
-----------

-- 1. ???

---------
-- DDL --
---------

-- drop table if exists processado.f_detalhe_imovel_processos_minerais cascade;
--
-- create table processado.f_detalhe_imovel_processos_minerais (
--    id_f_detalhe_imovel_processos_minerais int8 NULL,
--   	id_imovel int4 not null,
--   	tx_cod_imovel varchar(255) null,
--   	area_calc_ir double precision null,
--   	area_calc_ir_ha double precision null,
--   	area_calc_processos_minerarios double precision null,
--   	area_calc_processos_minerarios_ha double precision null,
--   	area_over_processos_minerarios double precision null,
--   	area_over_processos_minerarios_ha double precision null,
--   	perc_over_processos_minerarios double precision null,
--    id_processos_minerarios int4 null,
--   	data_ultima_analise timestamp null
-- );

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS processado.f_detalhe_imovel_processos_minerais_seq;

CREATE SEQUENCE processado.f_detalhe_imovel_processos_minerais_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_imovel_processos_minerais_seq RESTART WITH 1;


ALTER TABLE processado.f_detalhe_imovel_processos_minerais DROP CONSTRAINT IF EXISTS f_detalhe_imovel_processos_minerais_pk;

truncate table processado.f_detalhe_imovel_processos_minerais;

with analise_espacial as (
select
  dia.id_imovel as id_imovel
, dia.tx_cod_imovel as tx_cod_imovel
, dia.area_calc_ir as area_calc_ir
, st_area(pmg.geom) as area_calc_processos_minerarios
, st_area(processado.st_union_or_ignore(st_intersection(dig.geom, pmg.geom)))as area_over_processos_minerarios
, pmg.id_processos_minerarios as id_processos_minerarios
, now() as data_ultima_analise
from processado.d_imoveis_geo dig
	 join processado.d_imoveis_alfa dia on dig.id_imovel = dia.id_imovel and dia.tx_tipo_imovel = 'IRU' and dia.num_flg_ativo = true,
	 processado.d_processos_minerarios_geo pmg
where
    st_intersects(dig.geom, pmg.geom) and st_touches(dig.geom, pmg.geom) = FALSE

group by
pmg.id_processos_minerarios,
dia.id_imovel, dia.tx_cod_imovel,
dia.area_calc_ir)

insert into processado.f_detalhe_imovel_processos_minerais
select
  nextval('processado.f_detalhe_imovel_processos_minerais_seq') as id_f_detalhe_imovel_processos_minerais,
  id_imovel,
  tx_cod_imovel,
  area_calc_ir,
  area_calc_ir / 10000 as area_calc_ir_ha,
  area_calc_processos_minerarios,
  round((area_calc_processos_minerarios / 10000)::numeric, 4) as area_calc_processos_minerarios_ha,
  area_over_processos_minerarios,
  round((area_over_processos_minerarios / 10000)::numeric, 4) as area_over_processos_minerarios_ha,
  round((area_over_processos_minerarios / area_calc_ir)::numeric,4) as perc_over_processos_minerarios,
  id_processos_minerarios,
  data_ultima_analise



from analise_espacial;

ALTER TABLE processado.f_detalhe_imovel_processos_minerais ADD CONSTRAINT f_detalhe_imovel_processos_minerais_pk PRIMARY KEY (id_f_detalhe_imovel_processos_minerais);
