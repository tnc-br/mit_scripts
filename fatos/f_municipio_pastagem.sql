---------
-- DDL --
---------

--DROP TABLE IF EXISTS tm_sobreposicao.f_municipio_pastagem
--
--CREATE TABLE tm_sobreposicao.f_municipio_pastagem (
--	id_f_municipio_pastagem int8 NULL,	
--	tx_nome_municipio varchar NULL,
--	tipo_pastagem text NULL,
--	total numeric NULL
--);

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS tm_sobreposicao.f_municipio_pastagem_seq;

CREATE SEQUENCE tm_sobreposicao.f_municipio_pastagem_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE tm_sobreposicao.f_municipio_pastagem_seq RESTART WITH 1;
ALTER TABLE tm_sobreposicao.f_municipio_pastagem DROP CONSTRAINT IF EXISTS f_municipio_pastagem_pk;

truncate table tm_sobreposicao.f_municipio_pastagem;

insert into	tm_sobreposicao.f_municipio_pastagem 
SELECT 
    nextval('tm_sobreposicao.f_municipio_pastagem_seq') as id_f_municipio_pastagem,
	dmma.tx_nome_municipio, 
    --fdip.raster_val, 
    case when fdip.raster_val = 1 then 'Degradação Severa'
         when fdip.raster_val = 2 then 'Degradação Moderada'
         else 'Degradação Ausente' end as tipo_pastagem,
    COUNT(fdip.id_imovel) AS total
FROM processado.f_detalhe_imovel_pastagem fdip
	join processado.d_imoveis_alfa dia on dia.id_imovel = fdip.id_imovel 
	join processado.d_malha_municipal_alfa dmma on dmma.id_municipio = dia.id_municipio
GROUP BY tx_nome_municipio, raster_val
ORDER BY tx_nome_municipio, raster_val;

ALTER TABLE tm_sobreposicao.f_municipio_pastagem ADD CONSTRAINT f_municipio_pastagem_pk PRIMARY KEY (id_f_municipio_pastagem);
	