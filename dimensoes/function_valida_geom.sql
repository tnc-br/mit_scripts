CREATE OR REPLACE FUNCTION valida_geom(p_schema TEXT, p_table TEXT, p_id_col TEXT)
RETURNS void AS $$
DECLARE
    cTable RECORD;
BEGIN
    EXECUTE FORMAT('UPDATE %I.%I AS t1
                    SET geom = (
                        CASE WHEN u = ''ST_GeometryCollection'' THEN cTable.b_geom ELSE u_geom END
                    )
                    FROM (
                        SELECT %I AS id, ST_UNION(geom1) AS u_geom, ST_GeometryType(ST_UNION(geom1)) AS u, ST_BUFFER(ST_UNION(geom1), 0) AS b_geom
                        FROM (
                            SELECT %I, (ST_DUMP(ST_SETSRID(ST_MAKEVALID(ST_GEOMFROMGEOJSON(ST_ASGEOJSON(geom))), 654))) .geom AS geom1
                            FROM %I.%I
                            WHERE NOT ST_ISVALID(geom)
                        ) AS wrapTable1
                        GROUP BY %I
                    ) AS cTable
                    WHERE t1.%I = cTable.id AND cTable.id IS NOT NULL;',
                    p_schema, p_table, p_id_col, p_id_col, p_schema, p_table, p_id_col, p_id_col);
END;
$$ LANGUAGE plpgsql;


select public.valida_geom('processado','d_areas_quilombolas_geo','id_areas_quilombolas');
select public.valida_geom('processado','d_assentamentos_geo','id_assentamentos');
select public.valida_geom('processado','d_autos_infracao_geo','id_auto_infracao');
select public.valida_geom('processado','d_embargos_geo','id_embargos');
select public.valida_geom('processado','d_florestas_publicas_geo','id_florestas_publicas');
select public.valida_geom('processado','d_imoveis_geo','id_imovel');
select public.valida_geom('processado','d_malha_estadual_geo','id_uf');
select public.valida_geom('processado','d_alertas_geo','id_alertas');
select public.valida_geom('processado','d_malha_municipal_geo','id_municipio');
select public.valida_geom('processado','d_massa_dagua_geo','id_massadagua');
select public.valida_geom('processado','d_terras_indigenas_pa_geo','id_terras_indigenas');
select public.valida_geom('processado','d_unidades_conservacao_geo','id_unidades_conservacao');


--lembrar de remover a coluna geom_valid de todos os scripts, e ajustar esse script





--SELECT minhafuncao(p.tablename) FROM pg_catalog.pg_tables p where p.schemaname = 'processado' and p.tablename like '%_geo' ;


--select count(*) from processado.d_embargos_geo d
--where st_isvalid(d.geom) = false

--select valida_geom('processado', 'd_embargos_geo', 'id_embargos');