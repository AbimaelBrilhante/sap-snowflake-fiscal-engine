WITH parceiros_cleansed AS (
    SELECT * FROM {{ ref('stg_sap__parceiros_dedup') }} WHERE row_num = 1
),

impostos_pivoted AS (
    SELECT * FROM {{ ref('stg_sap__impostos_nf') }}
),

itens_nf AS (
    SELECT * FROM RAW.HANA_S4P.J_1BNFLIN
),

cabecalho_nf AS (
    SELECT * FROM RAW.HANA_S4P.J_1BNFDOC
),

active_status AS (
    SELECT * FROM RAW.HANA_S4P.J_1BNFE_ACTIVE
)

SELECT
    -- Business Keys & Operational Identifiers
    lin.DOCNUM AS docnum,
    lin.ITMNUM AS item_documento,
    doc.BELNR AS documento_contabil,
    doc.GJAHR AS exercicio_fiscal,
    doc.BUKRS AS empresa_codigo,
    lin.WERKS AS centro_custo,
    
    -- Cleaned Partner Fields via Staging reference
    parceiros_cleansed.is_contribuinte_icms,
    COALESCE(TRIM(parceiros_cleansed.codigo_parceiro_saidas), TRIM(doc.PARID), '') AS codigo_parceiro_saidas,
    COALESCE(TRIM(cpd.STCD1), TRIM(nad.STCD1), TRIM(doc.CGC), '') AS cnpj_parceiro,
    COALESCE(TRIM(cpd.REGIO), TRIM(nad.REGIO), TRIM(doc.REGIO), '') AS uf_saida,
    COALESCE(TRIM(cpd.NAME1), TRIM(nad.NAME1), TRIM(doc.NAME1), '') AS descricao_parceiro,

    -- Material Attributes & Supply Chain Logistics
    lin.MATNR AS material_codigo,
    lin.MAKTX AS material_descricao,
    lin.MATKL AS grupo_mercadorias,
    lin.CHARG AS lote_codigo,
    lin.CFOP AS cfop_codigo,
    lin.NBM AS ncm_codigo,
    lin.MENGE AS quantidade_item,
    lin.MEINS AS unidade_medida_basica,
    lin.NFNETT AS valor_liquido_item,
    
    -- Invoicing Status & Validations
    doc.NFTYPE AS categoria_nf,
    doc.DOCTYP AS tipo_documento,
    doc.DOCDAT AS data_documento,
    doc.PSTDAT AS data_lancamento,
    doc.NFENUM AS numero_nfe,
    active.DOCSTA AS status_documento_xml,
    active.CANCEL AS status_estornado,
    active.REGIO || active.NFYEAR || active.NFMONTH || active.STCD1 || active.MODEL || active.SERIE || active.NFNUM9 || active.DOCNUM9 || active.CDV AS chave_acesso_nfe,

    -- Tax Metrics Pipelines (Sourced directly from Staging Upstream via dbt ref)
    COALESCE(imp.base_icms, 0) AS valor_base_icms,
    COALESCE(imp.icms_contabil, 0) AS valor_icms_contabil,
    COALESCE(imp.valor_icms_st, 0) AS valor_icms_st,
    COALESCE(imp.valor_ipi, 0) AS valor_ipi,
    COALESCE(imp.valor_coﬁns, 0) AS valor_coﬁns,
    COALESCE(imp.valor_pis, 0) AS valor_pis,
    COALESCE(imp.valor_difal, 0) AS valor_difal

FROM itens_nf lin
LEFT JOIN cabecalho_nf doc ON lin.DOCNUM = doc.DOCNUM
LEFT JOIN RAW.HANA_S4P.J_1BNFNAD nad ON lin.DOCNUM = nad.DOCNUM AND doc.PARVW = nad.PARVW
LEFT JOIN RAW.HANA_S4P.J_1BNFCPD cpd ON lin.DOCNUM = cpd.DOCNUM AND cpd.PARVW = 'WE'
LEFT JOIN active_status active ON lin.DOCNUM = active.DOCNUM
LEFT JOIN parceiros_cleansed ON TRIM(doc.CGC) = TRIM(parceiros_cleansed.cnpj_base) AND TRIM(doc.STAINS) = TRIM(parceiros_cleansed.inscricao_estadual)
LEFT JOIN impostos_pivoted imp ON lin.DOCNUM = imp.docnum AND lin.ITMNUM = imp.itemnum

WHERE 
    doc.PSTDAT >= DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1 MONTH')
    AND doc.PSTDAT <= CURRENT_DATE
    AND doc.NFTYPE NOT IN ('IA', 'YK', 'ZZ', 'ZN', 'ZU', 'ZK', 'ZF', 'IB', 'A1')
