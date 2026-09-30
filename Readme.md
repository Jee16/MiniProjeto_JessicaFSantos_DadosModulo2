
## Sobre o projeto - Pata Amiga — Data Warehouse

Este projeto foi desenvolvido como parte do curso **Análise de Dados com Python Turma V2** e tem como objetivo construir um **Data Warehouse para a rede de petshops Pata Amiga**, utilizando dados de pedidos realizados entre setembro de 2023 e março de 2024.

O projeto transforma os dados de origem em uma estrutura dimensional, permitindo análises relacionadas a:

- Pedidos;
- Faturamento;
- Categorias de produtos;
- Canais de venda;
- Lojas;
- Praças de atendimento;
- Franquias;
- Etapas do processo de entrega.

O modelo foi desenvolvido seguindo o conceito de **modelo estrela (Star Schema)**, com uma tabela fato central e tabelas de dimensão relacionadas.

---

## Objetivos

O projeto busca responder perguntas de negócio relacionadas ao desempenho operacional e comercial da rede.

As cinco perguntas analisadas foram:

1. **Qual é o principal gargalo do processo de entrega e como ele varia por porte de loja?**
2. **Qual categoria de produto concentra o faturamento da rede?**
3. **O desconto funciona da mesma forma em todos os canais de venda?**
4. **Qual praça de atendimento concentra o maior faturamento?**
5. **Onde existem indícios de oportunidade para expansão?**

Também foi realizada uma análise da qualidade dos dados, identificando informações ausentes que podem limitar algumas análises.

---

#  Arquitetura do projeto

O projeto utiliza uma arquitetura dimensional baseada no modelo estrela.

### Tabela fato

**fato_pedido**

Armazena os eventos de pedidos e as principais métricas utilizadas nas análises:

- Número do pedido;
- Loja;
- Categoria;
- Data do pedido;
- Data da entrega;
- Quantidade de itens;
- Valor líquido;
- Canal do pedido;
- Indicação de desconto;
- Tempos das etapas de entrega.

### Dimensões

**dim_tempo**

Permite análises relacionadas às datas dos pedidos e entregas.

**dim_loja**

Contém informações sobre as lojas:

- Código;
- Nome;
- Cidade;
- UF;
- Mesorregião;
- População;
- Área de venda;
- Porte;
- Faixa de franquia;
- Formato da loja.

**dim_categoria**

Padroniza as categorias de produtos utilizadas nos dados de origem.

**dim_praca**

Representa as praças de atendimento.

### Tabela ponte

**bridge_loja_praca**

Relaciona lojas e praças.

Quando uma loja está associada a mais de uma praça, é utilizado um **fator de rateio**, evitando que o faturamento seja contabilizado integralmente em cada praça.

---

# Modelo estrela

O modelo dimensional desenvolvido possui a seguinte estrutura:

![Modelo estrela](image/dimensão.png)

A tabela `fato_pedido` concentra os registros de pedidos e se relaciona com as dimensões utilizadas nas análises.

A tabela `bridge_loja_praca` permite tratar os casos em que uma loja está relacionada a mais de uma praça, utilizando o `fator_rateio`.

---

# Scripts SQL

Os scripts devem ser executados na seguinte ordem:

### 01 — Staging

Criação e carga das tabelas de estágio utilizadas como origem dos dados.

Principais tabelas:

- `stg_pedido`
- `stg_loja`
- `stg_loja_praca`

---

### 02 — Dimensões

Criação e carga das dimensões:

- `dim_tempo`
- `dim_loja`

---

### 03 — Categorias e praças

Criação e tratamento das estruturas relacionadas às categorias e praças:

- `dim_categoria`
- `dim_praca`
- `bridge_loja_praca`


### 04 — Fato

Criação e carga da tabela:

```text
fato_pedido
```

Nesta etapa são realizadas as principais transformações dos dados:

- Conversão de datas;
- Tratamento de valores monetários;
- Tratamento de valores ausentes;
- Padronização dos canais;
- Padronização da informação de desconto;
- Relacionamento com as dimensões;
- Cálculo dos tempos das etapas de entrega.

---

### 05 — Análises de negócio

Contém as consultas utilizadas para responder às cinco perguntas de negócio propostas no projeto.

---

# Tratamento dos dados

## Tratamento das datas

As datas de pedido e integração chegam no formato:

```text
11/16/2023 02:30 PM
```

Foi utilizada a função:

```sql
STR_TO_DATE(
    coluna,
    '%m/%d/%Y %h:%i %p'
)
```

As datas das etapas de entrega chegam no formato:

```text
2023-11-16
```

e são tratadas utilizando `DATE()`.

---

## Tratamento dos valores monetários

Os valores poderiam aparecer em diferentes formatos, como:

```text
R$ 1.850,00
1850.00
1.200
-
```

Os valores foram padronizados para o formato numérico utilizado no Data Warehouse.

Valores vazios ou representados por `-` foram transformados em:

```text
NULL
```

e não em zero.

Essa decisão evita interpretar ausência de informação como um valor financeiro igual a zero.

---

## Padronização das categorias

As categorias apresentavam diferentes abreviações e grafias.

Foi realizada uma padronização para agrupá-las nas seguintes categorias:

| Categoria | Grupo |
|---|---|
| Medicamento | Saude e Higiene |
| Racao | Alimentacao |
| Petisco | Alimentacao |
| Higiene | Saude e Higiene |
| Brinquedo | Bem-estar |
| Acessorio | Bem-estar |
| Servico | Bem-estar |
| Nao Informado | Nao Informado |

---

## Padronização das lojas

Foram identificadas inconsistências na nomenclatura das lojas.

Alguns exemplos de correção:

```text
PATA AMIGA BLUMENAL CENTRO
→ PATA AMIGA BLUMENAU CENTRO

PATA AMIGA FLORIPA NORTE
→ PATA AMIGA FLORIANOPOLIS NORTE

PATA AMIGA JGUA DO SUL
→ PATA AMIGA JARAGUA DO SUL
```

Também foi removido o sufixo `/SC` dos nomes das lojas.

---

## Padronização dos canais de venda

O campo utilizado para identificar o canal foi `CanalPedido`.

Os valores foram padronizados para:

- App
- Site
- Loja Fisica
- WhatsApp
- Telefone
- Nao Informado

A ordem das regras considera **WhatsApp antes de App**, pois `WhatsApp` contém a palavra `App`.

A distribuição final foi:

| Canal | Pedidos |
|---|---:|
| App | 1.273 |
| Site | 1.032 |
| Loja Fisica | 824 |
| WhatsApp | 414 |
| Telefone | 264 |
| Nao Informado | 237 |
| **Total** | **4.044** |

---

# Resultados das análises

## 1. Qual é o principal gargalo do processo de entrega?

Foi calculado o tempo médio de cada etapa do processo de entrega por porte da loja. Onde A etapa entre a **emissão da nota fiscal e o despacho para a transportadora** apresenta o maior tempo médio entre as principais etapas do processo.
O maior valor ocorre nas lojas pequenas, com **8,54 dias**, contribuindo para o maior tempo médio total de entrega, de **15,16 dias**.

---

## 2. Qual categoria concentra o faturamento?

A categoria **Ração** concentra a maior parcela do faturamento da rede, representando **60,01%**, com faturamento de **R$ 1.076.202,55**. Em seguida aparece a categoria **Medicamento**, com 17,06%. Os resultados mostram uma concentração significativa do faturamento na categoria Ração.

---

## 3. O desconto funciona da mesma forma em todos os canais?

Foi analisado o ticket médio dos pedidos com e sem desconto em cada canal. Nos pedidos **sem desconto**, os tickets médios ficaram abaixo de R$ 200 na maioria dos canais. Os dados apresentam diferenças de ticket médio entre pedidos com e sem desconto e também entre os canais. Entre os pedidos com desconto, os tickets médios variam de **R$ 488,04 no App** a **R$ 514,33 no WhatsApp**, considerando os canais identificados. Essa análise demonstra diferenças observadas nos dados, mas não permite afirmar que o desconto seja a causa dessas diferenças. Também existem registros classificados como `Nao Informado`, o que limita uma comparação completa.

---

## 4. Qual praça de atendimento concentra o maior faturamento?

Para essa análise foi utilizado o relacionamento entre loja e praça através da tabela `bridge_loja_praca`. O **Vale do Itajaí** apresenta o maior faturamento alocado, com aproximadamente **R$ 633.746,09**, distribuído em 1.485 pedidos.
O cálculo considera o fator de rateio da relação entre lojas e praças, evitando que pedidos de uma loja associada a mais de uma praça sejam contabilizados integralmente em cada uma delas.

---
## P5(a) — Onde existem indícios de oportunidade para expansão?

Rio dos Cedros, Presidente Getúlio e Ibirama apresentam as maiores taxas de itens por mil habitantes.
Esses resultados podem ser utilizados como indicadores para investigar possíveis oportunidades de expansão. Entretanto, o indicador isoladamente não é suficiente para definir a abertura de uma nova loja. Também seria necessário considerar fatores como concorrência, custos de operação, renda da população, valor de aluguel, logística, distância das lojas existentes e potencial de mercado.

---

## P5(b) — Como o faturamento se distribui por faixa de franquia?

A faixa **Ouro** apresenta o maior faturamento observado, com **R$ 1.011.264,38**, seguida pelas faixas Diamante, com R$ 382.209,74, e Prata, com R$ 314.812,03. Essa análise utiliza a classificação de franquia presente no cadastro atual das lojas. Como não existe histórico das alterações dessa classificação, não é possível afirmar que a faixa atual era a mesma no momento de cada pedido.

---

## P5(c) — Quais informações ficaram de fora das análises?

 Dos **4.044 pedidos analisados**, 3 não possuem loja identificada, 1.953 não possuem entrega concluída, 257 não possuem quantidade de itens informada e 121 não possuem valor líquido. Essas ausências limitam principalmente as análises relacionadas ao tempo de entrega, quantidade de itens e faturamento.

---

# Qualidade dos dados

Durante o processo foram identificados registros com informações ausentes.

| Indicador | Quantidade |
|---|---:|
| Total de pedidos | **4.044** |
| Pedidos sem loja identificada | 3 |
| Pedidos sem entrega concluída | **1.953** |
| Pedidos sem quantidade de itens | 257 |
| Pedidos sem valor líquido | 121 |

Os valores ausentes foram mantidos como `NULL` quando representavam ausência de informação.

---

# Período analisado

Os pedidos analisados estão no período:

```text
01/09/2023 a 31/03/2024
```

Quantidade total de pedidos:

```text
4.044
```

---

# Tecnologias utilizadas

- **MySQL 8.0**
- SQL
- MySQL Workbench
- Modelo dimensional / Star Schema
- Git
- GitHub

---

# Como executar o projeto

## 1. Executar os scripts

Os arquivos devem ser executados na seguinte ordem:

```text
01-staging.sql
02-dimensoes.sql
03-fato.sql
04-negocio.sql
```

A ordem deve ser respeitada devido às dependências entre as tabelas.

## 3. Validar a carga

Após a execução dos scripts, a tabela `fato_pedido` deve possuir:

```text
4.044 pedidos
```

#  Conclusão

O projeto resultou em um **Data Warehouse dimensional** capaz de organizar os dados da rede Pata Amiga e apoiar análises comerciais e operacionais.

Entre os principais resultados encontrados estão:

- A etapa **Nota → Despacho** apresenta os maiores tempos médios do processo de entrega;
- A categoria **Ração representa 60,01% do faturamento**;
- Existem diferenças de ticket médio entre canais e entre pedidos com e sem desconto;
- O **Vale do Itajaí** apresenta o maior faturamento alocado por praça;
- **Rio dos Cedros, Presidente Getúlio e Ibirama** apresentam as maiores taxas de itens por mil habitantes;
- A faixa de franquia **Ouro** apresenta o maior faturamento observado;
- Foram identificados **4.044 pedidos**, sendo 1.953 sem entrega concluída.

O modelo também preserva as limitações existentes nos dados, evitando transformar informações ausentes em valores artificiais e deixando explícitas as situações em que uma análise mais completa dependeria de dados adicionais.

---

#  Autoria

**Aluna:** Jessica Finardi dos Santos  
**Curso:** Análise de Dados com Python Turma V2  
**Projeto:** Data Warehouse — Pata Amiga