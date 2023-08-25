
do $$

begin

raise notice 'inicio: %', now();

for counter in 20.. (select count(*) FROM processado.d_zona_compra_frigorifico_alfa)   loop	    



	insert into processado.f_zona_compra_imoveis  
		select
					nextval('processado.f_zona_compra_imoveis_seq') as id_f_zona_compra_imoveis,
					q1.id_zc,
					q1.tx_razao_social,
					st_area(st_union(st_intersection(dig.geom,q1.geom))) as area_over_frigorifico,
					count(dia.id_imovel)::int as qtd_imoveis,
					now() as data_ultima_analise
		from
			processado.d_imoveis_alfa dia
		inner join processado.d_imoveis_geo dig on (dia.id_imovel  = dig.id_imovel) and dia.tx_tipo_imovel = 'IRU' and dia.num_flg_ativo = true,
			(
				select 
					zcfa.id_zc,
					zcfa.tx_razao_social,
					zcfg.geom
				from 
					processado.d_zona_compra_frigorifico_alfa zcfa
					inner join processado.d_zona_compra_frigorifico_geo zcfg on (zcfa.id_zc = zcfg.id_zc) 
					limit 1 offset counter * 1) q1
		where
			st_intersects(st_simplify(dig.geom, 0.01), st_simplify(q1.geom, 0.01))
		group by q1.id_zc, q1.tx_razao_social	
;

		raise notice 'counter: %', counter;

 

   end loop;

   raise notice 'fim: %', now();

end;

$$;


 

