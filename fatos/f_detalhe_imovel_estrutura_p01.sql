truncate table processado.f_detalhe_imovel_estrutura;
do $$
begin

-- drop table	processado.f_detalhe_conectividade_estrutura;
 raise notice 'inicio: %', now();
 for counter in 0..7000  loop		
 
	insert into processado.f_detalhe_imovel_estrutura
	SELECT 
		q2.id_estrutura_florestal,		
		q1.id_imovel 
--	into processado.f_detalhe_conectividade_estrutura
	FROM 
	(select dcfa.id_imovel, dcfg.geom 
	from
		processado.d_imoveis_alfa dcfa   
		join processado.d_imoveis_geo  dcfg on dcfg.id_imovel = dcfa.id_imovel
		where dcfa.num_flg_ativo = true and dcfa.tx_status_imovel not in ('CA','RE','SU')
		order by dcfa.id_imovel 
		limit 10 offset counter * 10) q1
	join (select tcef.*  from  processado.d_estrutura_florestal_geo tcef  
	join processado.d_estrutura_florestal_alfa efa on efa.id_estrutura_florestal =  tcef.id_estrutura_florestal 
	                                              and efa.gridcode in (5,6)) q2
	on                                            
    st_intersects(q1.geom,q2.geom) ;
     raise notice 'counter: %', counter;

   end loop;
   raise notice 'fim: %', now();
end;
$$