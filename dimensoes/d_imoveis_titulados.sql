-----------
-- Regra --
-----------

-- FONTE: INCRA, ITERPA
-- 1. Coluna 'art' vira 'tx_art';
-- 2. Coluna 'situacao_i' vira 'tx_situacao_imovel'
-- 3. Coluna 'codigo_imo' vira 'tx_cod_titulo' 
-- 4. Coluna 'data_submi' vira 'dat_submissao'
-- 5. Coluna 'data_aprov' vira 'dat_aprovacao'
-- 6. Coluna 'status' vira 'tx_status_titulo'
-- 7. Coluna 'registro_m' vira 'tx_registro_titulo'
-- 8. Coluna 'nome_area' vira 'tx_nome_titulo'
-- 9. Coluna 'municipio_' vira 'id_municipio'
-- 10. Coluna 'uf_id' vira 'id_uf'

-- ITERPA:(não temos acesso aos dados ainda)
-- 11. Realizar UNION do INCRA com ITERPA

---------
-- DDL --
---------

-- drop table if exists processado.d_imoveis_titulados_geo cascade;
--
-- create table processado.d_imoveis_titulados_geo (
-- 	id_titulo int4 not null,
-- 	geom public.geometry null
-- );
--
--
-- drop table if exists processado.d_imoveis_titulados_alfa;
--
-- create table processado.d_imoveis_titulados_alfa (
-- 	id_titulo int4 not null,
-- 	tx_art varchar(255) null,
-- 	tx_situacao_titulo varchar(255) null,
-- 	tx_cod_titulo varchar(255) null,
-- 	dat_submissao varchar(255) null,
-- 	dat_aprovacao varchar(255) null,
-- 	tx_status_titulo varchar(255) null,
-- 	tx_registro_titulo varchar(255) null,
-- 	tx_nome_titulo varchar(255) null,
-- 	tx_parcela_co varchar(255) null,
-- 	id_municipio int4 null,
-- 	id_uf int4 null,
-- 	flag_match bool null,
-- 	tx_cod_imovel varchar(100) null,
-- 	flag_prada_ativo varchar null
-- );

------------
-- Script --
------------

ALTER TABLE processado.d_imoveis_titulados_alfa DROP CONSTRAINT IF EXISTS d_imoveis_titulados_alfa_fk;
ALTER TABLE processado.d_imoveis_titulados_alfa DROP CONSTRAINT IF EXISTS d_imoveis_titulados_alfa_pk;
ALTER TABLE processado.d_imoveis_titulados_geo DROP CONSTRAINT IF EXISTS d_imoveis_titulados_geo_pk;
DROP INDEX IF EXISTS processado.d_imoveis_titulados_geo_idx;

truncate table processado.d_imoveis_titulados_alfa;
truncate table processado.d_imoveis_titulados_geo cascade;


insert into processado.d_imoveis_titulados_geo
select 	*
	from (
			select 	distinct 
					A.gid as id_titulo,
					st_makevalid(st_transform(A.geom,654)) as geom
				from bruto.titulos_fundiarios_incra_br A
) query
;

insert into processado.d_imoveis_titulados_alfa
select 	* 
	from (
			select 	distinct 
					A.gid as id_titulo,
					A.art as tx_art,
					A.situacao_i as tx_situacao_imovel,
					A.codigo_imo as tx_cod_titulo,
					A.data_submi as dat_submissao,
					A.data_aprov as dat_aprovacao,
					A.status as tx_status_titulo,
					A.registro_m as tx_registro_titulo,
					A.nome_area as tx_nome_titulo,
					A.parcela_co as tx_parcela_co,
					A.municipio_ as id_municipio,
					A.uf_id as id_uf
				from bruto.titulos_fundiarios_incra_br A
) query
;

ALTER TABLE processado.d_imoveis_titulados_geo ADD CONSTRAINT d_imoveis_titulados_geo_pk PRIMARY KEY (id_titulo);
ALTER TABLE processado.d_imoveis_titulados_alfa ADD CONSTRAINT d_imoveis_titulados_alfa_pk PRIMARY KEY (id_titulo);
ALTER TABLE processado.d_imoveis_titulados_alfa ADD CONSTRAINT d_imoveis_titulados_alfa_fk FOREIGN KEY (id_titulo) REFERENCES processado.d_imoveis_titulados_geo(id_titulo);
CREATE INDEX d_imoveis_titulados_geo_idx ON processado.d_imoveis_titulados_geo USING gist (geom);