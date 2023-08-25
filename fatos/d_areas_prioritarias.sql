-- Descrição:
-- Cria a tabela que indica quais são os poligonos de conectividade que são considerados áreas prioritárias

--Fazer a classificação das áreas prioritárias por tier: 

---Adicionar na tabela d_areas_prioritarias a coluna de classificação da area prioritária: 
--Apresenta somente os registros onde (area_corredor_ha + area_nuclear_ha) >= 11,18

--Se (area_corredor_ha + area_nuclear_ha) entre 11,18 e 26,89, ‘Priorização alta’; 

--Se (area_corredor_ha + area_nuclear_ha) > 26,89, ‘Priorização muito alta’; 

--Os valores 11,18 e 26,89 são constantes. 

--drop TABLE processado.d_areas_prioritarias;
truncate TABLE processado.d_areas_prioritarias;

insert into processado.d_areas_prioritarias
select 
	id_conectividade_funcional,
	area_ramo,
	qtd_ramo,
	area_borda,
	qtd_borda,
	area_ilha,
	qtd_ilha,
	area_nuclear,
	qtd_nuclear,
	area_corredor,
	qtd_corredor,
	area_alca,
	qtd_alca,
    (fice.area_nuclear + fice.area_corredor) /10000 as     total_area_prioritaria	,
	case 			
	when (fice.area_nuclear + fice.area_corredor) /10000 >= 11.18 and  (fice.area_nuclear + fice.area_corredor)/10000  <= 26.89 then 'Alta'
	when (fice.area_nuclear + fice.area_corredor) /10000 > 26.89 then 'Muito Alta'
	end as priorizacao
	
--into processado.d_areas_prioritarias
from
	processado.f_intersecao_conectividade_estrutura fice
where
	(fice.area_nuclear + fice.area_corredor) >= 11.18;

