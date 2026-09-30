

-- =====================================================================================
--  ARQUIVO 5: AS CINCO PERGUNTAS DE NEGOCIO
--  Case: Pata Amiga - rede de petshops de SC | MySQL 8.0
-- =====================================================================================

USE dw_pata_amiga;


-- =====================================================================================
-- P1 - ONDE ESTA O GARGALO DO PROCESSO DE ENTREGA?
-- =====================================================================================

SELECT dl.porte,
       AVG(f.dias_integracao_separacao) AS media_integracao_separacao,
       AVG(f.dias_separacao_nota) AS media_separacao_nota,
       AVG(f.dias_nota_despacho) AS media_nota_despacho,
       AVG(f.dias_despacho_entrega) AS media_despacho_entrega,
       AVG(f.dias_total_ate_entrega) AS media_total_ate_entrega
  FROM fato_pedido f
  JOIN dim_loja dl
    ON dl.sk_loja = f.sk_loja
 GROUP BY dl.porte
 ORDER BY dl.porte;

ANÁLISE: Foi calculado o tempo médio de cada etapa do processo de
entrega por porte da loja. Onde A etapa entre a emissão da nota
fiscal e o despacho para a transportadora apresenta o maior tempo
médio entre as principais etapas do processo. O maior valor 
ocorre nas lojas pequenas, com 8,54 dias, contribuindo para o 
maior tempo médio total de entrega, de 15,16 dias.

-- =====================================================================================
-- P2 - QUAL CATEGORIA CONCENTRA O FATURAMENTO?
-- =====================================================================================

SELECT dc.nome_categoria,
       SUM(f.vl_liquido) AS faturamento,
       ROUND(SUM(f.vl_liquido) /
            (SELECT SUM(vl_liquido)
               FROM fato_pedido
              WHERE vl_liquido IS NOT NULL) * 100,2) AS percentual_faturamento
  FROM fato_pedido f
  JOIN dim_categoria dc 
    ON dc.sk_categoria = f.sk_categoria
 GROUP BY dc.nome_categoria
 ORDER BY faturamento DESC;

ANÁLISE: A categoria Ração concentra a maior parcela do faturamento
da rede, representando 60,01%, com faturamento de R$ 1.076.202,55.
Em seguida aparece a categoria Medicamento, com 17,06%. 
Os resultados mostram uma concentração significativa do faturamento
na categoria Ração.

-- =====================================================================================
-- P3 - O DESCONTO FUNCIONA IGUAL EM TODO CANAL?
-- =====================================================================================

SELECT canal_pedido,
       houve_desconto,
       COUNT(*) AS qtd_pedidos,
       AVG(vl_liquido) AS ticket_medio
  FROM fato_pedido
 WHERE vl_liquido IS NOT NULL
 GROUP BY canal_pedido,houve_desconto
 ORDER BY canal_pedido,houve_desconto;

SELECT canal_pedido,
       COUNT(*) AS qtd_pedidos
  FROM fato_pedido
 GROUP BY canal_pedido
 ORDER BY qtd_pedidos DESC;

ANÁLISE: Foi analisado o ticket médio dos pedidos com e sem 
desconto em cada canal. Nos pedidos sem desconto, os tickets 
médios ficaram abaixo de R$ 200 na maioria dos canais. Os dados 
apresentam diferenças de ticket médio entre pedidos com e sem 
desconto e também entre os canais. Entre os pedidos com desconto, 
os tickets médios variam de R$ 488,04 no App a R$ 514,33 no 
WhatsApp, considerando os canais identificados. Essa análise 
demonstra diferenças observadas nos dados, mas não permite afirmar
que o desconto seja a causa dessas diferenças. Também existem 
registros classificados como Nao Informado, o que limita uma 
comparação completa.

-- =====================================================================================
-- P4 - QUAL PRACA DE ATENDIMENTO CONCENTRA O FATURAMENTO?
-- =====================================================================================

SELECT dp.nome_praca,
       SUM(f.vl_liquido * b.fator_publico) AS faturamento_alocado,
       COUNT(DISTINCT f.sk_pedido) AS qtd_pedidos
  FROM fato_pedido f
  JOIN dim_loja dl
    ON dl.sk_loja = f.sk_loja
  JOIN bridge_loja_praca b
    ON b.cod_loja = dl.cod_loja
  JOIN dim_praca dp
    ON dp.sk_praca = b.sk_praca
 WHERE f.vl_liquido IS NOT NULL
 GROUP BY dp.nome_praca
 ORDER BY faturamento_alocado DESC;

ANÁLISE: Para essa análise foi utilizado o relacionamento entre 
loja e praça através da tabela bridge_loja_praca. O Vale do Itajaí 
apresenta o maior faturamento alocado, com aproximadamente 
R$ 633.746,09, distribuído em 1.485 pedidos. O cálculo considera 
o fator de rateio da relação entre lojas e praças, evitando que 
pedidos de uma loja associada a mais de uma praça sejam contabilizados 
integralmente em cada uma delas.

-- =====================================================================================
-- P5 - ONDE ABRIR A PROXIMA LOJA, E O QUE OS DADOS NAO PERMITEM AFIRMAR?
-- =====================================================================================

-- -------------------------------------------------------------------------------------
-- P5 (a) - Itens por mil habitantes + tempo medio de entrega
-- -------------------------------------------------------------------------------------

SELECT dl.sk_loja,
       dl.cod_loja,
       dl.nome_loja,
       dl.cidade,
       dl.uf,
       dl.populacao_cidade,
       SUM(f.qt_itens) AS total_itens,
       ROUND(SUM(f.qt_itens) / NULLIF(dl.populacao_cidade, 0) * 1000,2) AS itens_por_mil_habitantes,
       ROUND(AVG(f.dias_total_ate_entrega),2) AS media_dias_entrega
  FROM fato_pedido f
  JOIN dim_loja dl
    ON dl.sk_loja = f.sk_loja
 WHERE f.qt_itens IS NOT NULL
 GROUP BY dl.sk_loja,dl.cod_loja,dl.nome_loja,dl.cidade,dl.uf,dl.populacao_cidade
 ORDER BY itens_por_mil_habitantes DESC;

ANÁLISE: Rio dos Cedros, Presidente Getúlio e Ibirama apresentam 
as maiores taxas de itens por mil habitantes. Esses resultados 
podem ser utilizados como indicadores para investigar possíveis 
oportunidades de expansão. Entretanto, o indicador isoladamente 
não é suficiente para definir a abertura de uma nova loja. Também 
seria necessário considerar fatores como concorrência, custos de 
operação, renda da população, valor de aluguel, logística, 
distância das lojas existentes e potencial de mercado.

-- -------------------------------------------------------------------------------------
-- P5 (b) - Faturamento por faixa de franquia
-- -------------------------------------------------------------------------------------

SELECT dl.faixa_franquia,
       SUM(f.vl_liquido) AS faturamento,
       COUNT(*) AS qtd_pedidos
  FROM fato_pedido f
  JOIN dim_loja dl
    ON dl.sk_loja = f.sk_loja
 WHERE f.vl_liquido IS NOT NULL
 GROUP BY dl.faixa_franquia
 ORDER BY faturamento DESC;

ANÁLISE: A faixa Ouro apresenta o maior faturamento observado, 
com R$ 1.011.264,38, seguida pelas faixas Diamante, com R$ 382.209,
74, e Prata, com R$ 314.812,03. Essa análise utiliza a classificação
de franquia presente no cadastro atual das lojas. Como não existe 
histórico das alterações dessa classificação, não é possível 
afirmar que a faixa atual era a mesma no momento de cada pedido.

-- -------------------------------------------------------------------------------------
-- P5 (c) - O que ficou de fora?
-- -------------------------------------------------------------------------------------
SELECT COUNT(*) AS total_pedidos,
       SUM(CASE WHEN sk_loja = -1 THEN 1 ELSE 0 END) AS pedidos_sem_loja,
       SUM(CASE WHEN sk_tempo_entrega = -1 THEN 1 ELSE 0 END) AS entregas_nao_concluidas,
       SUM(CASE WHEN qt_itens IS NULL THEN 1 ELSE 0 END) AS pedidos_sem_itens,
       SUM(CASE WHEN vl_liquido IS NULL THEN 1 ELSE 0 END) AS pedidos_sem_valor
  FROM fato_pedido;

ANÁLISE:Dos 4.044 pedidos analisados, 3 não possuem loja identificada,
1.953 não possuem entrega concluída, 257 não possuem quantidade 
de itens informada e 121 não possuem valor líquido. Essas ausências
limitam principalmente as análises relacionadas ao tempo de entrega, 
quantidade de itens e faturamento.