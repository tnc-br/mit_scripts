-----------
-- Regra --
-----------
-- 1 - Alterar gid p/ id_processos_minerarios,
-- 2 - Alterar processo as tx_processo,
-- 3 - Alterar numero as num_numero,
-- 4 - Alterar ano as num_ano,
-- 5 - Alterar area_ha as area_ha,
-- 6 - Alterar id as tx_id,
-- 7 - Alterar fase as tx_fase,
-- 8 - Alterar ult_evento as tx_ult_evento,
-- 9 - Alterar nome as tx_nome,
-- 10 - Alterar subs as tx_subs,
-- 11 - Alterar uso as tx_uso,
-- 12 - Alterar uf as tx_sigla_uf


--DROP TABLE IF EXISTS processado.d_processos_minerarios_geo cascade;
--
--CREATE TABLE processado.d_processos_minerarios_geo (
--	id_processos_minerarios int4 NULL,
--	geom geometry NULL
--);
--
--DROP TABLE IF EXISTS processado.d_processos_minerarios_alfa cascade;
--
--CREATE TABLE processado.d_processos_minerarios_alfa (
--	id_processos_minerarios int4 NULL,
--	tx_processo varchar(254) NULL,
--	num_numero int4 NULL,
--	num_ano int4 NULL,
--	area_ha double precision NULL,
--	tx_id varchar(120) NULL,
--	tx_fase varchar(120) NULL,
--	tx_ult_evento varchar(120) NULL,
--	tx_nome varchar(120) NULL,
--	tx_subs varchar(120) NULL,
--	tx_uso varchar(120) NULL,
--	tx_sigla_uf varchar(120) NULL
--);


------------
-- Script --
------------


ALTER TABLE processado.d_processos_minerarios_alfa DROP CONSTRAINT IF EXISTS d_processos_minerarios_alfa_fk;
ALTER TABLE processado.d_processos_minerarios_alfa DROP CONSTRAINT IF EXISTS d_processos_minerarios_alfa_pk;
ALTER TABLE processado.d_processos_minerarios_geo DROP CONSTRAINT IF EXISTS d_processos_minerarios_geo_pk;
DROP INDEX IF EXISTS processado.d_processos_minerarios_geo_idx;

truncate table processado.d_processos_minerarios_geo cascade;

insert into processado.d_processos_minerarios_geo

select
	pmap.gid as id_processos_minerarios,
	st_makevalid(st_transform(pmap.geom,654)) as geom
from
	bruto.processos_minerarios_anm_pa pmap;
;



truncate table processado.d_processos_minerarios_alfa;

insert into processado.d_processos_minerarios_alfa

select
	pmap.gid as id_processos_minerarios,
	pmap.processo as tx_processo,
	pmap.numero as num_numero,
	pmap.ano as num_ano,
	pmap.area_ha as area_ha,
	pmap.id as tx_id,
	pmap.fase as tx_fase,
	pmap.ult_evento as tx_ult_evento,
	pmap.nome as tx_nome,
	pmap.subs as tx_subs,
	pmap.uso as tx_uso,
	pmap.uf as tx_sigla_uf
from
	bruto.processos_minerarios_anm_pa pmap;


ALTER TABLE processado.d_processos_minerarios_geo ADD CONSTRAINT d_processos_minerarios_geo_pk PRIMARY KEY (id_processos_minerarios);
ALTER TABLE processado.d_processos_minerarios_alfa ADD CONSTRAINT d_processos_minerarios_alfa_pk PRIMARY KEY (id_processos_minerarios);
ALTER TABLE processado.d_processos_minerarios_alfa ADD CONSTRAINT d_processos_minerarios_alfa_fk FOREIGN KEY (id_processos_minerarios) REFERENCES processado.d_processos_minerarios_geo(id_processos_minerarios);
CREATE INDEX d_processos_minerarios_geo_idx ON processado.d_processos_minerarios_geo USING gist (geom);