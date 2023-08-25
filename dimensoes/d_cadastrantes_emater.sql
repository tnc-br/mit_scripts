-----------
-- Regra --
-----------
 
---------
-- DDL --
---------

--DROP TABLE IF EXISTS processado.d_cadastrantes_emater_alfa cascade;
--
--CREATE TABLE processado.d_cadastrantes_emater_alfa (
--	tx_cod_imovel varchar(255) NULL,
--	tx_cpf_cnpj_cadastrante varchar(255) NULL,
--	tx_nome_cadastrante varchar(255) NULL,
--	tx_cod_protocolo varchar(255) NULL,
--	tx_status_imovel varchar(255) NULL,
--	tx_tipo_imovel varchar(255) NULL,
--	tx_nome_imovel varchar(255) NULL,
--	tx_nome_municipio varchar(255) NULL,
--	tx_nome_proprietario varchar(255) NULL,
--	tx_cpf_cnpj varchar(255) NULL,
--	tx_nome_logradouro varchar(255) NULL
--);

------------
-- Script --
------------

--ALTER TABLE processado.d_assentamentos_alfa DROP CONSTRAINT IF EXISTS d_assentamentos_alfa_fk;
--ALTER TABLE processado.d_assentamentos_alfa DROP CONSTRAINT IF EXISTS d_assentamentos_alfa_pk;
--ALTER TABLE processado.d_assentamentos_geo DROP CONSTRAINT IF EXISTS d_assentamentos_geo_pk;

truncate table processado.d_cadastrantes_emater_alfa;

insert into processado.d_cadastrantes_emater_alfa

select
	ce.cod_imovel as tx_cod_imovel,
	ce.cpf_cadast as tx_cpf_cnpj_cadastrante,
	ce.nom_cadast as tx_nome_cadastrante,
	ce.cod_protoc as tx_cod_protocolo,
	ce.ind_status as tx_status_imovel,
	ce.ind_tipo_i as tx_tipo_imovel,
	ce.nom_imovel as tx_nome_imovel,
	ce.imo_munici as tx_nome_municipio,
	ce.pessoas as tx_nome_proprietario,
	ce.cpfs_cnpjs as tx_cpf_cnpj,
	ce.end_lograd as tx_nome_logradouro
from
bruto.cadastrantes_emater ce;

--ALTER TABLE processado.d_assentamentos_geo ADD CONSTRAINT d_assentamentos_geo_pk PRIMARY KEY (id_assentamentos);
--ALTER TABLE processado.d_assentamentos_alfa ADD CONSTRAINT d_assentamentos_alfa_pk PRIMARY KEY (id_assentamentos);
--ALTER TABLE processado.d_assentamentos_alfa ADD CONSTRAINT d_assentamentos_alfa_fk FOREIGN KEY (id_assentamentos) REFERENCES processado.d_assentamentos_geo(id_assentamentos);

