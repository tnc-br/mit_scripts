---------
-- DDL --
---------

--DROP TABLE processado.d_area_cadastravel_geo;
--
--CREATE TABLE processado.d_area_cadastravel_geo (
--    id_area_cadastravel int4 NULL,
--	geom public.geometry NULL
--);
--
--
--DROP TABLE processado.d_area_cadastravel_alfa;
--
--CREATE TABLE processado.d_area_cadastravel_alfa (
--	id_area_cadastravel int4 NULL,
--	nm_mun varchar NULL,
--	area_ha float8 NULL,
--	layer varchar(100) NULL
--);


------------
-- Script --
------------


ALTER TABLE processado.d_area_cadastravel_alfa DROP CONSTRAINT IF EXISTS d_area_cadastravel_alfa_fk;
ALTER TABLE processado.d_area_cadastravel_alfa DROP CONSTRAINT IF EXISTS d_area_cadastravel_alfa_pk;
ALTER TABLE processado.d_area_cadastravel_geo DROP CONSTRAINT IF EXISTS d_area_cadastravel_geo_pk;


truncate table processado.d_area_cadastravel_geo cascade;

with query_area_cadastravel_geo as (
    
select
	A.id + 100000 as id_area_cadastravel, 
    st_makevalid(st_transform(A.geom,654)) as geom

from
	bruto.areacadastavel_fuso21 A

union 

select
	B.id + 200000 as id_area_cadastravel,
    st_makevalid(st_transform(B.geom,654)) as geom

from
	bruto.areacadastavel_fuso22 B

union 

select
	C.id + 300000 as id_area_cadastravel, 
    st_makevalid(st_transform(C.geom,654)) as geom

from
	bruto.areacadastavel_fuso23 C


)

insert into processado.d_area_cadastravel_geo 
select *
from query_area_cadastravel_geo

;



truncate table processado.d_area_cadastravel_alfa;

with query_area_cadastravel_alfa as (

SELECT 
    A.id + 100000 as id_area_cadastravel, 
    A.nm_mun, 
    A.area_ha, 
    A.layer
	from
	bruto.areacadastavel_fuso21 A

union

SELECT 
    B.id + 200000 as id_area_cadastravel, 
    B.nm_mun, 
    B.area_ha, 
    B.layer
	from
	bruto.areacadastavel_fuso22 B

union
SELECT 
    C.id + 300000 as id_area_cadastravel, 
    C.nm_mun, 
    C.area_ha, 
    C.layer
	from
	bruto.areacadastavel_fuso23 C
)

insert into processado.d_area_cadastravel_alfa 
select *
from query_area_cadastravel_alfa;


ALTER TABLE processado.d_area_cadastravel_geo ADD CONSTRAINT d_area_cadastravel_geo_pk PRIMARY KEY (id_area_cadastravel);
ALTER TABLE processado.d_area_cadastravel_alfa ADD CONSTRAINT d_area_cadastravel_alfa_pk PRIMARY KEY (id_area_cadastravel);
ALTER TABLE processado.d_area_cadastravel_alfa ADD CONSTRAINT d_area_cadastravel_alfa_fk FOREIGN KEY (id_area_cadastravel) REFERENCES processado.d_area_cadastravel_geo(id_area_cadastravel);