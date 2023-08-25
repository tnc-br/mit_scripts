truncate table processado.f_detalhe_ts_estrutura;

do $$
begin
  raise notice 'inicio: %', now();
  for counter in 0..(select count(*) from processado.d_programa_territorios_sustentaveis_alfa dmma) loop		
 
	insert into processado.f_detalhe_ts_estrutura
	SELECT 
		q2.id_estrutura_florestal,		
		q1.id_ps 
--	into processado.f_detalhe_ts_estrutura
	FROM 
	(select dptsa.id_ps, dptsg.geom 
	from
		processado.d_programa_territorios_sustentaveis_alfa dptsa  
		join processado.d_programa_territorios_sustentaveis_geo dptsg on dptsa.id_ps = dptsg.id_ps 
		order by dptsa.id_ps 
		limit 1 offset counter ) q1
	join (select tcef.*  from  processado.d_estrutura_florestal_geo tcef  
	join processado.d_estrutura_florestal_alfa efa on efa.id_estrutura_florestal =  tcef.id_estrutura_florestal 
	                                              and efa.gridcode in (5,6)) q2
	on                                            
    st_intersects(q1.geom,q2.geom) ;
     
     raise notice 'counter: %', counter;

   end loop;
   raise notice 'fim: %', now();
end;
$$;








