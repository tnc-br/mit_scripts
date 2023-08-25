-----------
-- Regra --
-----------

-- 1. Utilizar os imóveis que tenham num_flag_ativo = ‘true’ e tx_status_imovel <> (‘CA’, 'SU');
-- 2. Utilizar os imóveis do tipo 'IRU’;
-- 3. Puxar da tabela ‘sv_imovel_pessoa’ os imóveis e seus respectivos proprietários/tipo de pessoa (PF ou PJ);
-- 4. area_over_quilombo = st_area(st_union(st_intersection(a.geom, b.geom_valid)))/10000;
-- 5. if area_over_quilombo > 0 then flag_quilombo = ‘true’ else ‘false’

---------
-- DDL --
---------

-- drop table if exists processado.f_detalhe_imovel_areas_quilombolas_mit cascade;
--
-- create table processado.f_detalhe_imovel_areas_quilombolas_mit (
--  	id_f_detalhe_imovel_areas_quilombolas_mit int8 NULL,
--   	id_imovel int4 not null,
--   	id_areas_quilombolas int4 null,
--   	area_calc_ir double precision null,
--   	area_calc_ir_ha double precision null,
--   	area_calc_quilombo double precision null,
--   	area_calc_quilombo_ha double precision null,
--   	area_over_areas_quilombolas double precision null,
--   	area_over_areas_quilombolas_ha double precision null,
--		areacalcquilombo_ha double precision null,   	
-- 		perc_over_areas_quilombolas double precision null,
--   	data_ultima_analise timestamp null
-- );

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS processado.f_detalhe_imovel_areas_quilombolas_mit_seq;

CREATE SEQUENCE processado.f_detalhe_imovel_areas_quilombolas_mit_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_imovel_areas_quilombolas_mit_seq RESTART WITH 1;

ALTER TABLE processado.f_detalhe_imovel_areas_quilombolas_mit DROP CONSTRAINT IF EXISTS f_detalhe_imovel_areas_quilombolas_mit_pk;

truncate table processado.f_detalhe_imovel_areas_quilombolas_mit;

insert into processado.f_detalhe_imovel_areas_quilombolas_mit
with analise_espacial as (
	select 	B.id_imovel as id_imovel,
			D.id_areas_quilombolas as id_areas_quilombolas,
			st_area(A.geom) as area_calc_ir,
			st_area(D.geom) as area_calc_quilombo,
			st_area(processado.st_union_or_ignore(st_intersection(A.geom, D.geom))) as area_over_areas_quilombolas,
			now() as data_ultima_analise
		from processado.d_imoveis_geo A
	inner join processado.d_imoveis_alfa B on (A.id_imovel = B.id_imovel)
	inner join bruto.sv_imovel_pessoa C on (C.idt_imovel = A.id_imovel),
			 processado.d_areas_quilombolas_geo D
	
	where B.num_flg_ativo = true
	  and B.tx_status_imovel <> 'CA'
	  and B.tx_tipo_imovel in ('IRU', 'AST')
	  and st_intersects(A.geom, D.geom) and st_touches(A.geom, D.geom) = false
	group by B.id_imovel, D.geom, D.id_areas_quilombolas, A.geom
)
select 	nextval('processado.f_detalhe_imovel_areas_quilombolas_mit_seq') as id_f_detalhe_imovel_areas_quilombolas_mit,
		id_imovel,
		id_areas_quilombolas, 
		area_calc_ir,
		area_calc_ir / 10000 as area_calc_ir_ha,
		area_calc_quilombo,
		area_over_areas_quilombolas,
		area_calc_quilombo / 10000 as area_calc_quilombo_ha,
		round((area_over_areas_quilombolas / 10000)::numeric,4) as area_over_areas_quilombolas_ha,
		round((area_calc_quilombo / 10000)::numeric,4)  as areacalcquilombo_ha, 
		round((area_over_areas_quilombolas / area_calc_ir)::numeric,4) as perc_over_areas_quilombolas,
		data_ultima_analise
	from analise_espacial
;

ALTER TABLE processado.f_detalhe_imovel_areas_quilombolas_mit ADD CONSTRAINT f_detalhe_imovel_areas_quilombolas_mit_pk PRIMARY KEY (id_f_detalhe_imovel_areas_quilombolas_mit);
