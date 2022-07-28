-- Quais os 1000 melhores clientes que podemos oferecer emprestimo para a ação da proxima semana? 

/* CRIANDO TEMPORARIA*/
CREATE TEMPORARY TABLE  ANALISE AS 
SELECT P.* 
,H.motivo_emp
,H.valor_emp
,H.tx_emp
,H.emp_ativo

/* VERIFICANDO EXISTENCIA DA TABELA*/
SELECT *
FROM ANALISE
from pessoas P 
LEFT join historico_emp H 
ON P.ID = H.ID

/*VALIDAÇÃO DE DADOS*/

SELECT
MIN (idade) MENOR_IDADE
, MIN (anos_trabalho_atual) MENOR_TRAB_AT
, MAX (idade) MAIOR_IDADE
, MAX (anos_trabalho_atual) MAIOR_TRAB_AT
FROM ANALISE

/* MENOR IDADE E MENOR_TRAB_AT OK
MAIOR IDADE E MAIOR_TRAB_AT NÃO CONFIAR*/

-- HISTORICO DE EMPRESTIMOS 
SELECT COUNT(*)
FROM ANALISE 
WHERE ANALISE.motivo_emp IS NULL 
AND ANALISE.valor_emp IS NULL
AND ANALISE.tx_emp IS NULL
AND ANALISE.emp_ativo IS NULL 

-- 238 SEM HISTORICO DE EMPRESTIMO 
/*QUANTOS CLIENTES SEM DADO DE CONTATO?*/
SELECT COUNT (*) 
FROM ANALISE 
WHERE dados_contato = 0
-- 25805 CLIENTES SEM DADOS DE CONTATO demo
/*IDEAL TRABALHO ATÉ 60 ANOS (NÃO TRABALHA COM APOSENTADOS*/
SELECT COUNT (*)
FROM ANALISE 
WHERE dados_contato = 1 
AND idade BETWEEN 18 AND 60
-- 5520 CLIENTES COM DADOS, NO RANGE DE 18 A 60 ANOS, SERIABOM UMA CAMPANHA DE ATUALIZAÇÃO DE DADOS
-- COM INFO DE RENDA E ANO E EMPRESTIMO, SE O EMPRESTIMO IMPACTAR A 20% DA RENDA, TEM VIABILIDADE FINANCEIRA PARA O EMPRESTIMO, SE ELE TIVER 40% E TIVER EMPRESTIMO COM A GENTE, ELE É VIAVEL PORÉM É UM RISCO MAIOR 
-- sE FOR MENOR QUE 40% E SEM EMPRESTIMO ATIVO, CLIENTE VIAVEL, SE DER 20% COM EMPRESTIMO ATIVO 
SELECT COUNT (*)
FROM ANALISE 
WHERE 
(
  (valor_emp/renda_ano) <=0.4
  AND emp_ativo = 0)
-- 24018 clientes possiveis
OR (
  (valor_emp/renda_ano)<=0.2
  AND emp_ativo = 1 OR emp_ativo IS NULL ) -- CLIENTES COM EMPRESTIMO ATIVO 
  -- 310044 CLIENTES 
  
/*LIMPANDO E PADRONIZANDO*/
UPDATE ANALISE 
SET idade = (SELECT AVG(idade) 
         FROM ANALISE
         WHERE IDADE BETWEEN 18 AND 60
         )
WHERE idade IS NULL 
-- ADICIONANDO MEDIA NOS VALORES NULOS 
UPDATE ANALISE 
SET anos_trabalho_atual = (SELECT AVG(anos_trabalho_atual) 
         FROM ANALISE
         WHERE anos_trabalho_atual >= 30
         )
WHERE anos_trabalho_atual IS NULL 

-- deletando dados que nãp confiamos 
DELETE from ANALISE 
WHERE anos_trabalho_atual > 40
OR idade > 99

-- analisando o cliente ideal

SELECT id, COUNT(*)
FROM (
select *
, case WHEN dados_contato = 1 AND anos_hist_credito >= 2 
THEN 1 ELSE 0 END CONTATO_HIST_CREDITO
, CASE WHEN ((valor_emp/renda_ano) <=0.4 AND emp_ativo = 0)
         OR (  (valor_emp/renda_ano)<=0.2  AND (emp_ativo = 1 OR emp_ativo IS NULL ) )
     THEN 1 ELSE 0 END IMPACTO_FIN_OK
, CASE WHEN idade BETWEEN 18 AND 60 AND anos_trabalho_atual >= 3
   THEN 1 ELSE 0 END IDADE_TEMPO_SERVIÇO
from ANALISE
)
WHERE CONTATO_HIST_CREDITO =1 
AND IMPACTO_FIN_OK = 1
AND IDADE_TEMPO_SERVIÇO = 1
GROUP BY ID 
ORDER BY 2 DESC
-- CO
-- 3367 CLIENTES APTOS PARA A CAMAPNHA 

-- REMOVENDO DUPLICADOS,, ADD ORDER E GROUP BY 
SELECT id, COUNT(*)
FROM (
select *
, case WHEN dados_contato = 1 AND anos_hist_credito >= 2 
THEN 1 ELSE 0 END CONTATO_HIST_CREDITO
, CASE WHEN ((valor_emp/renda_ano) <=0.4 AND emp_ativo = 0)
         OR (  (valor_emp/renda_ano)<=0.2  AND (emp_ativo = 1 OR emp_ativo IS NULL ) )
     THEN 1 ELSE 0 END IMPACTO_FIN_OK
, CASE WHEN idade BETWEEN 18 AND 60 AND anos_trabalho_atual >= 3
   THEN 1 ELSE 0 END IDADE_TEMPO_SERVIÇO
from ANALISE
)
--WHERE CONTATO_HIST_CREDITO =1 
--AND IMPACTO_FIN_OK = 1
--AND IDADE_TEMPO_SERVIÇO = 1
GROUP BY ID 
ORDER BY 2 DESC

-- CRIANDO TABELA FINAL  
CREATE TABLE ANALISE_FINAL AS 
  SELECT *
FROM 
( select *
, case WHEN dados_contato = 1 AND anos_hist_credito >= 2 
     THEN 1 ELSE 0 END CONTATO_HIST_CREDITO
, CASE WHEN ((valor_emp/renda_ano) <=0.4 AND emp_ativo = 0)
         OR (  (valor_emp/renda_ano)<=0.2  AND (emp_ativo = 1 OR emp_ativo IS NULL ) )
     THEN 1 ELSE 0 END IMPACTO_FIN_OK
, CASE WHEN idade BETWEEN 18 AND 60 AND anos_trabalho_atual >= 3
   THEN 1 ELSE 0 END IDADE_TEMPO_SERVIÇO
from ANALISE
)

