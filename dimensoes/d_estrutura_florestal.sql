-----------
-- Regra --
-----------
-- 1 - Criar a coluna 'tx_tipo_fragmento' a partir da coluna 'grid_code', sendo:
	--a. se grid_code = 2, 'ramo'
	--b. se grid_code = 3 THEN 'borda'
	--c. se grid_code = 4 THEN 'ilha'
	--d. se grid_code = 5 THEN 'área nuclear'
	--e. se grid_code = 6 THEN 'corredor'
	--f. se grid_code = 7 THEN 'alça'

---------
-- DDL --
---------




--DROP TABLE IF EXISTS processado.d_estrutura_florestal_geo cascade;
--
--CREATE TABLE processado.d_estrutura_florestal_geo (
--	id_estrutura_florestal int4 NULL,
--	geom geometry NULL,
--  CONSTRAINT pk_d_estrutura_florestal_geo PRIMARY KEY (id_estrutura_florestal)
--);
--
--DROP TABLE IF EXISTS processado.d_estrutura_florestal_alfa cascade;
--
--CREATE TABLE processado.d_estrutura_florestal_alfa (
--	id_estrutura_florestal int4 NULL,
--	gridcode int4 NULL,
--	tx_tipo_fragmento varchar(254) NULL,
--  CONSTRAINT pk_d_estrutura_florestal_alfa PRIMARY KEY (id_estrutura_florestal),
--  constraint fk_d_estrutura_florestal_d_estrutura_florestal_geo foreign key (id_estrutura_florestal) references processado.d_estrutura_florestal_geo(id_estrutura_florestal)
--);



------------
-- Script --
------------
truncate table processado.d_estrutura_florestal_geo cascade;

insert into processado.d_estrutura_florestal_geo

SELECT 
	tcef.gid as id_estrutura_florestal, 
	st_makevalid(st_transform(tcef.geom,654)) as geom
FROM 
	bruto.tnc_camada_estrutura_florestal tcef
;



truncate table processado.d_estrutura_florestal_alfa;

insert into processado.d_estrutura_florestal_alfa

SELECT 
	tcef.gid as id_estrutura_florestal, 
	tcef.gridcode,
  	CASE tcef.gridcode
		WHEN 2 THEN 'ramo'
		WHEN 3 THEN 'borda'
		WHEN 4 THEN 'ilha'
		WHEN 5 THEN 'área nuclear'
		WHEN 6 THEN 'corredor'
		WHEN 7 THEN 'alça'
		ELSE 'fragmento não identificado'
  END AS tx_tipo_fragmento
FROM 
	bruto.tnc_camada_estrutura_florestal tcef
;

