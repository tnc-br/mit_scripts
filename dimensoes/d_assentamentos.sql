-----------
-- Regra --
-----------

-- d_assentamentos_mit_alfa

-- 1. Fazer union all das bases de quilombolas do INCRA e ITERPA;
-- 2. Filtrar base do INCRA para cd_uf = 'PA';
-- 3. Criar a coluna 'tx_orgao_resp' e colocar 'ITERPA' e 'INCRA' para os respectivos casos;
-- 4. Inserir área calculada;
-- 5. Filtrar ind_tipo_imovel = 'AST', flg_ativo = true e ind_status_imovel <> ('SU', 'CA')
-- 6. Definir tx_orgao_responsavel do imóvel como 'SEMAS';
-- 7. d_assentamentos_alfa_pk definida como chave primária;
-- 8. d_assentamentos_alfa_fk definido como chave estrangeira referenciando id_assentamentos das tabelas alfa e geo. 


-- d_assentamentos_mit_geo

-- 1. Fazer union all das bases de quilombolas do INCRA e ITERPA;
-- 2. Filtrar base do INCRA para cd_uf = 'PA';
-- 3. Inserir geometria transformada para SRID 654;
-- 4. Filtrar ind_tipo_imovel = 'PCT' e definir tx_orgao_responsavel como 'SEMAS';
-- 5. d_assentamentos_geo_pk definida como chave primária;
-- 6. Cria um índice chamado d_assentamentos_geo_idx usando GIST. 


------------
-- Script --
------------

--Camada Assentamentos
ALTER TABLE processado.d_assentamentos_mit_alfa DROP CONSTRAINT IF EXISTS d_assentamentos_mit_alfa_fk;
ALTER TABLE processado.d_assentamentos_mit_alfa DROP CONSTRAINT IF EXISTS d_assentamentos_mit_alfa_pk;
ALTER TABLE processado.d_assentamentos_mit_geo DROP CONSTRAINT IF EXISTS d_assentamentos_mit_geo_pk;
DROP INDEX IF EXISTS processado.d_assentamentos_mit_geo_idx;


TRUNCATE TABLE
	processado.d_assentamentos_mit_alfa;

insert into processado.d_assentamentos_mit_alfa

select * 
--into processado.d_assentamentos_mit_alfa
from
 (
 select 
            gid as id_assentamentos,
            null as id_imovel,
            gid as id_incra,
            null as id_iterpa,
            nome_proje as tx_nome,
            SUBSTRING(nome_proje, 1, POSITION(' ' IN nome_proje)-1) AS tx_modalidade,
            num_famili as num_familia, 
            ap.cd_sipra  as cod_assentamento, 
            descricao_ as descricao, 
            st_area(st_transform(ap.geom,654)) as area_calc_assentamentos,
            'INCRA' as tx_orgao_resp
    FROM bruto.assentamentos_incra ap 
 where ap.uf = 'PA'

 union
 
 select
 	    ai.gid+100000  as id_assentamentos,
        null as id_imovel,
 		null as id_incra,
        ai.gid  as id_iterpa,
        ai.localidade as tx_nome,
        modalidade as tx_modalidade,
        ai.familia as num_familia,
        null as cod_assentamento, 
        null  as descricao, 
        st_area(st_transform(ai.geom,654)) as area_calc_assentamentos,
        'ITERPA' as tx_orgao_resp
    from bruto.assentamentos_iterpa ai

 union
 
 select
        ROW_NUMBER() OVER(ORDER BY si.idt_imovel ASC)+200000 as id_assentamentos,
        --si.gid+200000  as id_assentamentos,
        si.idt_imovel::text as id_imovel,
        null  as id_iterpa,
        null as id_incra,
        si.nom_imovel as tx_nome,
        null as modalidade,
        null as num_familia, 
        si.cod_imovel as cod_assentamento, --era cd_sipra, alterar para as bases que vem do INCRA e ITERPA também 
        null  as descricao, 
        null as area_calc_assentamentos,
        --st_area(st_transform(si.geom,654)) as area_calc_assentamentos,
        'SEMAS' as tx_orgao_resp
    from bruto.sv_imovel si
 where si.ind_tipo_imovel = 'AST'
 and si.flg_ativo = true
 and si.ind_status_imovel not in  ('SU', 'CA')
) q1
;

-- CAMADA GEO

TRUNCATE TABLE processado.d_assentamentos_mit_geo;

insert into processado.d_assentamentos_mit_geo
select * 
--into processado.d_assentamentos_mit_geo

from
(
 select ap.gid as id_assentamentos, 
        st_makevalid(st_transform(ap.geom,654)) as geom 
 from 
	bruto.assentamentos_incra ap
where ap.uf = 'PA'

 union
 
 select ai.gid+100000 as id_assentamentos, 
       st_transform(ai.geom,654) as geom 
 from 
	bruto.assentamentos_iterpa ai 
	
 union 
 
 select 
     ROW_NUMBER() OVER(ORDER BY si.idt_imovel ASC)+200000 as id_assentamentos,
     st_makevalid(st_transform(si.geo_area_imovel::geometry,654)) as geom
 from bruto.sv_imovel si 
 where 
    si.ind_tipo_imovel = 'AST'
    and si.flg_ativo = true
    and si.ind_status_imovel not in  ('SU', 'CA')
 
) q1;



ALTER TABLE processado.d_assentamentos_mit_geo ADD CONSTRAINT d_assentamentos_mit_geo_pk PRIMARY KEY (id_assentamentos);
ALTER TABLE processado.d_assentamentos_mit_alfa ADD CONSTRAINT d_assentamentos_mit_alfa_pk PRIMARY KEY (id_assentamentos);
ALTER TABLE processado.d_assentamentos_mit_alfa ADD CONSTRAINT d_assentamentos_mit_alfa_fk FOREIGN KEY (id_assentamentos) REFERENCES processado.d_assentamentos_mit_geo(id_assentamentos);
CREATE INDEX d_assentamentos_mit_geo_idx ON processado.d_assentamentos_mit_geo USING gist (geom);

--2401 rows returned (execution time: 6,078 sec; total time: 6,109 sec)