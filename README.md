# SAP S/4HANA to Snowflake: High-Performance Fiscal Engine

## 📌 Project Overview
This project demonstrates a high-complexity SQL transformation engine designed to offload heavy fiscal processing from **SAP S/4HANA** to **Snowflake**. 

Instead of running slow, resource-intensive reports directly in the ERP, this logic reconstructs the fiscal and billing business rules within the Cloud Data Warehouse. This creates a **"Single Source of Truth"** that serves as a foundation for all tax reconciliations and financial audits.

## 🛠 Tech Stack
* **Source:** SAP S/4HANA (Modules: FI, MM, SD)
* **Target:** Snowflake (Data Warehouse)
* **Language:** SQL (Snowflake Dialect)

## 🔍 Key Technical Features
* **Data Offloading Logic:** Reconstructs standard SAP fiscal reporting (Transaction J1B*) into optimized SQL Views.
* **Complex Multi-Module Joins:** Integrates `ACDOCA` (Accounting), `J_1BNFLIN` (Billing), and `KNA1` (Master Data) for a complete end-to-end view.
* **Dynamic Tax Aggregation:** Subquery logic to consolidate multiple tax types (VAT/Income Tax) into a flattened, easy-to-query format.
* **Data Integrity & Cleansing:** Advanced use of `IFF`, `TRY_TO_NUMBER`, and `ROW_NUMBER()` to handle master data duplicates and string inconsistencies.

## 💼 Business Impact
* **ERP Performance:** Reduces SAP processing load, preventing system lag during fiscal closing periods.
* **Operational Efficiency:** Analysts can query millions of records in seconds on Snowflake, whereas SAP reports might time out or take minutes.
* **Consistency:** Ensures all tax reconciliations are based on the same verified logic, reducing audit risks.

---
**Author:** Abimael Brilhante Soares Rodrigues  
*Data Analyst | Specialist in SAP Financial Data & Snowflake*
