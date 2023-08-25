-----------
-- Regra --
-----------

--1. Utilizar os imóveis que tenham tx_status_imovel <> ‘CA’;​ 
--2. Utilizar os imóveis do tipo 'IRU’;​
--3. Filtrar para alertas do tipo ‘DETER’;​
--4. Selecionar a linha mais antiga do imóvel (select first(data_criacao))​ --trazer primeira data do imóvel, a mais antiga. 
--5. Filtrar para casos em que (dat_criacao > dat_alerta);​ o dif_data é a data de criação mais antiga para aquele imovel - dat_alerta
--6. area_over_alerta = st_area(st_union(st_intersection(a.geom, b.geom_valid)))/10000;​
--7. if area_over_alerta > 0 then flag_ deter = ‘true’ else ‘false’;



---------
-- DDL --
---------

--  drop table if exists processado.f_detalhe_imovel_desmatamento_pre_declaracao cascade;
--
--  create table processado.f_detalhe_imovel_desmatamento_pre_declaracao (
--  		id_f_detalhe_imovel_desmatamento_pre_declaracao int8 NULL,
--  		id_imovel int4 null,
--			tx_cod_imovel varchar(255) not null,
--  		id_alertas int4 null,
--  		tx_classe_alerta varchar(255) null,
--  		--dat_criacao timestamp null,
--			dat_primeiro_registro timestamp null,
--  		dat_alerta timestamp null,
--			dif_data int4 null,
--    		area_over_alerta double precision null,
--			area_over_alerta_ha double precision null,
--			tx_orgao_alerta varchar(255) null,
--			data_ultima_analise timestamp null
--  );

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS processado.f_detalhe_imovel_desmatamento_pre_declaracao_seq;

CREATE SEQUENCE processado.f_detalhe_imovel_desmatamento_pre_declaracao_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_imovel_desmatamento_pre_declaracao_seq RESTART WITH 1;


ALTER TABLE processado.f_detalhe_imovel_desmatamento_pre_declaracao DROP CONSTRAINT IF EXISTS f_detalhe_imovel_desmatamento_pre_declaracao_pk;

truncate table processado.f_detalhe_imovel_desmatamento_pre_declaracao;

with query_registro_mais_antigo as (
	select 
		tx_cod_imovel,
		MIN(dat_criacao) as dat_primeiro_registro
	from 
		processado.d_imoveis_alfa 
	group by 
		tx_cod_imovel 
),


alertas_deter_br as (
	select 	B.id_imovel,
			B.tx_cod_imovel as tx_cod_imovel,
			C.id_alertas as id_alertas,
			C.tx_classe_alerta as tx_classe_alerta,
			--B.dat_criacao as dat_criacao,
			E.dat_primeiro_registro as dat_primeiro_registro,
			C.dat_alerta as dat_alerta,
			E.dat_primeiro_registro - C.dat_alerta as dif_data,
			st_area(st_union(st_intersection(A.geom, D.geom)))/10000 as area_over_alerta,
			C.tx_orgao_alerta as tx_orgao_alerta,
			A.geom as geom_imovel,
			D.geom as geom_alerta,
			now() as data_ultima_analise
		from processado.d_imoveis_geo A
	inner join processado.d_imoveis_alfa B on (A.id_imovel = B.id_imovel)
	left join query_registro_mais_antigo E on (B.tx_cod_imovel = E.tx_cod_imovel),
	processado.d_alertas_alfa C
	inner join processado.d_alertas_geo D on (D.id_alertas = C.id_alertas)
	where B.num_flg_ativo = true
	  and C.tx_orgao_alerta = 'DETER'
	  and C.tx_classe_alerta = 'DESMATAMENTO_CR'
	  and C.ano_alerta in (DATE_PART('year', now()), (DATE_PART('year', now()) - 1) )
	  and st_intersects(A.geom, D.geom) and st_touches(A.geom, D.geom) = false
	group by B.id_imovel, B.tx_cod_imovel, B.dat_criacao, C.tx_classe_alerta, C.id_alertas, D.geom, D.id_alertas, A.geom, E.dat_primeiro_registro
),

alertas_prodes_br as (
	select 	B.id_imovel,
			B.tx_cod_imovel as tx_cod_imovel,
			C.id_alertas as id_alertas,
			C.tx_classe_alerta as tx_classe_alerta,
			--B.dat_criacao as dat_criacao,
			E.dat_primeiro_registro as dat_primeiro_registro,
			C.dat_alerta as dat_alerta,
			E.dat_primeiro_registro - C.dat_alerta as dif_data,
			st_area(st_union(st_intersection(A.geom, D.geom)))/10000 as area_over_alerta,
			C.tx_orgao_alerta as tx_orgao_alerta,
			A.geom as geom_imovel,
			D.geom as geom_alerta,
			now() as data_ultima_analise
		from processado.d_imoveis_geo A
	inner join processado.d_imoveis_alfa B on (A.id_imovel = B.id_imovel)
	left join query_registro_mais_antigo E on (B.tx_cod_imovel = E.tx_cod_imovel),
	processado.d_alertas_alfa C
	inner join processado.d_alertas_geo D on (D.id_alertas = C.id_alertas)
	
	where B.num_flg_ativo = true
	  and C.tx_orgao_alerta = 'PRODES'
	  and st_intersects(A.geom, D.geom) and st_touches(A.geom, D.geom) = false
	group by B.id_imovel, B.tx_cod_imovel, B.dat_criacao, C.tx_classe_alerta, C.id_alertas, D.geom, D.id_alertas, A.geom, E.dat_primeiro_registro
)


insert into processado.f_detalhe_imovel_desmatamento_pre_declaracao 

select 	
		nextval('processado.f_detalhe_imovel_desmatamento_pre_declaracao_seq') as id_f_detalhe_imovel_desmatamento_pre_declaracao,
		id_imovel,
		tx_cod_imovel,
		id_alertas,
		tx_classe_alerta,
		--dat_criacao,
		dat_primeiro_registro,
		dat_alerta,
		EXTRACT(DAY FROM dif_data) as dif_data,
		area_over_alerta,
		area_over_alerta / 10000 as area_over_alerta_ha,
		tx_orgao_alerta,
		data_ultima_analise
from 
	alertas_deter_br
where EXTRACT(DAY FROM dif_data) between 0 and 1825

union

select 	
		nextval('processado.f_detalhe_imovel_desmatamento_pre_declaracao_seq') as id_f_detalhe_imovel_desmatamento_pre_declaracao,
		id_imovel,
		tx_cod_imovel,
		id_alertas,
		tx_classe_alerta,
		--dat_criacao,
		dat_primeiro_registro,
		dat_alerta,
		EXTRACT(DAY FROM dif_data) as dif_data,
		area_over_alerta,
		area_over_alerta / 10000 as area_over_alerta_ha,
		tx_orgao_alerta,
		data_ultima_analise
from 
	alertas_prodes_br
where EXTRACT(DAY FROM dif_data) between 0 and 1825

;

ALTER TABLE processado.f_detalhe_imovel_desmatamento_pre_declaracao ADD CONSTRAINT f_detalhe_imovel_desmatamento_pre_declaracao_pk PRIMARY KEY (id_f_detalhe_imovel_desmatamento_pre_declaracao);
