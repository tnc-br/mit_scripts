
---------
-- DDL --
---------

-- DROP TABLE IF EXISTS processado.f_detalhe_quilombos_alertas;
--
--CREATE TABLE processado.f_detalhe_quilombos_alertas (
--  id_f_detalhe_quilombos_alertas int8 NULL,
--	id_areas_quilombolas int8 NULL,
--	id_alertas int4 NULL,
--	tx_nome_uc varchar(255) NULL,
--	dat_alerta timestamp NULL,
--	tx_orgao_alerta varchar(255) NULL,
--	area_over_assentamentos float8 NULL
--);

------------
-- Script --
------------
DROP SEQUENCE IF EXISTS processado.f_detalhe_quilombos_alertas_seq;

CREATE SEQUENCE processado.f_detalhe_quilombos_alertas_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

ALTER SEQUENCE processado.f_detalhe_quilombos_alertas_seq RESTART WITH 1;


ALTER TABLE processado.f_detalhe_quilombos_alertas DROP CONSTRAINT IF EXISTS f_detalhe_quilombos_alertas_pk;

TRUNCATE TABLE processado.f_detalhe_quilombos_alertas;

with alertas_prodes_br as (

    select 
        aqa.id_areas_quilombolas,
        daa.id_alertas,
        daa.tx_nome_uc,
        daa.dat_alerta,
        daa.tx_orgao_alerta,
        st_area(processado.st_union_or_ignore(st_intersection(aqg.geom, dag.geom))) as area_over_assentamentos
    from 
        processado.d_areas_quilombolas_alfa aqa
         inner join processado.d_areas_quilombolas_geo aqg on (aqa.id_areas_quilombolas = aqg.id_areas_quilombolas),
        processado.d_alertas_alfa daa
    inner join processado.d_alertas_geo dag on (daa.id_alertas = dag.id_alertas)
    
    where 
        st_intersects(aqg.geom, dag.geom) and st_touches(aqg.geom, dag.geom) = false
        and daa.tx_orgao_alerta = 'PRODES'
    group by aqa.id_areas_quilombolas, daa.id_alertas, daa.tx_nome_uc, daa.dat_alerta, daa.tx_orgao_alerta 
    --limit 10000
),

    alertas_deter_br as (

    select 
        aqa.id_areas_quilombolas,
        daa.id_alertas,
        daa.tx_nome_uc,
        daa.dat_alerta,
        daa.tx_orgao_alerta,
        st_area(processado.st_union_or_ignore(st_intersection(aqg.geom, dag.geom))) as area_over_assentamentos
    from 
        processado.d_areas_quilombolas_alfa aqa
         inner join processado.d_areas_quilombolas_geo aqg on (aqa.id_areas_quilombolas = aqg.id_areas_quilombolas),
        processado.d_alertas_alfa daa
    inner join processado.d_alertas_geo dag on (daa.id_alertas = dag.id_alertas)
    
    where 
        st_intersects(aqg.geom, dag.geom) and st_touches(aqg.geom, dag.geom) = false
        and daa.tx_orgao_alerta = 'DETER'
	    and daa.ano_alerta in (DATE_PART('year', now()), (DATE_PART('year', now()) - 1) )
    group by aqa.id_areas_quilombolas, daa.id_alertas, daa.tx_nome_uc, daa.dat_alerta, daa.tx_orgao_alerta  
    --limit 10000
)   


insert into processado.f_detalhe_quilombos_alertas
select 
nextval('processado.f_detalhe_quilombos_alertas_seq') as id_f_detalhe_quilombos_alertas,
*
from 
(   select * from alertas_prodes_br
    union  
    select * from alertas_deter_br) query_union;


ALTER TABLE processado.f_detalhe_quilombos_alertas ADD CONSTRAINT f_detalhe_quilombos_alertas_pk PRIMARY KEY (id_f_detalhe_quilombos_alertas);
