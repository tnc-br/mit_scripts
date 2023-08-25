-----------
-- Regra --
-----------

---------
-- DDL --
---------

-- drop table if exists processado.d_programa_territorios_sustentaveis_geo cascade;

--CREATE TABLE processado.d_programa_territorios_sustentaveis_geo (
--	id_ps int4 NOT NULL,
--	geom public.geometry NULL,
--	CONSTRAINT d_programa_territorios_sustentaveis_geo_pkey PRIMARY KEY (id_ps)
--);
--CREATE INDEX d_programa_territorios_sustentaveis_geo_idx ON processado.d_programa_territorios_sustentaveis_geo USING gist (geom);



-- drop table if exists processado.d_programa_territorios_sustentaveis_alfa;

--CREATE TABLE processado.d_programa_territorios_sustentaveis_alfa (
--	id_ps int4 NOT NULL,
--	tx_nome varchar(255) NULL,
--	tx_nome_municipio varchar(255) NULL,
--	CONSTRAINT d_programa_territorios_sustentaveis_alfa_pkey PRIMARY KEY (id_ps),
--	CONSTRAINT fk_d_programa_territorios_sustentaveis_alfa_d_programa_territor FOREIGN KEY (id_ps) REFERENCES processado.d_programa_territorios_sustentaveis_geo(id_ps)
--);

------------
-- Script --
------------

ALTER TABLE processado.d_programa_territorios_sustentaveis_alfa DROP CONSTRAINT IF EXISTS d_programa_territorios_sustentaveis_alfa_pkey;
ALTER TABLE processado.d_programa_territorios_sustentaveis_alfa DROP CONSTRAINT IF EXISTS fk_d_programa_territorios_sustentaveis_alfa_d_programa_territor;
ALTER TABLE processado.d_programa_territorios_sustentaveis_geo DROP CONSTRAINT IF EXISTS d_programa_territorios_sustentaveis_geo_pkey;
DROP INDEX IF EXISTS processado.d_programa_territorios_sustentaveis_geo_idx;

truncate table processado.d_programa_territorios_sustentaveis_geo cascade;

insert into processado.d_programa_territorios_sustentaveis_geo
	select 	gid as id_ps,
			st_makevalid(st_transform(geom,654)) as geom
		from bruto.programa_territorios_sustentaveis
;

truncate table processado.d_programa_territorios_sustentaveis_alfa;

insert into processado.d_programa_territorios_sustentaveis_alfa
	select 	gid as id_ps,
			nome_ts as tx_nome,
			municipio as tx_nome_municipio
		from bruto.programa_territorios_sustentaveis
;

ALTER TABLE processado.d_programa_territorios_sustentaveis_geo ADD CONSTRAINT d_programa_territorios_sustentaveis_geo_pkey PRIMARY KEY (id_ps);
ALTER TABLE processado.d_programa_territorios_sustentaveis_alfa ADD CONSTRAINT d_programa_territorios_sustentaveis_alfa_pkey PRIMARY KEY (id_ps);
ALTER TABLE processado.d_programa_territorios_sustentaveis_alfa ADD CONSTRAINT fk_d_programa_territorios_sustentaveis_alfa_d_programa_territor FOREIGN KEY (id_ps) REFERENCES processado.d_programa_territorios_sustentaveis_geo(id_ps);
CREATE INDEX d_programa_territorios_sustentaveis_geo_idx ON  processado.d_programa_territorios_sustentaveis_geo USING gist (geom);
