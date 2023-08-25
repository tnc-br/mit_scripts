-----------
-- Regra --
-----------
-- 1 - Filtrar zonas de compra ativas;
-- 2 - Filtrar zonas de compra com plantas no Pará (uf = 'PA');
-- 3 - Juntar as geometrias dos diferentes nomes de FRIGOL ('M_FRIGOL S. A' e 'FRIGOL S. A' --> 'FRIGOL')
---------
-- DDL --
---------

-- drop table if exists processado.d_zona_compra_frigorifico_geo cascade;
-- create table processado.d_zona_compra_frigorifico_geo (
--	id_zc INTEGER,
-- 	tx_razao_social varchar(120) not null,
-- 	geom public.geometry null
-- );
--
--
--
-- drop table if exists processado.d_zona_compra_frigorifico_alfa;
-- create table processado.d_zona_compra_frigorifico_alfa (
-- 	id_zc INTEGER,
--	tx_razao_social varchar(120) not null,
--	area_calc_zona_compra double precision
-- );


DROP SEQUENCE IF EXISTS processado.id_zc_seq;

CREATE SEQUENCE processado.id_zc_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.id_zc_seq RESTART WITH 1;



------------
-- Script --
------------

ALTER TABLE processado.d_zona_compra_frigorifico_alfa DROP CONSTRAINT IF EXISTS d_zona_compra_frigorifico_alfa_fk;
ALTER TABLE processado.d_zona_compra_frigorifico_alfa DROP CONSTRAINT IF EXISTS d_zona_compra_frigorifico_alfa_pk;
ALTER TABLE processado.d_zona_compra_frigorifico_geo DROP CONSTRAINT IF EXISTS d_zona_compra_frigorifico_geo_pk;
DROP INDEX IF EXISTS processado.d_zona_compra_frigorifico_geo_idx;

truncate table processado.d_zona_compra_frigorifico_alfa;
truncate table processado.d_zona_compra_frigorifico_geo cascade;


insert into processado.d_zona_compra_frigorifico_geo

select
	nextval('processado.id_zc_seq') as id_zc,
	CASE 
        WHEN izcfb.razaosocia = 'M_FRIGOL S. A' or izcfb.razaosocia = 'FRIGOL S. A' THEN 'FRIGOL'
        ELSE izcfb.razaosocia
    	END AS tx_razao_social,
	processado.st_union_or_ignore(st_transform(st_makevalid(izcfb.geom),654)) as geom 
from
	bruto.imazon_zonas_compra_frigorificos_br izcfb
where
	uf = 'PA'
	and status ilike 'ativo%'
	
	group by tx_razao_social
;


insert into processado.d_zona_compra_frigorifico_alfa
	SELECT 
		id_zc,
		tx_razao_social,
		st_area(geom) as area_calc_zona_compra
		from 
			processado.d_zona_compra_frigorifico_geo;



ALTER TABLE processado.d_zona_compra_frigorifico_geo ADD CONSTRAINT d_zona_compra_frigorifico_geo_pk PRIMARY KEY (id_zc);
ALTER TABLE processado.d_zona_compra_frigorifico_alfa ADD CONSTRAINT d_zona_compra_frigorifico_alfa_pk PRIMARY KEY (id_zc);
ALTER TABLE processado.d_zona_compra_frigorifico_alfa ADD CONSTRAINT d_zona_compra_frigorifico_alfa_fk FOREIGN KEY (id_zc) REFERENCES processado.d_zona_compra_frigorifico_geo(id_zc);
CREATE INDEX d_zona_compra_frigorifico_geo_idx ON processado.d_zona_compra_frigorifico_geo USING gist (geom);


