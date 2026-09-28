
USE dw_pata_amiga;


INSERT INTO fato_pedido (
    numero_pedido,
    sk_tempo_pedido,
    sk_tempo_entrega,
    sk_loja,
    sk_categoria,
    houve_desconto,
    canal_pedido,
    dt_pedido,
    qt_itens,
    vl_liquido,
    dias_integracao_separacao,
    dias_separacao_nota,
    dias_nota_despacho,
    dias_despacho_entrega,
    dias_total_ate_entrega
)

SELECT p.`NumeroPedido` AS numero_pedido,
       CASE
            WHEN TRIM(p.`DtHoraPedido`) IN ('', '-') THEN -1
            WHEN STR_TO_DATE(TRIM(p.`DtHoraPedido`),'%m/%d/%Y %h:%i %p') IS NULL THEN -1
	   ELSE CAST( DATE_FORMAT(STR_TO_DATE(TRIM(p.`DtHoraPedido`),'%m/%d/%Y %h:%i %p'),'%Y%m%d') AS SIGNED) END AS sk_tempo_pedido,
    CASE
         WHEN TRIM(p.`DtEntregaCliente`) IN ('', '-') THEN -1
         WHEN DATE(p.`DtEntregaCliente`) IS NULL THEN -1
	ELSE CAST(DATE_FORMAT(DATE(p.`DtEntregaCliente`),'%Y%m%d') AS SIGNED) END AS sk_tempo_entrega,
    COALESCE(dl.sk_loja,-1) AS sk_loja,
    COALESCE(dc.sk_categoria,-1) AS sk_categoria,
    CASE
         WHEN UPPER(TRIM(p.`HouveDesconto`)) IN ('S', 'SIM', '1', 'X', 'TRUE', 'V') THEN 'Sim'
         WHEN UPPER(TRIM(p.`HouveDesconto`)) IN ('N', 'NAO', '0', 'FALSE', 'F') THEN 'Nao'
    ELSE 'Nao Informado' END AS houve_desconto,
    CASE
         WHEN UPPER(TRIM(p.`CanalPedido`)) LIKE '%WHATS%' THEN 'WhatsApp'
         WHEN UPPER(TRIM(p.`CanalPedido`)) LIKE '%APP%' THEN 'App'
         WHEN UPPER(TRIM(p.`CanalPedido`)) LIKE '%SITE%' THEN 'Site'
         WHEN UPPER(TRIM(p.`CanalPedido`)) LIKE '%LOJA%' THEN 'Loja Fisica'
         WHEN UPPER(TRIM(p.`CanalPedido`)) LIKE '%TEL%' THEN 'Telefone'
         WHEN p.`CanalPedido` IS NULL OR TRIM(p.`CanalPedido`) = '' THEN 'Nao Informado'
   ELSE 'Nao Informado' END AS canal_pedido,
    CASE
         WHEN TRIM(p.`DtHoraPedido`) IN ('', '-') THEN NULL
    ELSE STR_TO_DATE(TRIM(p.`DtHoraPedido`),'%m/%d/%Y %h:%i %p') END AS dt_pedido,
    CASE
         WHEN TRIM(p.`QTD.Itens`) IN ('', '-') THEN NULL
    ELSE CAST(REPLACE(TRIM(p.`QTD.Itens`), '.','') AS SIGNED)END AS qt_itens,
    CASE
         WHEN TRIM(REPLACE( p.`ValorLiquidoPedido(R$)`,'R$', '')) IN ('', '-') THEN NULL
         WHEN p.`ValorLiquidoPedido(R$)` LIKE '%,%' 
         THEN CAST(REPLACE( REPLACE( REPLACE(REPLACE(p.`ValorLiquidoPedido(R$)`,'R$',''),' ',''),'.', ''),',','.') AS DECIMAL(15,2))
    ELSE CAST(REPLACE(REPLACE(p.`ValorLiquidoPedido(R$)`,'R$',''),' ','') AS DECIMAL(15,2)) END AS vl_liquido,
    CASE
         WHEN TRIM(p.`DtHoraIntegracaoERP`) IN ('', '-') OR TRIM(p.`Dt Separacao Estoque`) IN ('', '-') THEN NULL
         WHEN STR_TO_DATE(TRIM(p.`DtHoraIntegracaoERP`),'%m/%d/%Y %h:%i %p') IS NULL THEN NULL
         WHEN DATE(p.`Dt Separacao Estoque`) IS NULL THEN NULL
    ELSE DATEDIFF(DATE(p.`Dt Separacao Estoque`),DATE(STR_TO_DATE(TRIM(p.`DtHoraIntegracaoERP`),'%m/%d/%Y %h:%i %p'))) END AS dias_integracao_separacao,
    CASE
        WHEN TRIM(p.`Dt Separacao Estoque`) IN ('', '-') OR TRIM(p.`DtNotaFiscal`) IN ('', '-') THEN NULL
        WHEN DATE(p.`Dt Separacao Estoque`) IS NULL OR DATE(p.`DtNotaFiscal`) IS NULL THEN NULL
    ELSE DATEDIFF(DATE(p.`DtNotaFiscal`),DATE(p.`Dt Separacao Estoque`) ) END AS dias_separacao_nota,
    CASE
         WHEN TRIM(p.`DtNotaFiscal`) IN ('', '-') OR TRIM(p.`Dt_Despacho_Transportadora`) IN ('', '-') THEN NULL
         WHEN DATE(p.`DtNotaFiscal`) IS NULL OR DATE(p.`Dt_Despacho_Transportadora`) IS NULL THEN NULL
	ELSE DATEDIFF(DATE(p.`Dt_Despacho_Transportadora`),DATE(p.`DtNotaFiscal`)) END AS dias_nota_despacho,
    CASE
         WHEN TRIM(p.`Dt_Despacho_Transportadora`) IN ('', '-') OR TRIM(p.`DtEntregaCliente`) IN ('', '-') THEN NULL
         WHEN DATE(p.`Dt_Despacho_Transportadora`) IS NULL OR DATE(p.`DtEntregaCliente`) IS NULL THEN NULL
    ELSE DATEDIFF(DATE(p.`DtEntregaCliente`),DATE(p.`Dt_Despacho_Transportadora`)) END AS dias_despacho_entrega,
    CASE
         WHEN TRIM(p.`DtHoraIntegracaoERP`) IN ('', '-') OR TRIM(p.`DtEntregaCliente`) IN ('', '-') THEN NULL
         WHEN STR_TO_DATE(TRIM(p.`DtHoraIntegracaoERP`),'%m/%d/%Y %h:%i %p') IS NULL THEN NULL
         WHEN DATE(p.`DtEntregaCliente`) IS NULL THEN NULL
    ELSE DATEDIFF(DATE(p.`DtEntregaCliente`),DATE(STR_TO_DATE(TRIM(p.`DtHoraIntegracaoERP`),'%m/%d/%Y %h:%i %p'))) END AS dias_total_ate_entrega
FROM stg_pedido p
LEFT JOIN dim_loja dl
  ON dl.nome_loja = CASE WHEN REPLACE( REPLACE(TRIM(p.`Loja-Nome`),'/SC',''),'  ',' ') = 'PATA AMIGA BLUMENAL CENTRO' THEN 'PATA AMIGA BLUMENAU CENTRO'
                         WHEN REPLACE(REPLACE(TRIM(p.`Loja-Nome`),'/SC',''),'  ',' ') = 'PATA AMIGA FLORIPA NORTE' THEN 'PATA AMIGA FLORIANOPOLIS NORTE'
                         WHEN REPLACE(REPLACE(TRIM(p.`Loja-Nome`),'/SC','' ),'  ',' ') = 'PATA AMIGA JGUA DO SUL' THEN 'PATA AMIGA JARAGUA DO SUL'
                    ELSE REPLACE(REPLACE(TRIM(p.`Loja-Nome`),'/SC',''),'  ', ' ') END
LEFT JOIN dim_categoria dc
  ON dc.categoria_origem = p.`CategoriaProduto`;