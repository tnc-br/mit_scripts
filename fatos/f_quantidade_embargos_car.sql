-- f_quantidade_embargos_car: tabela que aramazena a quantidade de embargos 
 -- que um determinado CAR sobrepõe
drop table if exists processado.f_quantidade_embargos_car;

select fdie.id_imovel, count(*) as cont_embargos
into processado.f_quantidade_embargos_car
from processado.f_detalhe_imovel_embargos fdie
	join processado.d_embargos_alfa dea on dea.id_embargos = fdie.id_embargos
group by fdie.id_imovel;


