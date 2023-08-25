---------
-- DDL --
---------

--DROP TABLE IF EXISTS tm_sobreposicao.f_sobreposicao_car_ti_geo cascade;

--CREATE TABLE tm_sobreposicao.f_sobreposicao_car_ti_geo (
--	id_f_sobreposicao_car_ti int8 NULL,
--	id_imovel int4 NULL,
--	tx_cod_imovel varchar(100) NULL,
--	area_calc_ir float8 NULL,
--	area_calc_ir_ha float8 NULL,
--	qtd_aq int8 NULL,
--	area_intersecao float8 NULL,
--	area_intersecao_ha float8 NULL,
--	geom public.geometry NULL,
--	perc_intersecao float8 NULL
--);

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS tm_sobreposicao.f_sobreposicao_car_ti_seq;

CREATE SEQUENCE tm_sobreposicao.f_sobreposicao_car_ti_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE tm_sobreposicao.f_sobreposicao_car_ti_seq RESTART WITH 1;
ALTER TABLE tm_sobreposicao.f_sobreposicao_car_ti_geo DROP CONSTRAINT IF EXISTS f_sobreposicao_car_ti_pk;

truncate table tm_sobreposicao.f_sobreposicao_car_ti_geo;

with analise_espacial_1 as (
        select
			fdicc.id_imovel as id_imovel,
            fdicc.tx_cod_imovel as cod_imovel,            
			dia.tx_nome_imovel,
			dia.tx_des_condicao,
			dia.tx_status_imovel,
     		dia.area_calc_ir,
     		dia.area_calc_ir/10000 as area_calc_ir_ha,     		
			count(distinct fdicc.id_terras_indigenas) as qtd_ti,
			processado.st_union_or_ignore(icar.geom) as geo_area_agregada
		from	
            processado.f_detalhe_imovel_ti fdicc
            join processado.d_terras_indigenas_pa_geo icar	on fdicc.id_terras_indigenas = icar.id_terras_indigenas 
            join processado.d_imoveis_alfa dia on  fdicc.id_imovel= dia.id_imovel and dia.num_flg_ativo = true --and dia.id_imovel = 296274    
            join processado.d_malha_estadual_geo dmeg on st_intersects(dmeg.geom, icar.geom) 
        group by
	        fdicc.id_imovel, 
            fdicc.tx_cod_imovel,
     		dia.area_calc_ir,
     		dia.tx_nome_imovel,
			dia.tx_des_condicao,
			dia.tx_status_imovel
            ),
analise_espacial_2 as (
		select 
          ig.id_imovel, 
          st_area(an1.geo_area_agregada) as area_agregada,
          st_intersection(ig.geom,an1.geo_area_agregada) as geom_intersection           
        from analise_espacial_1 an1 
        join processado.d_imoveis_geo ig on ig.id_imovel = an1.id_imovel --and ig.id_imovel = 296274
),
analise_espacial_3 as (
		select 
          an2.id_imovel, 
          st_area(an2.geom_intersection) as area_intersecao,
          st_transform(an2.geom_intersection,4674) as geom
        from analise_espacial_2 an2 
        --where an2.id_imovel = 296274
)

insert into	tm_sobreposicao.f_sobreposicao_car_ti_geo 
select 
	nextval('tm_sobreposicao.f_sobreposicao_car_ti_seq') as id_f_sobreposicao_car_ti, 
  	a1.id_imovel,
	a1.cod_imovel,
    a1.area_calc_ir,
    a1.area_calc_ir_ha,
    a1.qtd_ti,
    a3.area_intersecao,
    a3.area_intersecao/10000 as area_intersecao_ha,
    a3.geom,
    case when a1.area_calc_ir > 0 then 
    	a3.area_intersecao / a1.area_calc_ir
   	else 0
	end as perc_intersecao

 from
	analise_espacial_1 a1 
    join analise_espacial_2 a2 on a1.id_imovel = a2.id_imovel --and a1.id_imovel = 296274 
    join analise_espacial_3 a3 on a1.id_imovel = a3.id_imovel;

   
ALTER TABLE tm_sobreposicao.f_sobreposicao_car_ti_geo ADD CONSTRAINT f_sobreposicao_car_ti_pk PRIMARY KEY (id_f_sobreposicao_car_ti);
