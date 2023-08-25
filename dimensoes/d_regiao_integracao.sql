-----------
-- Regra --
-----------

---------
-- DDL --
---------

-- drop table if exists processado.d_regiao_integracao_geo cascade;
--
-- create table processado.d_regiao_integracao_geo (
-- 	id_ri int4 not null,
-- 	geom geometry null
-- );
--
--
-- drop table if exists processado.d_regiao_integracao_alfa;
--
-- create table processado.d_regiao_integracao_alfa (
-- 	id_ri int4 not null,
-- 	tx_nome varchar(255) null
-- );

------------
-- Script --
------------

ALTER TABLE processado.d_regiao_integracao_alfa DROP CONSTRAINT IF EXISTS d_regiao_integracao_alfa_fk;
ALTER TABLE processado.d_regiao_integracao_alfa DROP CONSTRAINT IF EXISTS d_regiao_integracao_alfa_pk;
ALTER TABLE processado.d_regiao_integracao_geo DROP CONSTRAINT IF EXISTS d_regiao_integracao_geo_pk;
DROP INDEX IF EXISTS processado.d_regiao_integracao_geo_idx;

truncate table processado.d_regiao_integracao_geo cascade;
truncate table processado.d_regiao_integracao_alfa;



insert into processado.d_regiao_integracao_geo

			select 
					id as id_ri,
					st_makevalid(st_transform(geom,654)) as geom
				from bruto.regioes_de_integracao
				

;

insert into processado.d_regiao_integracao_alfa
			select 
					id as id_ri,
					regiões_d as tx_nome
				from bruto.regioes_de_integracao

;

ALTER TABLE processado.d_regiao_integracao_geo ADD CONSTRAINT d_regiao_integracao_geo_pk PRIMARY KEY (id_ri);
ALTER TABLE processado.d_regiao_integracao_alfa ADD CONSTRAINT d_regiao_integracao_alfa_pk PRIMARY KEY (id_ri);
ALTER TABLE processado.d_regiao_integracao_alfa ADD CONSTRAINT d_regiao_integracao_alfa_fk FOREIGN KEY (id_ri) REFERENCES processado.d_regiao_integracao_geo(id_ri);

CREATE INDEX d_regiao_integracao_geo_idx ON processado.d_regiao_integracao_geo USING gist (geom);