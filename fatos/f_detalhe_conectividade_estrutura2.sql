--Descrição
--Calcula as áreas de cada interseção entre conectividade e estrutura.
--Solução para não precisar fazer a união entre os polígonos.
--Utiliza o iterador para acompanhar o andamento da consulta.

truncate table processado.f_detalhe_conectividade_estrutura2;

do $$
begin
 raise notice 'inicio: %', now();
 for counter in 0..((select count(*) from processado.f_detalhe_conectividade_estrutura me) /1000) +1 loop		

	insert into processado.f_detalhe_conectividade_estrutura2
	 SELECT  fdce.*, st_area( st_intersection(dcfg.geom, defg.geom))

FROM 
(select * from 
	processado.f_detalhe_conectividade_estrutura fd 
	limit 1000 offset counter * 1000
) fdce 
join processado.d_conectividade_funcional_geo dcfg on fdce.id_conectividade_funcional = dcfg.id_conectividade_funcional 
join processado.d_estrutura_florestal_geo defg on defg.id_estrutura_florestal = fdce.id_estrutura_florestal  ;


	raise notice 'counter: %', counter;

 end loop;
 raise notice 'fim: %', now();
end;
$$;





