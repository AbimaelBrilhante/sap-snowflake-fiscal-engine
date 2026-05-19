SELECT
    master_partner."ICMS_Taxpayer" AS is_taxpayer,
    COALESCE(TRIM(master_partner."Partner_ID_Outbound"), TRIM(doc.PARID), '') AS partner_id,
    COALESCE(TRIM(cpd.STCD2), TRIM(nad.CPF), TRIM(doc.CPF), '') AS tax_id_person, -- CPF
    COALESCE(TRIM(cpd.STCD1), TRIM(nad.CGC), TRIM(doc.CGC), '') AS tax_id_company, -- CNPJ
    COALESCE(TRIM(cpd.REGIO), TRIM(nad.REGIO), TRIM(doc.REGIO), '') AS region_state,
    COALESCE(TRIM(cpd.NAME1), TRIM(nad.NAME1), TRIM(doc.NAME1), '') AS partner_description,
    lin.DOCNUM AS invoice_id,
    lin.ITMNUM AS item_number,
    lin.MATNR AS material_id,
    lin.BWTAR AS valuation_type,
    lin.CHARG AS batch_number,
    lin.MATKL AS material_group,
    lin.MAKTX AS material_description,
    lin.ITMREF AS item_reference,
    lin.CFOP AS fiscal_operation_code,
    lin.NBM AS ncm_code, -- Harmonized System Code
    lin.MATORG AS material_origin,
    lin.TAXSIT AS tax_situation_id,
    IFF(
        LEFT(TRIM(lin.REFKEY), 2) IN ('50', '51'),
        LEFT(TRIM(lin.REFKEY), LEN(TRIM(lin.REFKEY)) - 4),
        TRIM(lin.REFKEY)
    ) AS reference_doc_id,
    lin.MENGE AS quantity,
    lin.ITMTYP AS item_category,
    lin.MEINS AS base_unit_measure,
    lin.NFDIS AS discount_value,
    lin.WERKS AS plant_center,
    lin.NFFRE AS freight_value,
    lin.NFINS AS insurance_amount,
    lin.NFOTH AS other_expenses,
    lin.NFNETT AS net_operation_value,
    lin.MWSKZ AS tax_code_iva,
    lin.XPED AS purchase_order_id,
    lin.NITEMPED AS po_item_number,
    lin.KOSTL AS cost_center,
    lin.AUFNR AS internal_order,
    lin.PRCTR AS profit_center,
    lin.PS_PSP_PNR AS wbs_element, -- Project structure
    doc.NFTYPE AS invoice_category,
    doc.DOCTYP AS doc_type,
    doc.DIRECT AS direction_indicator, -- Inbound/Outbound
    doc.DOCDAT AS document_date,
    doc.PSTDAT AS posting_date,
    doc.SERIES AS doc_series,
    doc.NFNUM AS manual_invoice_number,
    doc.BELNR AS accounting_doc_id,
    doc.GJAHR AS fiscal_year,
    doc.BUKRS AS company_code,
    doc.BRANCH AS business_place,
    doc.NFTOT AS total_invoice_amount,
    doc.NFENUM AS electronic_invoice_number,
    active.DOCSTA AS document_status,
    active.CANCEL AS is_reversed,
    active.REGIO || active.NFYEAR || active.NFMONTH || active.STCD1 || active.MODEL || active.SERIE || active.NFNUM9 || active.DOCNUM9 || active.CDV AS digital_access_key,
    acdoca.FKART AS billing_type,
    acdoca.ANLN1 AS asset_id,
    COALESCE(tax.base_vat, 0) AS vat_base_amount,
    COALESCE(tax.vat_amount, 0) AS vat_total_amount,
    COALESCE(tax.total_tax_amount, 0) AS total_tax_sum

FROM ERP_RAW.INVOICE_ITEMS lin -- J_1BNFLIN
LEFT JOIN ERP_RAW.INVOICE_HEADER doc -- J_1BNFDOC
    ON lin.DOCNUM = doc.DOCNUM
LEFT JOIN ERP_RAW.PARTNER_DATA nad -- J_1BNFNAD
    ON lin.DOCNUM = nad.DOCNUM AND doc.PARVW = nad.PARVW
LEFT JOIN ERP_RAW.ELECTRONIC_STATUS active -- J_1BNFE_ACTIVE
    ON lin.DOCNUM = active.DOCNUM
LEFT JOIN (
    SELECT
        k.ICMSTAXPAY AS "ICMS_Taxpayer",
        k.KUNNR AS "Partner_ID_Outbound",
        k.STCD1,
        k.STCD3,
        ROW_NUMBER() OVER (PARTITION BY TRIM(k.STCD1), TRIM(k.STCD3) ORDER BY k.KUNNR) AS rn
    FROM ERP_RAW.CUSTOMER_MASTER k -- KNA1
) master_partner
    ON TRIM(doc.CGC) = TRIM(master_partner.STCD1)
    AND master_partner.rn = 1
LEFT JOIN ERP_RAW.ACCOUNTING_JOURNAL acdoca -- ACDOCA
    ON doc.BUKRS = acdoca.RBUKRS
    AND doc.BELNR = acdoca.BELNR
    AND lin.ITMREF = acdoca.DOCLN
LEFT JOIN (
    SELECT
        DOCNUM,
        ITMNUM,
        SUM(CASE WHEN TAXTYP IN ('ICM2', 'CIC0', 'ICM1') THEN BASE ELSE 0 END) AS base_vat,
        SUM(CASE WHEN TAXTYP IN ('ICM2', 'CIC0', 'ICM1') THEN TAXVAL ELSE 0 END) AS vat_amount,
        SUM(TAXVAL) AS total_tax_amount
    FROM ERP_RAW.TAX_ITEMS -- J_1BNFSTX
    GROUP BY DOCNUM, ITMNUM
) tax 
    ON lin.DOCNUM = tax.DOCNUM AND lin.ITMNUM = tax.ITMNUM

WHERE 
    doc.PSTDAT >= DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1 MONTH')
    AND doc.PSTDAT <= CURRENT_DATE
    AND doc.NFTYPE NOT IN ('IA', 'YK', 'ZZ')
ORDER BY 
    lin.DOCNUM, lin.ITMNUM;
