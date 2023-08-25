---------
-- DDL --
---------

-- drop table if exists tm_sobreposicao.f_imovel_pastagem cascade;
--
--  create table tm_sobreposicao.f_imovel_pastagem (
--  	id_imovel int4 not null,
--  	area_calc_ir_ha double precision null,
--  	area_pastagem_ausente_ha double precision null,
--  	area_pastagem_moderada_ha double precision null,
--  	area_pastagem_severa_ha double precision null,
--  	area_pastagem_total_ha double precision null,
--  	data_ultima_analise timestamp null
--  );



------------
-- Script --
------------

truncate table tm_sobreposicao.f_imovel_pastagem;


with query_pastagem as (
	select 	fdip.id_imovel as id_imovel,
    		fdip.area_calc_ir_ha,
			SUM(CASE WHEN raster_val =  3 THEN area_pastagem_ha ELSE 0 END) as area_pastagem_ausente_ha,
			SUM(CASE WHEN raster_val =  2 THEN area_pastagem_ha ELSE 0 END) as area_pastagem_moderada_ha,
			SUM(CASE WHEN raster_val =  1 THEN area_pastagem_ha ELSE 0 END) as area_pastagem_severa_ha,
			now() as data_ultima_analise
		from  processado.f_detalhe_imovel_pastagem fdip
	  group by fdip.id_imovel, fdip.area_calc_ir_ha
)


insert into tm_sobreposicao.f_imovel_pastagem

select 
		id_imovel,
		area_calc_ir_ha, 
		area_pastagem_ausente_ha,
		area_pastagem_moderada_ha,
		area_pastagem_severa_ha,
		area_pastagem_ausente_ha + area_pastagem_moderada_ha + area_pastagem_severa_ha as area_pastagem_total_ha,
		data_ultima_analise
	from query_pastagem
;

