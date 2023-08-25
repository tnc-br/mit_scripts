-----------
-- Regra --
-----------
---------
-- DDL --
---------

-- drop table if exists processado.f_zona_compra_imoveis cascade;
--
-- create table processado.f_zona_compra_imoveis (
--  	id_f_zona_compra_imoveis int8 NULL,
--   	id_zc int4 not null,
--   	tx_razao_social varchar(120) null,
--   	area_over_frigorifico double precision null,
--   	qtd_imoveis int4 null,
--   	data_ultima_analise timestamp null
-- );

------------
-- Script --
------------


DROP SEQUENCE IF EXISTS processado.f_zona_compra_imoveis_seq;

CREATE SEQUENCE processado.f_zona_compra_imoveis_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_zona_compra_imoveis_seq RESTART WITH 1;

ALTER TABLE processado.f_zona_compra_imoveis DROP CONSTRAINT IF EXISTS f_zona_compra_imoveis_pk;



insert into processado.f_zona_compra_imoveis 
	select
				nextval('processado.f_zona_compra_imoveis_seq') as id_f_zona_compra_imoveis,
				zcfa.id_zc,
				zcfa.tx_razao_social,
				st_area(processado.st_union_or_ignore(st_intersection(dig.geom,zcfg.geom))) as area_over_frigorifico,
				count(dia.id_imovel)::int as qtd_imoveis,
				now() as data_ultima_analise
	from
		processado.d_imoveis_alfa dia
	inner join processado.d_imoveis_geo dig on (dia.id_imovel  = dig.id_imovel) and dia.tx_tipo_imovel = 'IRU' and dia.num_flg_ativo = true,
		processado.d_zona_compra_frigorifico_alfa zcfa
	inner join processado.d_zona_compra_frigorifico_geo zcfg on (zcfa.id_zc = zcfg.id_zc)
	where
		st_intersects(st_simplify(dig.geom, 0.01), st_simplify(zcfg.geom, 0.01))
	group by zcfa.id_zc, zcfa.tx_razao_social	
;

ALTER TABLE processado.f_zona_compra_imoveis ADD CONSTRAINT f_zona_compra_imoveis_pk PRIMARY KEY (id_f_zona_compra_imoveis);

 

