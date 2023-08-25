-----------
-- Regra --
-----------
-- 1 - Alterar colunas de e área para double precision
-- 2 - Alterar colunas de id para int4

---------
-- DDL --
---------

DROP TABLE IF EXISTS processado.d_conectividade_funcional_geo cascade;

CREATE TABLE processado.d_conectividade_funcional_geo (
	id_conectividade_funcional int4 NULL,
	geom geometry NULL
);

DROP TABLE IF EXISTS processado.d_conectividade_funcional_alfa cascade;

CREATE TABLE processado.d_conectividade_funcional_alfa (
	id_conectividade_funcional int4 NULL,
	num_sum double precision NULL,
	num_mean double precision NULL,
	num_median double precision NULL,
	num_stdev double precision NULL,
	num_min double precision NULL,
	num_max double precision NULL,
	num_range double precision NULL,
	num_minority double precision NULL,
	num_majority double precision NULL,
	num_variety int4 NULL,
	num_variance double precision NULL,
	id_municipio int4 NULL
);



------------
-- Script --
------------


ALTER TABLE processado.d_conectividade_funcional_alfa DROP CONSTRAINT IF EXISTS d_conectividade_funcional_alfa_fk;
ALTER TABLE processado.d_conectividade_funcional_alfa DROP CONSTRAINT IF EXISTS d_conectividade_funcional_alfa_pk;
ALTER TABLE processado.d_conectividade_funcional_geo DROP CONSTRAINT IF EXISTS d_conectividade_funcional_geo_pk;
DROP INDEX IF EXISTS processado.d_conectividade_funcional_geo_idx;




truncate table processado.d_conectividade_funcional_geo cascade;

insert into processado.d_conectividade_funcional_geo

SELECT 

	tccf.gid as id_conectividade_funcional, 
	st_makevalid(st_transform(tccf.geom,654)) as geom
FROM 
	bruto.tnc_camada_conectividade_funcional tccf
	join bruto.malha_municipal bmm on st_intersects(st_transform(bmm.geom,4674),st_transform(tccf.geom,4674)) and bmm.sigla='PA'
;



truncate table processado.d_conectividade_funcional_alfa;

insert into processado.d_conectividade_funcional_alfa


SELECT 
	tccf.gid as id_conectividade_funcional, 
	tccf."_sum" as num_sum, 
	tccf."_mean" as num_mean, 
	tccf."_median" as num_median, 
	tccf."_stdev" as num_stdev, 
	tccf."_min" as num_min, 
	tccf."_max" as num_max, 
	tccf."_range" as num_range, 
	tccf."_minority" as num_minority, 
	tccf."_majority" as num_majority, 
	tccf."_variety" as num_variety, 
	tccf."_variance" as num_variance,
	bmm.cd_mun::int as id_municipio
FROM 
	bruto.tnc_camada_conectividade_funcional tccf
	join bruto.malha_municipal bmm on st_intersects(st_transform(bmm.geom,4674),st_transform(tccf.geom,4674)) and bmm.sigla='PA';

ALTER TABLE processado.d_conectividade_funcional_geo ADD CONSTRAINT d_conectividade_funcional_geo_pk PRIMARY KEY (id_conectividade_funcional);
ALTER TABLE processado.d_conectividade_funcional_alfa ADD CONSTRAINT d_conectividade_funcional_alfa_pk PRIMARY KEY (id_conectividade_funcional);
ALTER TABLE processado.d_conectividade_funcional_alfa ADD CONSTRAINT d_conectividade_funcional_alfa_fk FOREIGN KEY (id_conectividade_funcional) REFERENCES processado.d_conectividade_funcional_geo(id_conectividade_funcional);
CREATE INDEX d_conectividade_funcional_geo_idx ON processado.d_conectividade_funcional_geo USING gist (geom);