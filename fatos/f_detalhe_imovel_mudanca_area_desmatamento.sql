-----------
-- Regra --
-----------

-- 1. Gerar tabela de UNION dos alertas PRODES e DETER;
-- 2. Comparar cada imóvel e determinar o seu percentual de variação entre a primeira geometria e a última pós desmatamento (pct_dif = (area_ultima_geom – area_primeira_geom)/(area_primeira_geom);
-- 3. WHERE dat_alerta IS BETWEEN (dat_primeira_data AND dat_ultima_data) AND pct_dif_area <> 0

---------
-- DDL --
---------

--DROP TABLE IF EXISTS processado.f_detalhe_imovel_mudanca_area_desmatamento CASCADE;
--
--CREATE TABLE processado.f_detalhe_imovel_mudanca_area_desmatamento (
--  id_f_detalhe_imovel_mudanca_area_desmatamento int8 NULL,
--	id_alertas int4 NULL,
--	tx_cod_imovel varchar(100) NULL,
--	id_imovel_inicial int8 NULL,
--	id_imovel_final int8 NULL,
--	dat_primeira_data timestamp NULL,
--	tx_orgao_alerta varchar(255) null,
--	area_calc_primeira_data double precision NULL,
--	area_calc_primeira_data_ha double precision NULL,
--	dat_ultima_data timestamp NULL,
--	area_calc_ultima_data double precision NULL,
--	area_calc_ultima_data_ha double precision NULL,
--	dif_area double precision NULL,
--	dif_area_ha double precision NULL,
--	perc_dif_area double precision NULL,
--	dat_alerta timestamp NULL,
--	area_calc_alerta float8 NULL,
--	area_calc_alerta_ha float8 NULL,
--	data_ultima_analise timestamptz NULL
--);

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS processado.f_detalhe_imovel_mudanca_area_desmatamento_seq;

CREATE SEQUENCE processado.f_detalhe_imovel_mudanca_area_desmatamento_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_imovel_mudanca_area_desmatamento_seq RESTART WITH 1;

ALTER TABLE processado.f_detalhe_imovel_mudanca_area_desmatamento DROP CONSTRAINT IF EXISTS f_detalhe_imovel_mudanca_area_desmatamento_pk;

truncate table processado.f_detalhe_imovel_mudanca_area_desmatamento;



with query_mudanca_area as (

select
    cadantigo.tx_cod_imovel,
	cadantigo.id_imovel as id_imovel_inicial,
	cadfinal.id_imovel as id_imovel_final,
	cadantigo.data_inicial as dat_primeira_data,
	cadantigo.area_inicial as area_calc_primeira_data,
	cadfinal.data_final as dat_ultima_data,
	cadfinal.area_final as area_calc_ultima_data,
	(cadfinal.area_final - cadantigo.area_inicial) as dif_area,
	case 
        when cadantigo.area_inicial > 0
	    then (cadfinal.area_final - cadantigo.area_inicial)/cadantigo.area_inicial
	    else null 
    end as perc_dif_area,
	now() as data_ultima_analise 
from

( -- cadastro inicial (mais antigo)
	select
	a.*
	from (
		select dia.tx_cod_imovel,
		dia.id_imovel,
		dia.dat_criacao as data_inicial,
		round(dia.area_calc_ir::numeric,4)::double precision as area_inicial,
		row_number() over (partition by dia.tx_cod_imovel order by dia.dat_criacao asc) as idx,
		count(*) over (partition by dia.tx_cod_imovel order by dia.dat_criacao asc) as qtd
		from processado.d_imoveis_alfa dia  
--		join processado.d_analise_codigo_florestal_alfa cf on dia.id_imovel = cf.id_imovel
		where
		
--		and dia.num_flg_ativo = TRUE
		dia.tx_cod_imovel is not null --and dia.tx_cod_imovel = 'PA-1505486-941B5AA2EB0E472B838E9030503EC528'
		and dia.tx_status_imovel <> 'RE'
		group by dia.tx_cod_imovel, dia.id_imovel, dia.dat_criacao, dia.area_calc_ir
	) as a
	where a.idx= 1
) cadantigo 

join

( -- cadastro final (mais recente)
	select
	a.*
	from (
		select dia.tx_cod_imovel,
		dia.id_imovel,
		dia.dat_criacao as data_final,
		round(dia.area_calc_ir::numeric,4) as area_final,
		row_number() over (partition by dia.tx_cod_imovel order by dia.dat_criacao desc) as idx,
		count(*) over (partition by dia.tx_cod_imovel order by dia.dat_criacao asc) as qtd
		from processado.d_imoveis_alfa dia  
--		join processado.d_analise_codigo_florestal_alfa cf on dia.id_imovel = cf.id_imovel
		where
		dia.num_flg_ativo = true and
		dia.tx_cod_imovel is not null --and dia.tx_cod_imovel = 'PA-1505486-941B5AA2EB0E472B838E9030503EC528'
		group by dia.tx_cod_imovel, dia.dat_criacao, dia.area_calc_ir,dia.id_imovel
	) as a
	where a.idx= 1
) as cadfinal
on cadantigo.tx_cod_imovel = cadfinal.tx_cod_imovel and  cadantigo.data_inicial <> cadfinal.data_final

order by cadantigo.qtd desc

) 





insert into processado.f_detalhe_imovel_mudanca_area_desmatamento
    
    select 
	nextval('processado.f_detalhe_imovel_mudanca_area_desmatamento_seq') as id_f_detalhe_imovel_mudanca_area_desmatamento,
	daa.id_alertas,
	qma.tx_cod_imovel,
	qma.id_imovel_inicial,
	qma.id_imovel_final,
	qma.dat_primeira_data,
	daa.tx_orgao_alerta,
	qma.area_calc_primeira_data,
	qma.area_calc_primeira_data / 10000 as area_calc_primeira_data_ha, 
	qma.dat_ultima_data,
	qma.area_calc_ultima_data,
	qma.area_calc_ultima_data / 10000 as area_calc_ultima_data_ha,
	qma.dif_area,
	qma.dif_area as dif_area_ha,
	qma.perc_dif_area,
	daa.dat_alerta,
	daa.area_calc_alerta,
	daa.area_calc_alerta as area_calc_alerta_ha,
	now() as data_ultima_analise
	--into processado.f_detalhe_imovel_mudanca_area_desmatamento
	
	from 
        query_mudanca_area qma
    inner join 
        processado.f_detalhe_imovel_alertas fdial  on (fdial.id_imovel = qma.id_imovel_final)
    inner join
        processado.d_alertas_alfa daa on (daa.id_alertas = fdial.id_alertas)
    where
        qma.perc_dif_area <> 0 
		and (
			daa.tx_orgao_alerta =  'PRODES' 
			and daa.dat_alerta between  qma.dat_primeira_data and qma.dat_ultima_data )
		or (
			daa.tx_orgao_alerta = 'DETER' 
			and daa.dat_alerta between qma.dat_primeira_data and qma.dat_ultima_data
			and daa.ano_alerta in (DATE_PART('year', now()), (DATE_PART('year', now()) - 1) )
			)

;

-- Query OK, 95414 rows affected (execution time: 15,105 sec; total time: 15,105 sec)

ALTER TABLE processado.f_detalhe_imovel_mudanca_area_desmatamento ADD CONSTRAINT f_detalhe_imovel_mudanca_area_desmatamento_pk PRIMARY KEY (id_f_detalhe_imovel_mudanca_area_desmatamento);
