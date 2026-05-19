WITH source_kna1 AS (
    SELECT * FROM RAW.HANA_S4P.KNA1 --
),

deduplicated AS (
    SELECT
        ICMSTAXPAY AS is_contribuinte_icms,
        KUNNR AS codigo_parceiro_saidas,
        TRIM(STCD1) AS cnpj_base,
        TRIM(STCD3) AS inscricao_estadual,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(STCD1), TRIM(STCD3) 
            ORDER BY KUNNR
        ) AS row_num
    FROM source_kna1
)

SELECT
    is_contribuinte_icms,
    codigo_parceiro_saidas,
    cnpj_base,
    inscricao_estadual,
    row_num
FROM deduplicated
