---------
-- DDL --
---------

-- drop table if exists processado.f_detalhe_imovel_pastagem cascade;
--
--  create table processado.f_detalhe_imovel_pastagem (
--  	id_f_detalhe_imovel_pastagem int8 NULL,
--  	id_imovel int4 not null,
--  	raster_val int4 null,
--  	area_pastagem double precision null,
--  	area_pastagem_ha double precision null,
--  	area_calc_ir double precision null,
--  	area_calc_ir_ha double precision null,
--  	data_ultima_analise timestamp null
--  );




------------
-- Script --
------------
DROP SEQUENCE IF EXISTS processado.f_detalhe_imovel_pastagem_seq;

CREATE SEQUENCE processado.f_detalhe_imovel_pastagem_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_imovel_pastagem_seq RESTART WITH 1;

ALTER TABLE processado.f_detalhe_imovel_pastagem DROP CONSTRAINT IF EXISTS f_detalhe_imovel_pastagem_pk;

truncate table processado.f_detalhe_imovel_pastagem;


with analise_espacial as (
	select 	pi.id_imovel as id_imovel,
			pi.raster_val,
    		sum(pi.area_pastagem) as area_pastagem,
			pi.area_calc_ as area_calc_ir,
			now() as data_ultima_analise
		from  processado.pastagem_imovel pi
	inner join processado.d_imoveis_alfa dia on (dia.id_imovel = pi.id_imovel)
	inner join processado.d_imoveis_geo dig  on (dia.id_imovel = dig.id_imovel)
	
	where dia.num_flg_ativo = true
	  and dia.tx_status_imovel not in ( 'CA', 'SU', 'RE' )
	  and raster_val <> 0
	group by pi.id_imovel, pi.raster_val, pi.area_calc_

)

insert into processado.f_detalhe_imovel_pastagem

select 
		nextval('processado.f_detalhe_imovel_pastagem_seq') as id_f_detalhe_imovel_pastagem,
		id_imovel,
		raster_val, 
		area_pastagem,
		area_pastagem / 10000 as area_pastagem_ha,
		area_calc_ir,
		area_calc_ir / 10000 as area_calc_ir_ha,
		data_ultima_analise
	from analise_espacial
;

ALTER TABLE processado.f_detalhe_imovel_pastagem ADD CONSTRAINT f_detalhe_imovel_pastagem_pk PRIMARY KEY (id_f_detalhe_imovel_pastagem);
