
---------
-- DDL --
---------

--DROP TABLE processado.d_lista_suja_trabalho_escravo;
--
--CREATE TABLE processado.d_lista_suja_trabalho_escravo (
--	id_lista_suja int4 NULL,
--	ano_acao_fiscal int4 NULL,
--	tx_sigla_uf varchar NULL,
--	tx_empregador varchar NULL,
--	tx_cpf_cpnj varchar NULL,
--	tx_estabelecimento varchar NULL,
--	num_trabalhadores_envolvidos int4 NULL,
--	tx_cnae varchar NULL,
--	dat_decisao_adm_procedencia date NULL,
--	dat_inclusao_empregadores date NULL
--);



------------
-- Script --
------------


ALTER TABLE processado.d_lista_suja_trabalho_escravo DROP CONSTRAINT IF EXISTS d_lista_suja_trabalho_escravo_pk;

truncate table processado.d_lista_suja_trabalho_escravo;

insert into processado.d_lista_suja_trabalho_escravo

SELECT 
    lste.id as id_lista_suja,
    lste.ano_acao_fiscal as ano_acao_fiscal,
    lste.uf as tx_sigla_uf,
    lste.empregador as tx_empregador,
    REPLACE(lste.cnpj_cpf, '.', '') as tx_cpf_cpnj,
    lste.estabelecimento as tx_estabelecimento,
    lste.trabalhadores_envolvidos as num_trabalhadores_envolvidos,
    lste.cnae as tx_cnae,
    lste.dt_decisao_administrativa_procedencia as dat_decisao_adm_procedencia,
    lste.dt_inclusao_cadastro_empregadores as dat_inclusao_empregadores
FROM 
    bruto.lista_suja_trabalho_escravo_br lste
    
where

lste.uf = 'PA'


;

ALTER TABLE processado.d_lista_suja_trabalho_escravo ADD CONSTRAINT d_lista_suja_trabalho_escravo_pk PRIMARY KEY (id_lista_suja);


