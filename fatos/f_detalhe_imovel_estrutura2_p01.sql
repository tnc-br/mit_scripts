truncate processado.f_detalhe_imovel_estrutura2;

do $$
begin
 raise notice 'inicio: %', now();
 for counter in 0..500 loop -- ((select count(*) from processado.f_detalhe_ts_estrutura me) /100) +1 loop		

	insert into processado.f_detalhe_imovel_estrutura2

	select q1.*, st_area( st_intersection(dmmg.geom, defg.geom)) as area
--	into processado.f_detalhe_imovel_estrutura2
	from
	(select dptsa.id_imovel, dptsa.id_estrutura_florestal
	from
		processado.f_detalhe_imovel_estrutura dptsa  		 
		order by dptsa.id_imovel 
		limit 1000 offset  counter * 1000 ) q1
	join processado.d_imoveis_geo dmmg on dmmg.id_imovel = q1.id_imovel
	join processado.d_estrutura_florestal_geo defg on defg.id_estrutura_florestal = q1.id_estrutura_florestal;

	raise notice 'counter: %', counter;

 end loop;
 raise notice 'fim: %', now();
end;
$$;