-----------
-- Regra --
-----------
-- 1 - Fazer union do desmatamento PRODES com alertas DETER;
-- 2 - Manter somente as colunas de classe, uf, nome da uc e data do alerta;
-- 3 - Adicionar a coluna do ano do alerta;
-- 4 - Atribuir o órgão 'DETER' p/ alertas do DETER e 'PRODES' p/ alertas do PRODES


---------
-- DDL --
---------

--drop table processado.d_alertas_geo cascade;
--create table processado.d_alertas_geo (
--	id_alertas serial not null,
--	uuid_alertas UUID not null unique,
--	geom public.geometry null
--)
--drop table processado.d_alertas_alfa cascade;
--
--create table processado.d_alertas_alfa (
--	id_alertas serial not null,
--	uuid_alertas uuid not null,
--	id_municipio int4 null,
--	tx_sigla_uf varchar(2) null,
--	tx_classe_alerta varchar(255) null,
--	tx_nome_uc varchar(255) null,
--	dat_alerta timestamp null,
--	ano_alerta int null,
--	tx_orgao_alerta varchar(255) null,
--	area_calc_alerta float8 null
-- );
	
------------
-- Script --
------------

ALTER TABLE processado.d_alertas_alfa DROP CONSTRAINT IF EXISTS d_alertas_alfa_fk;
ALTER TABLE processado.d_alertas_alfa DROP CONSTRAINT IF EXISTS d_alertas_alfa_pk;
ALTER TABLE processado.d_alertas_geo DROP CONSTRAINT IF EXISTS d_alertas_geo_pk;
DROP INDEX IF EXISTS processado.d_alertas_geo_idx;



truncate table processado.d_alertas_alfa;
truncate table processado.d_alertas_geo cascade;

alter sequence processado.d_alertas_geo_id_alertas_seq restart with 1;
alter sequence processado.d_alertas_alfa_id_alertas_seq restart with 1;



insert into processado.d_alertas_geo (uuid_alertas, geom)
select  md5(concat(id_municipio, tx_sigla_uf, tx_classe_alerta, tx_nome_uc, dat_alerta, ano_alerta, tx_orgao_alerta, area_calc_alerta,geom))::uuid as uuid_alertas, 
		st_buffer(st_transform(st_makevalid(geom), 654),0) as geom
	from (
			select 	null as id_municipio,
					A.state as tx_sigla_uf,
					A.main_class as tx_classe_alerta, 
					null as tx_nome_uc, 
					to_date((A.image_date::varchar), 'YYYY-MM-DD') as dat_alerta, 
					EXTRACT('Year' FROM to_date((A.image_date::varchar), 'YYYY-MM-DD')) as ano_alerta,
					'PRODES' as tx_orgao_alerta, 
					st_area(st_makevalid(st_transform(A.geom,654))) as area_calc_alerta,
					A.geom
				from bruto.prodes_desmatamento_anual A
			union 
			select 	B.geocodibge::int as id_municipio,
					B.uf as tx_sigla_uf,
					B.classname as tx_classe_alerta, 
					B.UC as tx_nome_uc, 
					B.VIEW_DATE as dat_alerta, 
					EXTRACT('Year' FROM B.VIEW_DATE) as ano_alerta,
					'DETER' as tx_orgao_alerta, 
					st_area(st_makevalid(st_transform(B.geom,654))) as area_calc_alerta,
					B.geom
				from bruto.alertas_deter_br B) alertas
;


insert into processado.d_alertas_alfa (uuid_alertas, id_municipio, tx_sigla_uf, tx_classe_alerta, tx_nome_uc, dat_alerta, ano_alerta, tx_orgao_alerta, area_calc_alerta)
select  md5(concat(id_municipio, tx_sigla_uf, tx_classe_alerta, tx_nome_uc, dat_alerta, ano_alerta, tx_orgao_alerta, area_calc_alerta,geom))::uuid as uuid_alertas, 
		id_municipio, 
		tx_sigla_uf,
		tx_classe_alerta, 
		tx_nome_uc, 
		dat_alerta, 
		ano_alerta, 
		tx_orgao_alerta, 
		area_calc_alerta 
	from (
			select 	null as id_municipio,
					A.state as tx_sigla_uf,
					A.main_class as tx_classe_alerta, 
					null as tx_nome_uc, 
					to_date((A.image_date::varchar), 'YYYY-MM-DD') as dat_alerta, 
					EXTRACT('Year' FROM to_date((A.image_date::varchar), 'YYYY-MM-DD')) as ano_alerta,
					'PRODES' as tx_orgao_alerta, 
					st_area(st_makevalid(st_transform(A.geom,654))) as area_calc_alerta,
					A.geom 
				from bruto.prodes_desmatamento_anual A
			union 
			select 	B.geocodibge::int as id_municipio,
					B.uf as tx_sigla_uf,
					B.classname as tx_classe_alerta, 
					B.UC as tx_nome_uc, 
					B.VIEW_DATE as dat_alerta, 
					EXTRACT('Year' FROM B.VIEW_DATE) as ano_alerta,
					'DETER' as tx_orgao_alerta, 
					st_area(st_makevalid(st_transform(B.geom,654))) as area_calc_alerta,
					B.geom
				from bruto.alertas_deter_br B) query
;

ALTER TABLE processado.d_alertas_geo ADD CONSTRAINT d_alertas_geo_pk PRIMARY KEY (id_alertas);
ALTER TABLE processado.d_alertas_alfa ADD CONSTRAINT d_alertas_alfa_pk PRIMARY KEY (id_alertas);
ALTER TABLE processado.d_alertas_alfa ADD CONSTRAINT d_alertas_alfa_fk FOREIGN KEY (uuid_alertas) REFERENCES processado.d_alertas_geo(uuid_alertas);

CREATE INDEX d_alertas_geo_idx ON processado.d_alertas_geo USING gist (geom);