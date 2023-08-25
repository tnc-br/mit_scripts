-----------------------------------------
-- d_imoveis_alfa_cancelados_suspensos --
-----------------------------------------

-----------
-- Regra --
-----------
-- 1 - Filtrar imóveis c/ num_flg_ativo = true e tx_status_imovel in ('CA','SU');
-- 2 - Retirar imóveis c/ mais de uma linha ativa

---------
-- DDL --
---------

-- DROP TABLE processado.d_imoveis_alfa_cancelados_suspensos;

--CREATE TABLE processado.d_imoveis_alfa_cancelados_suspensos (
--	id_imovel int8 NOT NULL,
--	tx_cod_imovel varchar(100) NULL,
--	tx_cod_protocolo varchar(100) NULL,
--	dat_protocolo timestamp NULL,
--	tx_status_imovel varchar(2) NULL,
--	tx_tipo_imovel varchar(3) NULL,
--	tx_nome_proprietario text NULL,
--	tx_cpf_cnpj_proprietario text NULL,
--	tx_cpf_cadastrante varchar(11) NULL,
--	tx_nome_cadastrante varchar(100) NULL,
--	tx_nome_imovel varchar(100) NULL,
--	num_fracao_ideal int4 NULL,
--	id_municipio int4 NULL,
--	num_area_imovel float8 NULL,
--	num_modulo_fiscal float8 NULL,
--	tx_perfil text NULL,
--	dat_criacao timestamp NULL,
--	num_flg_ativo bool NULL,
--	num_cod_cep varchar(9) NULL,
--	tx_des_condicao text NULL,
--	tx_cpf_edicao varchar(14) NULL,
--	tx_cnpj_cadastrante varchar(14) NULL,
--	tx_nome_insti_cadastrante varchar(100) NULL,
--	area_calc_ir float8 NULL,
--	chave_autuado text NULL,
--	CONSTRAINT d_imoveis_alfa_cancelados_suspensos_pk PRIMARY KEY (id_imovel)
--);



ALTER TABLE processado.d_imoveis_alfa_cancelados_suspensos DROP CONSTRAINT IF EXISTS d_imoveis_alfa_cancelados_suspensos_pk;
ALTER TABLE processado.d_imoveis_geo_cancelados_suspensos DROP CONSTRAINT IF EXISTS d_imoveis_geo_cancelados_suspensos_pk;
DROP INDEX IF EXISTS processado.d_imoveis_geo_cancelados_suspensos_idx;

set client_min_messages = error;

TRUNCATE TABLE
	processado.d_imoveis_alfa_cancelados_suspensos;


with query_imovel_alfa as (
select
	im.idt_imovel as id_imovel,
	im.cod_imovel as tx_cod_imovel,
	im.cod_protocolo as tx_cod_protocolo,
	CASE 
        WHEN date_part('year', im.dat_protocolo) > 2100 
        THEN NULL
        ELSE im.dat_protocolo::timestamp 
        END AS 
        dat_protocolo,
	im.ind_status_imovel as tx_status_imovel,
	im.ind_tipo_imovel as tx_tipo_imovel,
	null as tx_nome_proprietario,
	null as tx_cpf_cnpj_proprietario,
	im.cod_cpf_cadastrante as tx_cpf_cadastrante,
	im.nom_completo_cadastrante as tx_nome_cadastrante,
	im.nom_imovel as tx_nome_imovel,
	im.num_fracao_ideal,
	im.idt_municipio as id_municipio,
	im.num_area_imovel::float,
	im.num_modulo_fiscal::float,
	case
		when im.num_modulo_fiscal <= 4 then 'Pequeno'
		when im.num_modulo_fiscal > 4
		and im.num_modulo_fiscal <= 14 then 'Médio'
		else 'Grande'
	end as tx_perfil,
	im.dat_criacao,
	im.flg_ativo as num_flg_ativo,
	im.cod_cep as num_cod_cep,
	im.des_condicao as tx_des_condicao,
	im.cpf_responsavel as tx_cpf_edicao,
	im.cnpj_instituicao_cadastrante as tx_cnpj_cadastrante,
	im.nom_instituicao_cadastrante as tx_nome_insti_cadastrante,
	ST_Area(ST_Transform(ST_GeomFromWKB(im.geo_area_imovel::geometry),
	654)) as area_calc_ir,
	null as chave_autuado
from
	bruto.sv_imovel im
where
	im.ind_status_imovel in ('SU', 'CA')
	and im.cod_imovel is not null
),

lista_duplicados as (
    select
		tx_cod_imovel
	from
		query_imovel_alfa
	where
		num_flg_ativo = 'true'
	group by
		tx_cod_imovel
	having
		COUNT(*) > 1
),

mais_recentes_duplicados as ( 
select
		last(qia.id_imovel)
from
		lista_duplicados ld
join 

query_imovel_alfa qia 

on
		qia.tx_cod_imovel = ld.tx_cod_imovel
		and qia.num_flg_ativo = true
	group by
		qia.tx_cod_imovel

)

insert into processado.d_imoveis_alfa_cancelados_suspensos  

select
	*
from
	query_imovel_alfa
where
	tx_cod_imovel not in (select * from lista_duplicados)
	or num_flg_ativo <> 'true'
	or id_imovel in (select * from mais_recentes_duplicados);


----------------------------------------
-- d_imoveis_geo_cancelados_suspensos --
----------------------------------------

---------
-- DDL --
---------

-- DROP TABLE processado.d_imoveis_geo_cancelados_suspensos;

--CREATE TABLE processado.d_imoveis_geo_cancelados_suspensos (
--	id_imovel int8 NOT NULL,
--	geom public.geometry NULL,
--	CONSTRAINT d_imoveis_geo_cancelados_suspensos_pk PRIMARY KEY (id_imovel)
--);


TRUNCATE TABLE processado.d_imoveis_geo_cancelados_suspensos ;
-- Camada sv_imovel

with query_imovel_geo as (
select
	im.idt_imovel as id_imovel, 
    im.cod_imovel as tx_cod_imovel,
    st_makevalid(st_transform(im.geo_area_imovel::geometry,654)) as geom,
    im.flg_ativo as num_flg_ativo
from
	bruto.sv_imovel im
where
	im.ind_status_imovel in ('SU', 'CA')
	and im.cod_imovel is not null
),

lista_duplicados as (
    select
		tx_cod_imovel
	from
		query_imovel_geo
	where
		num_flg_ativo = 'true'
	group by
		tx_cod_imovel
	having
		COUNT(*) > 1
),

mais_recentes_duplicados as ( 
select
		last(qig.id_imovel)
from
		lista_duplicados ld
join 

query_imovel_geo qig 

on
		qig.tx_cod_imovel = ld.tx_cod_imovel
		and qig.num_flg_ativo = true
	group by
		qig.tx_cod_imovel

)

insert into
	processado.d_imoveis_geo_cancelados_suspensos

select 
	   qig.id_imovel, 
        qig.geom
--       st_simplifypreservetopology(st_transform(st_geomfromwkb(im.geo_area_imovel::geometry,4674) ,654), 0.001) as geom_simplificada
	  -- st_geomfromwkb(im.geo_area_imovel::geometry,4674) as geom , 
      -- st_simplifypreservetopology(st_geomfromwkb(im.geo_area_imovel::geometry,4674), 0.001) as geom_simplificada

from 
	query_imovel_geo qig
where
	tx_cod_imovel not in (select * from lista_duplicados)
	or num_flg_ativo <> 'true'
	or id_imovel in (select * from mais_recentes_duplicados);


ALTER TABLE processado.d_imoveis_geo_cancelados_suspensos ADD CONSTRAINT d_imoveis_geo_cancelados_suspensos_pk PRIMARY KEY (id_imovel);
ALTER TABLE processado.d_imoveis_alfa_cancelados_suspensos ADD CONSTRAINT d_imoveis_alfa_cancelados_suspensos_pk PRIMARY KEY (id_imovel);

CREATE INDEX d_imoveis_geo_cancelados_suspensos_idx ON processado.d_imoveis_geo_cancelados_suspensos USING gist (geom);

set client_min_messages = notice;
--Query OK, 484972 rows affected 
--(execution time: 22,875 sec; total time: 22,875 sec)

