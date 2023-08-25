-- Descrição
-- Análise espacial de interseção da camada de conectividade com a camada de estrutura florestal
-- Executado em múltiplas queries em paralelo.
do $$
begin
-- drop table	processado.f_detalhe_conectividade_estrutura;
 raise notice 'inicio: %', now();
 for counter in 4001..((SELECT count(*) FROM processado.d_conectividade_funcional_alfa  dcfa)/10)  loop		
 
	insert into processado.f_detalhe_conectividade_estrutura
	SELECT 
		efa.id_estrutura_florestal,		
		q1.id_conectividade_funcional 
--	into processado.f_detalhe_conectividade_estrutura
	FROM 
	(select dcfa.id_conectividade_funcional, dcfg.geom 
	from
		processado.d_conectividade_funcional_alfa  dcfa   
		join processado.d_conectividade_funcional_geo dcfg on dcfg.id_conectividade_funcional = dcfa.id_conectividade_funcional  
		order by dcfa.id_conectividade_funcional 
		limit 10 offset counter * 10) q1
	join processado.d_estrutura_florestal_geo tcef on st_intersects(q1.geom,tcef.geom)
	join processado.d_estrutura_florestal_alfa efa on efa.id_estrutura_florestal =  tcef.id_estrutura_florestal;
     
     raise notice 'counter: %', counter;

   end loop;
   raise notice 'fim: %', now();
end;
$$