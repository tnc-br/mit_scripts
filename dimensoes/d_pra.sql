-----------
-- Regra --
-----------

-- 1.Fazer o join da tabela bruta ''objeto_tramitavel'' com a tabela ''situacao'' para obter o ''tx_descricao'' ; 
-- 2. Inserir na tabela ''projeto'' o campo ''fl_ativo'';
-- 3. Inserir na tabela ''projeto'' o campo ''id_projetoda'',''num_flag_prada_ativo'', ''dat_emissao'' a partir da tabela ''prada'';
-- 4. Inserir na tabela ''projeto'' o campo ''id_tca'' e ''num_flag_tca_ativo'', ''dat_emissao'' a partir da tabela ''termo_compromisso'';
-- 5. Inserir na tabela de imoveis as colunas ''geo_app_recompor_total_aa'', ''geo_reserva_legal_recompor_aa'';
-- 6. Fazer o left join da tabela de imoveis com num_flag_ativo = ''true'' na tabela ''projeto'' on tabela_imoveis.id_imovel = tabela_projeto.id_imovel para projetos com fl_ativo = ''true'';


--id_objeto_tramitavel - 
---------
-- DDL --
---------






--DROP TABLE IF EXISTS processado.d_pra_geo CASCADE;
--
--CREATE TABLE processado.d_pra_geo (
--    uuid_pra uuid NOT NULL,
--    id_analise int4 NULL,
--    id_projeto int4 NULL,
--    id_imovel int4 NULL,
--	geo_arl_proposta_aa public.geometry NULL,
--	geo_arl_averbada_aa public.geometry NULL,
--	geo_arl_aprovada_nao_averbada_aa public.geometry NULL,
--	geo_recomposicao public.geometry NULL
--);
--
--
--DROP TABLE IF EXISTS processado.d_pra_alfa CASCADE;
--
--CREATE TABLE processado.d_pra_alfa (
--    uuid_pra uuid NOT NULL,
--    id_analise int4 NULL,
--    id_projeto int4 NULL,
--	id_imovel int4 NULL,
--	tx_cod_imovel varchar(100) NULL,
--	tx_tipo_imovel varchar(3) NULL,
--	tx_des_condicao text NULL,
--	tx_perfil text NULL,
--	nm_tipo_area_regularidade_imovel varchar(100) NULL,
--	area_regularidade_ha numeric NULL,
--	data_cadastro timestamp NULL,
--	flag_tca bool NULL,
--	flag_prada bool NULL,
--	tx_nm_condicao varchar(120) NULL,
--    num_area_arl_proposta_aa float8 NULL,
--	num_area_arl_averbada_aa float8 NULL,
--	num_area_arl_aprovada_nao_averbada_aa float8 NULL,
--	data_emissao timestamp NULL
--);

--tudo que começar com geo na bruto.pra_dados_analise_pa entra aqui


------------
-- Script --
------------

ALTER TABLE processado.d_pra_alfa DROP CONSTRAINT IF EXISTS d_pra_alfa_fk;
ALTER TABLE processado.d_pra_alfa DROP CONSTRAINT IF EXISTS d_pra_alfa_pk;
ALTER TABLE processado.d_pra_geo DROP CONSTRAINT IF EXISTS d_pra_geo_pk;


truncate table processado.d_pra_geo cascade;

insert into processado.d_pra_geo

select 
    md5(concat(id_analise,id_projeto,id_imovel,tx_cod_imovel,tx_tipo_imovel,tx_des_condicao,tx_perfil,nm_tipo_area_regularidade_imovel,area_regularidade_ha,data_cadastro,flag_tca ,flag_prada ,tx_nm_condicao,num_area_arl_proposta_aa,num_area_arl_averbada_aa,num_area_arl_aprovada_nao_averbada_aa,data_emissao,geo_arl_proposta_aa,geo_arl_averbada_aa,geo_arl_aprovada_nao_averbada_aa,geo_recomposicao))::uuid as uuid_pra,
    id_analise,
    id_projeto,
    id_imovel,
    geo_arl_proposta_aa,
    geo_arl_averbada_aa,
    geo_arl_aprovada_nao_averbada_aa,
    geo_recomposicao
    from
(

select
    sva.id_analise,
    ppp.id AS id_projeto,
    ppp.id_imovel,
    dia.tx_cod_imovel,
    dia.tx_tipo_imovel,
    dia.tx_des_condicao,
    dia.tx_perfil,
    ptari.nm_tipo_area_regularidade_imovel,
    SUM(parir.nu_area) AS area_regularidade_ha,
    MAX(ppp.data_cadastro) as data_cadastro,
    ptcp.ativo AS flag_tca,
    prap.ativo AS flag_prada,
    pc.nm_condicao as tx_nm_condicao,
    paaa.num_area_arl_proposta_aa,
    paaa.num_area_arl_averbada_aa,
    paaa.num_area_arl_aprovada_nao_averbada_aa,
    ptcp.data_emissao,
	st_makevalid(st_transform(paaa.geo_arl_proposta_aa, 654)) as geo_arl_proposta_aa,
	st_makevalid(st_transform(paaa.geo_arl_averbada_aa, 654)) as geo_arl_averbada_aa,
	st_makevalid(st_transform(paaa.geo_arl_aprovada_nao_averbada_aa, 654)) as geo_arl_aprovada_nao_averbada_aa,
	st_makevalid(st_transform(parir.the_geom, 654)) as geo_recomposicao
FROM
    bruto.pra_projetos_pa ppp
   	INNER JOIN processado.d_imoveis_alfa dia ON ppp.id_imovel = dia.id_imovel AND dia.num_flg_ativo = true
    LEFT JOIN bruto.pra_analise_area_antropizada paaa ON ppp.id_imovel = paaa.idt_imovel
    LEFT JOIN bruto.sv_analise sva ON sva.id_imovel = ppp.id_imovel
    LEFT JOIN bruto.pra_objeto_tramitavel pot ON pot.id_objeto_tramitavel = ppp.id_objeto_tramitavel
    LEFT JOIN bruto.pra_condicao pc ON pc.id_condicao = pot.id_condicao
    LEFT JOIN bruto.pra_termo_compromisso_pa ptcp ON ptcp.id_projeto = ppp.id
    LEFT JOIN bruto.pra_prada_pa prap ON ppp.id = prap.id
    LEFT JOIN bruto.pra_areas_regularidade_imovel_recomposicao parir ON parir.id_analise = sva.id_analise
    LEFT JOIN bruto.pra_tipo_area_regularidade_imovel ptari ON ptari.id_tipo_area_regularidade_imovel = parir.id_tipo_area_regularidade_imovel
WHERE
    ppp.removido = false
    AND pc.nm_condicao NOT IN ('Cancelado', 'Documentos recusados pelo jurídico', 'Projeto recusado pelo sistema', 'Compensação recusada pelo ofertante')
GROUP BY   
	sva.id_analise,
    ppp.id,
    ppp.id_imovel,
    dia.tx_cod_imovel,
    dia.tx_tipo_imovel,
    dia.tx_des_condicao,
    dia.tx_perfil,
    ptari.nm_tipo_area_regularidade_imovel,
    ptcp.ativo,
    prap.ativo,
    pc.nm_condicao,
    paaa.num_area_arl_proposta_aa,
    paaa.num_area_arl_averbada_aa,
    paaa.num_area_arl_aprovada_nao_averbada_aa,
    ptcp.data_emissao,
    paaa.geo_arl_proposta_aa,
    paaa.geo_arl_averbada_aa,
    paaa.geo_arl_aprovada_nao_averbada_aa,
    parir.the_geom    
) q1;


truncate table processado.d_pra_alfa;

insert into processado.d_pra_alfa
select 
    md5(concat(id_analise,id_projeto,id_imovel,tx_cod_imovel,tx_tipo_imovel,tx_des_condicao,tx_perfil,nm_tipo_area_regularidade_imovel,area_regularidade_ha,data_cadastro,flag_tca ,flag_prada ,tx_nm_condicao,num_area_arl_proposta_aa,num_area_arl_averbada_aa,num_area_arl_aprovada_nao_averbada_aa,data_emissao,geo_arl_proposta_aa,geo_arl_averbada_aa,geo_arl_aprovada_nao_averbada_aa,geo_recomposicao))::uuid as uuid_pra,
    id_analise,
    id_projeto,
    id_imovel,
    tx_cod_imovel,
    tx_tipo_imovel,
    tx_des_condicao,
    tx_perfil,
    nm_tipo_area_regularidade_imovel,
    area_regularidade_ha,
    data_cadastro,
    flag_tca ,
    flag_prada ,
    tx_nm_condicao,
    num_area_arl_proposta_aa,
    num_area_arl_averbada_aa,
    num_area_arl_aprovada_nao_averbada_aa,
    data_emissao
    from
(

select
    sva.id_analise,
    ppp.id AS id_projeto,
    ppp.id_imovel,
    dia.tx_cod_imovel,
    dia.tx_tipo_imovel,
    dia.tx_des_condicao,
    dia.tx_perfil,
    ptari.nm_tipo_area_regularidade_imovel,
    SUM(parir.nu_area) AS area_regularidade_ha,
    MAX(ppp.data_cadastro) as data_cadastro,
    ptcp.ativo AS flag_tca,
    prap.ativo AS flag_prada,
    pc.nm_condicao as tx_nm_condicao,
    paaa.num_area_arl_proposta_aa,
    paaa.num_area_arl_averbada_aa,
    paaa.num_area_arl_aprovada_nao_averbada_aa,
    ptcp.data_emissao,
	st_makevalid(st_transform(paaa.geo_arl_proposta_aa, 654)) as geo_arl_proposta_aa,
	st_makevalid(st_transform(paaa.geo_arl_averbada_aa, 654)) as geo_arl_averbada_aa,
	st_makevalid(st_transform(paaa.geo_arl_aprovada_nao_averbada_aa, 654)) as geo_arl_aprovada_nao_averbada_aa,
	st_makevalid(st_transform(parir.the_geom, 654)) as geo_recomposicao
FROM
    bruto.pra_projetos_pa ppp
   	INNER JOIN processado.d_imoveis_alfa dia ON ppp.id_imovel = dia.id_imovel AND dia.num_flg_ativo = true
    LEFT JOIN bruto.pra_analise_area_antropizada paaa ON ppp.id_imovel = paaa.idt_imovel
    LEFT JOIN bruto.sv_analise sva ON sva.id_imovel = ppp.id_imovel
    LEFT JOIN bruto.pra_objeto_tramitavel pot ON pot.id_objeto_tramitavel = ppp.id_objeto_tramitavel
    LEFT JOIN bruto.pra_condicao pc ON pc.id_condicao = pot.id_condicao
    LEFT JOIN bruto.pra_termo_compromisso_pa ptcp ON ptcp.id_projeto = ppp.id
    LEFT JOIN bruto.pra_prada_pa prap ON ppp.id = prap.id
    LEFT JOIN bruto.pra_areas_regularidade_imovel_recomposicao parir ON parir.id_analise = sva.id_analise
    LEFT JOIN bruto.pra_tipo_area_regularidade_imovel ptari ON ptari.id_tipo_area_regularidade_imovel = parir.id_tipo_area_regularidade_imovel
WHERE
    ppp.removido = false
    AND pc.nm_condicao NOT IN ('Cancelado', 'Documentos recusados pelo jurídico', 'Projeto recusado pelo sistema', 'Compensação recusada pelo ofertante')
GROUP BY   
	sva.id_analise,
    ppp.id,
    ppp.id_imovel,
    dia.tx_cod_imovel,
    dia.tx_tipo_imovel,
    dia.tx_des_condicao,
    dia.tx_perfil,
    ptari.nm_tipo_area_regularidade_imovel,
    ptcp.ativo,
    prap.ativo,
    pc.nm_condicao,
    paaa.num_area_arl_proposta_aa,
    paaa.num_area_arl_averbada_aa,
    paaa.num_area_arl_aprovada_nao_averbada_aa,
    ptcp.data_emissao,
    paaa.geo_arl_proposta_aa,
    paaa.geo_arl_averbada_aa,
    paaa.geo_arl_aprovada_nao_averbada_aa,
    parir.the_geom    
) q1;



ALTER TABLE processado.d_pra_geo ADD CONSTRAINT d_pra_geo_pk PRIMARY KEY (uuid_pra);
ALTER TABLE processado.d_pra_alfa ADD CONSTRAINT d_pra_alfa_pk PRIMARY KEY (uuid_pra);
ALTER TABLE processado.d_pra_alfa ADD CONSTRAINT d_pra_alfa_fk FOREIGN KEY (uuid_pra) REFERENCES processado.d_pra_geo(uuid_pra);