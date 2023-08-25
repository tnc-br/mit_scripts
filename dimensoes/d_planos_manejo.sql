-----------
-- Regra --
-----------

-- 1.Fazer o join da tabela bruta ''objeto_tramitavel'' com a tabela ''situacao'' para obter o ''tx_descricao'' ; 
-- 2. Inserir na tabela ''projeto'' o campo ''fl_ativo'';
-- 3. Inserir na tabela ''projeto'' o campo '' as id_pmfs_planos_manejosda'',''num_flag_planos_manejosda_ativo'', ''dat_emissao'' a partir da tabela ''planos_manejosda'';
-- 4. Inserir na tabela ''projeto'' o campo '' as id_pmfs_tca'' e ''num_flag_tca_ativo'', ''dat_emissao'' a partir da tabela ''termo_compromisso'';
-- 5. Inserir na tabela de imoveis as colunas ''geo_app_recompor_total_aa'', ''geo_reserva_legal_recompor_aa'';
-- 6. Fazer o left join da tabela de imoveis com num_flag_ativo = ''true'' na tabela ''projeto'' on tabela_imoveis. as id_pmfs_imovel = tabela_projeto. as id_pmfs_imovel para projetos com fl_ativo = ''true'';


-- as id_pmfs_objeto_tramitavel - 
---------
-- DDL --
---------

--DROP TABLE IF EXISTS processado.d_planos_manejos_geo cascade;
--
--CREATE TABLE processado.d_planos_manejos_geo (
--	id_pmfs int4 NULL,
--	geom geometry NULL
--);
--
--
--DROP TABLE IF EXISTS processado.d_planos_manejos_alfa cascade;
--
--CREATE TABLE processado.d_planos_manejos_alfa (
--	id_pmfs int4 NULL,
--	tx_nom_proprietario varchar(254) NULL,
--	tx_cpf_cnpj_proprietaria varchar(25) NULL,
--	tx_nome_imovel varchar(40) NULL,
--	tx_processo varchar(20) NULL,
--	tx_responsavel_tecnico varchar(254) NULL,
--	tx_cpf_cnpj_responsavel_tecnico varchar(25) NULL,
--	tx_num_autef varchar(25) NULL,
--	tx_ano_autef varchar(15) NULL,
--	dat_emissao_autef varchar(30) NULL,
--	dat_validade_autef varchar(30) NULL,
--	tx_atividade varchar(150) NULL,
--	tx_fase_processo varchar(50) NULL,
--	tx_situacao_fundiario varchar(80) NULL,
--	tx_nome_municipio varchar(45) NULL,
--	tx_nome_uf varchar(15) NULL,
--	tx_poligonal varchar(30) NULL,
--	tx_cod_imovel varchar(100) NULL,
--	area_calc_upa double precision NULL,
--	tx_volume_m3 varchar(50) NULL,
--	num_volume_m3 varchar(50) NULL
--);

--tudo que começar com geo na bruto.planos_manejos_dados_analise_pa entra aqui

------------
-- Script --
------------

ALTER TABLE processado.d_planos_manejos_alfa DROP CONSTRAINT IF EXISTS d_planos_manejos_alfa_fk;
ALTER TABLE processado.d_planos_manejos_alfa DROP CONSTRAINT IF EXISTS d_planos_manejos_alfa_pk;
ALTER TABLE processado.d_planos_manejos_geo DROP CONSTRAINT IF EXISTS d_planos_manejos_geo_pk;
DROP INDEX IF EXISTS processado.d_planos_manejos_geo_idx;


truncate table processado.d_planos_manejos_geo cascade;

insert into processado.d_planos_manejos_geo

select
	upa.id as id_pmfs,
	st_makevalid(st_transform(upa.geom,654)) as geom
from
	bruto.upa upa
;

truncate table processado.d_planos_manejos_alfa;

insert into processado.d_planos_manejos_alfa

select
	upa.id as id_pmfs,
	upa.detentor as tx_nom_proprietario,
	upa.cpf_detent as tx_cpf_cnpj_proprietaria,
	upa.nomeimovel as tx_nome_imovel,
	upa.processo as tx_processo,
	upa.rt as tx_responsavel_tecnico,
	upa.cpf_rt as tx_cpf_cnpj_responsavel_tecnico,
	upa.nº_autef as tx_num_autef,
	upa.anoautef as tx_ano_autef,
	upa.emi_autef as dat_emissao_autef,
	upa.val_autef as dat_validade_autef,
	upa.atividade as tx_atividade,
	upa.fase_proce as tx_fase_processo,
	upa.sit_fundi as tx_situacao_fundiario,
	upa.municipio as tx_nome_municipio,
	upa.uf as tx_nome_uf,
	upa.poligonal as tx_poligonal,
	upa.codigo_car as tx_cod_imovel,
	ST_AREA(geom) as area_calc_upa,
    upa."volume_m³" as tx_volume_m3,
	CASE WHEN REPLACE("upa"."volume_m³", ',', '.') ~ '^[-+]?[0-9]+(\.[0-9]+)?$'
            THEN CAST(REPLACE("upa"."volume_m³", ',', '.') AS DOUBLE PRECISION)
            ELSE NULL
       END AS num_volume_m3

from
	bruto.upa upa;

ALTER TABLE processado.d_planos_manejos_geo ADD CONSTRAINT d_planos_manejos_geo_pk PRIMARY KEY (id_pmfs);
ALTER TABLE processado.d_planos_manejos_alfa ADD CONSTRAINT d_planos_manejos_alfa_pk PRIMARY KEY (id_pmfs);
ALTER TABLE processado.d_planos_manejos_alfa ADD CONSTRAINT d_planos_manejos_alfa_fk FOREIGN KEY (id_pmfs) REFERENCES processado.d_planos_manejos_geo(id_pmfs);	
CREATE INDEX d_planos_manejos_geo_idx ON processado.d_planos_manejos_geo USING gist (geom);
