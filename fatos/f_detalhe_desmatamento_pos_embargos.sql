
---------
-- DDL --
---------

--DROP TABLE IF EXISTS processado.f_detalhe_desmatamento_pos_embargos cascade;
--
--CREATE TABLE processado.f_detalhe_desmatamento_pos_embargos (
--    id_f_detalhe_desmatamento_pos_embargos int8 NULL,
--	tx_seq_tad int8 NULL,
--	tx_seq_auto int8 NULL,
--	tx_codigo varchar NULL,
--	tx_orgao_resp text NULL,
--	dat_alerta timestamp NULL,
--	tx_classe_alerta varchar(255) NULL,
--	id_alertas int4 NULL,
--	dat_embargo timestamp NULL,
--	id_embargos int8 NULL,
--	area_over_embargos float8 NULL,
--    data_ultima_analise timestamptz NULL
--);

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS processado.f_detalhe_desmatamento_pos_embargos_seq;

CREATE SEQUENCE processado.f_detalhe_desmatamento_pos_embargos_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_desmatamento_pos_embargos_seq RESTART WITH 1;



ALTER TABLE processado.f_detalhe_desmatamento_pos_embargos DROP CONSTRAINT IF EXISTS f_detalhe_desmatamento_pos_embargos_pk;

truncate table processado.f_detalhe_desmatamento_pos_embargos;

with query_embargos as (

    select 
        dea.tx_seq_tad,
        dea.tx_seq_auto,
        dea.tx_codigo,
        dea.tx_orgao_resp,   
        daa.dat_alerta,
        daa.tx_classe_alerta,
        daa.id_alertas,
        dea.dat_embargo,
        dea.id_embargos,
        st_area(processado.st_union_or_ignore(st_intersection(deg.geom_buffer , dag.geom))) as area_over_embargos,
        now() as data_ultima_analise

    from
        processado.d_embargos_alfa dea
    inner join processado.d_embargos_geo deg on (dea.id_embargos = deg.id_embargos),
    processado.d_alertas_geo dag
    inner join processado.d_alertas_alfa daa on (dag.id_alertas = daa.id_alertas)
    
    where
        daa.tx_orgao_alerta = 'PRODES'
        and daa.dat_alerta > dea.dat_embargo
        and st_intersects(deg.geom_buffer, dag.geom) and st_touches(deg.geom_buffer, dag.geom) = false 
        and st_intersects(deg.geom, (select geom from processado.d_malha_estadual_geo where id_uf = 15 ) )
    group by dea.tx_seq_tad, dea.tx_seq_auto, dea.tx_codigo, dea.tx_orgao_resp, daa.dat_alerta, daa.tx_classe_alerta, deg.geom, dag.geom, dea.dat_embargo, daa.id_alertas, dea.id_embargos

)



insert into processado.f_detalhe_desmatamento_pos_embargos
select 
    nextval('processado.f_detalhe_desmatamento_pos_embargos_seq') as id_f_detalhe_desmatamento_pos_embargos,
    * 
from query_embargos;

ALTER TABLE processado.f_detalhe_desmatamento_pos_embargos ADD CONSTRAINT f_detalhe_desmatamento_pos_embargos_pk PRIMARY KEY (id_f_detalhe_desmatamento_pos_embargos);
