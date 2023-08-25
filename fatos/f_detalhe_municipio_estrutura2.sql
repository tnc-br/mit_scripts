truncate processado.f_detalhe_municipio_estrutura2;

do $$
begin
 raise notice 'inicio: %', now();
 for counter in 0..((select count(*) from processado.f_detalhe_municipio_estrutura me) /10000) +1 loop		

	insert into processado.f_detalhe_municipio_estrutura2
	select fdme.*, st_area( st_intersection(dmmg.geom, defg.geom)) as area
	from
	(select me.* from 
	processado.f_detalhe_municipio_estrutura me  
	order by me.id_municipio
	limit 10000 offset counter * 10000
	) fdme
	join processado.d_malha_municipal_geo dmmg on dmmg.id_municipio = fdme.id_municipio
	join processado.d_estrutura_florestal_geo defg on defg.id_estrutura_florestal = fdme.id_estrutura_florestal;

	raise notice 'counter: %', counter;

 end loop;
 raise notice 'fim: %', now();
end;
$$;