-- Descrição:
-- Análise espacial de interseção da camada de conectividade com a camada de estrutura florestal
--Utiliza o iterador para acompanhar o andamento da consulta. 
truncate table processado.f_detalhe_municipio_estrutura;

do $$
begin


raise notice 'inicio: %', now();
  for counter in 0..(select count(*) from processado.d_malha_municipal_alfa dmma where dmma.tx_sigla_municipio ='PA') loop		
 
	insert into processado.f_detalhe_municipio_estrutura
	SELECT 
		q2.id_estrutura_florestal,		
		q1.id_municipio as id_municipio
--	into processado.f_detalhe__municipio_estrutura
	FROM 
	(select bma.id_municipio, bma.tx_nome_municipio, bma.tx_sigla_municipio, bmm.geom 
	from
		processado.d_malha_municipal_alfa bma 
		join processado.d_malha_municipal_geo bmm on bma.id_municipio = bmm.id_municipio and bma.tx_sigla_municipio = 'PA'
		order by bma.id_municipio
		limit 1 offset counter) q1
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
