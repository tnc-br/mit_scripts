---------
-- DDL --
---------

--DROP TABLE tm_sobreposicao.f_sobreposicao_quilombolas_car_geo;
--
--CREATE TABLE tm_sobreposicao.f_sobreposicao_quilombolas_car_geo (
--	id_f_sobreposicao_quilombolas_car_geo int8 null,
--	id_areas_quilombolas int4 NULL,
--	area_calc_quilombola float8 NULL,
--	area_calc_quilombola_ha float8 NULL,
--	qtd_imoveis int8 NULL,
--	area_intersecao float8 NULL,
--	area_intersecao_ha float8 NULL,
--	geom public.geometry NULL,
--	perc_intersecao float8 NULL
--);

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS tm_sobreposicao.f_sobreposicao_quilombolas_car_geo_seq;

CREATE SEQUENCE tm_sobreposicao.f_sobreposicao_quilombolas_car_geo_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE tm_sobreposicao.f_sobreposicao_quilombolas_car_geo_seq RESTART WITH 1;
ALTER TABLE tm_sobreposicao.f_sobreposicao_quilombolas_car_geo DROP CONSTRAINT IF EXISTS f_sobreposicao_quilombolas_car_geo_pk;

truncate table tm_sobreposicao.f_sobreposicao_quilombolas_car_geo;


with analise_espacial_1 as (
	select
		fdiaqm.id_areas_quilombolas,
		daqa.area_calc_area_quilombola as area_calc_quilombola,
		(daqa.area_calc_area_quilombola/10000) as area_calc_quilombola_ha,
		count(distinct fdiaqm.id_imovel) as qtd_imoveis,
		processado.st_union_or_ignore(dig.geom) as geo_area_agregada
	from processado.f_detalhe_imovel_areas_quilombolas_mit fdiaqm
		left join processado.d_areas_quilombolas_alfa daqa on daqa.id_areas_quilombolas = fdiaqm.id_areas_quilombolas
		left join processado.d_imoveis_geo dig on dig.id_imovel = fdiaqm.id_imovel
	group by 
		fdiaqm.id_areas_quilombolas,
		daqa.area_calc_area_quilombola
),

analise_espacial_2 as (
	select 
		daqg.id_areas_quilombolas,
		st_intersection(daqg.geom,an1.geo_area_agregada) as geom_intersection           
	from analise_espacial_1 an1 
        join processado.d_areas_quilombolas_geo daqg on daqg.id_areas_quilombolas = an1.id_areas_quilombolas
),

analise_espacial_3 as (
		select 
          an2.id_areas_quilombolas, 
          st_area(an2.geom_intersection) as area_intersecao,
          st_area(an2.geom_intersection)/10000 as area_intersecao_ha,
          st_transform(an2.geom_intersection,4674) as geom
        from analise_espacial_2 an2 
)

insert into tm_sobreposicao.f_sobreposicao_quilombolas_car_geo
select 
	nextval('tm_sobreposicao.f_sobreposicao_quilombolas_car_geo_seq') as id_f_sobreposicao_quilombolas_car_geo, 
  	a1.id_areas_quilombolas,
    a1.area_calc_quilombola,
    a1.area_calc_quilombola_ha,
    a1.qtd_imoveis,
    a3.area_intersecao,
    a3.area_intersecao_ha,
    a3.geom,
    case when area_calc_quilombola > 0 then 
    	a3.area_intersecao / a1.area_calc_quilombola
   	else 0
	end as perc_intersecao
 from
	analise_espacial_1 a1 
    join analise_espacial_2 a2 on a1.id_areas_quilombolas = a2.id_areas_quilombolas
    join analise_espacial_3 a3 on a1.id_areas_quilombolas = a3.id_areas_quilombolas;
   
ALTER TABLE tm_sobreposicao.f_sobreposicao_quilombolas_car_geo ADD CONSTRAINT f_sobreposicao_quilombolas_car_geo_pk PRIMARY KEY (id_f_sobreposicao_quilombolas_car_geo);
