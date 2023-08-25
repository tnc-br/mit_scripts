do $$

begin

raise notice 'inicio: %', now();

for counter in 5..9  loop

    with analise_espacial as (
        select
            dia.id_imovel,
            dia.tx_cod_imovel,
            q1.id_zc,
            st_area(dig.geom) as area_calc_ir,
            st_area(st_union(st_intersection(dig.geom,q1.geom)))as area_over_frigorifico,
            now() as data_ultima_analise
        from
            processado.d_imoveis_alfa dia
        inner join processado.d_imoveis_geo dig on (dia.id_imovel = dig.id_imovel) and dia.tx_tipo_imovel = 'IRU' and dia.num_flg_ativo = true,
            (
            select
                zcfa.id_zc,
                zcfg.geom
            from
                processado.d_zona_compra_frigorifico_alfa zcfa
                inner join processado.d_zona_compra_frigorifico_geo zcfg on (zcfa.id_zc = zcfg.id_zc)
                limit 1 offset counter * 1) q1
        where
            st_intersects(dig.geom,q1.geom)
        group by dia.id_imovel, dia.tx_cod_imovel,q1.id_zc, dig.geom, q1.geom
    )

	insert into processado.f_detalhe_imovel_zona_compra_frigorifico
    select
            id_zc,
            id_imovel,
            tx_cod_imovel,
            area_calc_ir,
            data_ultima_analise,
            area_over_frigorifico,
            area_over_frigorifico / 10000 as area_over_frigorifico_ha,
            area_calc_ir / 10000 as area_calc_ir_ha,
            round((area_over_frigorifico / area_calc_ir)::numeric, 4) as perc_over_frigorifico
        from analise_espacial
    where area_over_frigorifico > 0;

    raise notice 'counter: %', counter;

end loop;

raise notice 'fim: %', now();

end;

$$;