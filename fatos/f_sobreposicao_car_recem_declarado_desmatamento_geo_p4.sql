
do $$
begin
raise notice 'inicio: %', now();
for counter in 1001..1500 loop
with analise_espacial_1 as (
    select
		fdidpd.id_imovel as id_imovel,
        fdidpd.tx_cod_imovel as cod_imovel,            
		dia.tx_nome_imovel,
		dia.tx_des_condicao,
		dia.tx_status_imovel,
 		dia.area_calc_ir,
 		dia.area_calc_ir/10000 as area_calc_ir_ha,     		 
		count(distinct fdidpd.id_alertas) as qtd_alertas,
		processado.st_union_or_ignore(dag.geom) as geo_area_agregada
	from 
	( select fd.*
	from processado.f_detalhe_imovel_desmatamento_pre_declaracao fd
	order by fd.id_imovel
	limit 100 offset counter * 100) fdidpd 
    join processado.d_alertas_geo dag on fdidpd.id_alertas = dag.id_alertas
    join processado.d_imoveis_alfa dia on fdidpd.id_imovel = dia.id_imovel and dia.num_flg_ativo = true            
	join processado.d_malha_estadual_geo dmeg  on st_intersects(dmeg.geom, dag.geom)
    where dmeg.id_uf = 15
    group by
    	fdidpd.id_imovel, 
        fdidpd.tx_cod_imovel,
 		dia.area_calc_ir,
 		dia.tx_nome_imovel,
		dia.tx_des_condicao,
		dia.tx_status_imovel
),
analise_espacial_2 as (
	select 
      	ig.id_imovel, 
      	st_area(an1.geo_area_agregada) as area_agregada,
      	st_intersection(ig.geom,an1.geo_area_agregada) as geom_intersection           
    from analise_espacial_1 an1 
    join processado.d_imoveis_geo ig on ig.id_imovel = an1.id_imovel
),
analise_espacial_3 as (
	select 
      	an2.id_imovel, 
      	st_area(an2.geom_intersection) as area_intersecao,
      	st_transform(an2.geom_intersection,4674) as geom
    from analise_espacial_2 an2
)

--drop table tm_sobreposicao.f_sobreposicao_car_recem_declarado_desmatamento_geo cascade;
insert into	tm_sobreposicao.f_sobreposicao_car_recem_declarado_desmatamento_geo 
select
	nextval('tm_sobreposicao.f_sobreposicao_car_recem_declarado_desmatamento_seq') as id_f_sobreposicao_car_recem_declarado_desmatamento,
   	a1.id_imovel,
   	a1.cod_imovel,
  	a1.area_calc_ir,
   	a1.area_calc_ir_ha,
   	a1.qtd_alertas,
   	a3.area_intersecao,
   	a3.area_intersecao/10000 as area_intersecao_ha,
   	a3.geom,
   	case when a1.area_calc_ir > 0 then 
      	a3.area_intersecao / a1.area_calc_ir
   	else 0
   	end as perc_intersecao
--INTO tm_sobreposicao.f_sobreposicao_car_recem_declarado_desmatamento_geo
from
	analise_espacial_1 a1 
    join analise_espacial_2 a2 on a1.id_imovel = a2.id_imovel
    join analise_espacial_3 a3 on a1.id_imovel = a3.id_imovel;

raise notice 'counter: %', counter;

 end loop;
 raise notice 'fim: %', now();
end;
$$;