-----------
-- Regra --
-----------
---------
-- DDL --
---------

-- drop table if exists processado.f_zona_compra_imoveis_paralelizacao cascade;
--
-- create table processado.f_zona_compra_imoveis_paralelizacao (
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

truncate table processado.f_zona_compra_imoveis;

do $$

begin

raise notice 'inicio: %', now();

for counter in 0..4  loop       



	insert into processado.f_zona_compra_imoveis 
		select
					nextval('processado.f_zona_compra_imoveis_seq') as id_f_zona_compra_imoveis,
					q1.id_zc,
					q1.tx_razao_social,
					st_area(st_union(st_intersection(dig.geom,q1.geom))) as area_over_frigorifico,
					count(dia.id_imovel)::int as qtd_imoveis,
					now() as data_ultima_analise
		from
			processado.d_imoveis_alfa dia
		inner join processado.d_imoveis_geo dig on (dia.id_imovel  = dig.id_imovel) and dia.tx_tipo_imovel = 'IRU' and dia.num_flg_ativo = true,
			(
				select 
					zcfa.id_zc,
					zcfa.tx_razao_social,
					zcfg.geom
				from 
					processado.d_zona_compra_frigorifico_alfa zcfa
					inner join processado.d_zona_compra_frigorifico_geo zcfg on (zcfa.id_zc = zcfg.id_zc) 
					limit 1 offset counter * 1) q1
		where
			st_intersects(st_simplify(dig.geom, 0.01), st_simplify(q1.geom, 0.01))
		group by q1.id_zc, q1.tx_razao_social	
;

		raise notice 'counter: %', counter;

 

   end loop;

   raise notice 'fim: %', now();

end;

$$;


ALTER TABLE processado.f_zona_compra_imoveis ADD CONSTRAINT f_zona_compra_imoveis_pk PRIMARY KEY (id_f_zona_compra_imoveis);

 

