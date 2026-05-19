# SAP S/4HANA to Snowflake Fiscal Transformation Engine (powered by dbt)

## 📌 Business Problem
Inside SAP S/4HANA ERP systems, fiscal and tax ledger models are highly normalized, fragmented, and transactional. Applying multi-clause aggregation queries directly across billions of live relational rows inside the transactional tax table (`J_1BNFSTX`) caused high database contention on Snowflake warehouses. This directly resulted in painful loading delays across corporate Qlik Sense reporting layers, stalling critical daily compliance analyses and financial month-end closing processes.

## ⚙️ The Architectural Solution
This project implements a modular modern ELT data framework leveraging **dbt (Data Build Tool)** and **Snowflake**, decoupling massive analytical workloads into robust semantic layers:
* **Staging Layer:** Handles direct upstream raw ingestion cleaning, fields formatting, and partner record deduplication (`KNA1`).
* **Marts Layer:** Pivots line-level rows of complex multi-tax code structures (`TAXTYP`) into distinct analytical metrics per invoice block, exposing a high-performance, analytics-ready downstream Fact entity (`fct_faturamento_notas_fiscais`).

## 🚀 Core Engineering Outcomes
* **Industrial Modularization:** Decoupled multi-tax groupings (ICMS, IPI, PIS, COFINS, ST, DIFAL, and FCP) and partner dimensions into clean, reusable upstream structures, eliminating code redundancy.
* **Automated Data Quality:** Enforced structural integrity and primary key health checks through native automated dbt schema tests (`not_null` assertions).
* **BI Query Performance Acceleration:** Drastically mitigated frontend dashboard fetch times by migrating a heavy 160-line live execution query into a pre-materialized, nocturnal data warehouse table.

## 🛠️ Project Structure
```text
sap-snowflake-fiscal-engine/
├── dbt_project.yml          # Global project configurations
├── models/
│   ├── staging/
│   │   ├── _stg__models.yml # Data quality tests for Staging
│   │   ├── stg_sap__impostos_nf.sql
│   │   └── stg_sap__parceiros_dedup.sql
│   └── marts/
│       ├── _marts__models.yml # Test assertions for Invoicing Fact
│       └── fct_faturamento_notas_fiscais.sql
└── README.md
---
**Author:** Abimael Brilhante Soares Rodrigues  
*Data Analyst | Specialist in SAP Financial Data & Snowflake*
