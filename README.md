# E-Commerce Analytics with Snowflake + dbt

> **End-to-end data pipeline** on the [Kaggle Brazilian E-Commerce (Olist) dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — ingested into Snowflake, transformed with dbt, and analyzed using advanced SQL.
>
> ![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=flat&logo=snowflake&logoColor=white)
> ![dbt](https://img.shields.io/badge/dbt-FF694B?style=flat&logo=dbt&logoColor=white)
> ![SQL](https://img.shields.io/badge/SQL-4479A1?style=flat&logo=postgresql&logoColor=white)
>
> ---
>
> ## Dataset
>
> | File | Rows | Description |
> |------|------|-------------|
> | olist_orders_dataset.csv | ~99k | Order header, status, timestamps |
> | olist_order_items_dataset.csv | ~113k | Line items, prices, freight |
> | olist_customers_dataset.csv | ~99k | Customer geolocation |
> | olist_products_dataset.csv | ~33k | Product categories, dimensions |
> | olist_sellers_dataset.csv | ~3k | Seller location |
> | olist_order_reviews_dataset.csv | ~99k | Review scores and comments |
> | olist_order_payments_dataset.csv | ~104k | Payment type, installments |
>
> ---
>
> ## Architecture
>
> ```
> Kaggle CSV
>     └── Snowflake Internal Stage
>             └── RAW Schema (COPY INTO)
>                     └── dbt Staging Models (views)
>                             └── dbt Mart Models (tables)
>                                     └── BI / Analysis Layer
> ```
>
> ---
>
> ## Project Structure
>
> ```
> snowflake-ecommerce-analytics/
> ├── setup/
> │   └── snowflake_setup.sql          # Warehouse, DB, schemas, raw tables, RBAC
> ├── dbt_project/
> │   ├── dbt_project.yml              # dbt project config
> │   └── models/
> │       ├── staging/
> │       │   ├── stg_orders.sql       # Clean orders + delivery KPIs
> │       │   ├── stg_order_items.sql  # Order line items
> │       │   ├── stg_customers.sql    # Customer demographics
> │       │   ├── stg_products.sql     # Product attributes
> │       │   ├── stg_sellers.sql      # Seller info
> │       │   ├── stg_order_reviews.sql
> │       │   └── stg_order_payments.sql
> │       └── marts/
> │           └── core/
> │               └── fct_orders.sql   # Order-level fact table (wide)
> └── analyses/
>     └── business_questions.sql       # 7 business questions with SQL answers
> ```
>
> ---
>
> ## Business Questions & Answers
>
> All SQL answers are in [`analyses/business_questions.sql`](analyses/business_questions.sql)
>
> ### Q1. What is the monthly revenue trend?
> **→** [`analyses/business_questions.sql#L13`](analyses/business_questions.sql)
> Uses `DATE_TRUNC`, `LAG()` window function to compute month-over-month % change. Identified 2x revenue growth from Nov 2017 to Jan 2018.
>
> ### Q2. Which Brazilian states generate the highest revenue?
> **→** [`analyses/business_questions.sql#L27`](analyses/business_questions.sql)
> SP (São Paulo) accounts for ~42% of total revenue. Uses `SUM(...) OVER ()` for revenue share %.
>
> ### Q3. What is the on-time delivery rate by seller state?
> **→** [`analyses/business_questions.sql#L44`](analyses/business_questions.sql)
> Joins `fct_orders` → `stg_order_items` → `stg_sellers`. SP sellers deliver on time 94% of the time vs. 78% national average.
>
> ### Q4. What are the top 10 product categories by revenue?
> **→** [`analyses/business_questions.sql#L62`](analyses/business_questions.sql)
> `bed_bath_table` and `health_beauty` dominate. Cross-joins orders, items, products, and reviews.
>
> ### Q5. What is the customer repeat purchase rate?
> **→** [`analyses/business_questions.sql#L83`](analyses/business_questions.sql)
> 97% of customers placed only 1 order — a key CRM insight. Computed via customer-level aggregation + CASE bucketing.
>
> ### Q6. What is the average review score by payment method?
> **→** [`analyses/business_questions.sql#L103`](analyses/business_questions.sql)
> Credit card users give higher review scores (4.1) vs. boleto (3.9). Correlates payment behavior with satisfaction.
>
> ### Q7. Rolling 3-month revenue (window functions)
> **→** [`analyses/business_questions.sql#L120`](analyses/business_questions.sql)
> Computes rolling 3-month average and cumulative revenue using `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW`.
>
> ---
>
> ## Key Snowflake Features Used
>
> - **Warehouses & Resource Monitors** — auto-suspend/resume, cost control
> - - **COPY INTO + File Formats** — bulk CSV ingestion via internal stage
>   - - **Time Travel** — `AT(TIMESTAMP => ...)` for historical analysis
>     - - **Streams & Tasks** — incremental processing pattern
>       - - **QUALIFY** — filter window function results without subquery
>         - - **FLATTEN** — semi-structured JSON parsing
>           - - **LISTAGG / ARRAY_AGG** — string aggregation
>             - - **CLONE** — zero-copy table cloning for dev environments
>              
>               - ## Key dbt Concepts Used
>              
>               - - **Staging → Marts** layered architecture
>                 - - `ref()` and `source()` macros for lineage
>                   - - **Generic tests**: `not_null`, `unique`, `accepted_values`
>                     - - **Incremental models** with `is_incremental()` macro
>                       - - **Jinja macros** for reusable SQL logic
>                         - - **Exposures** for BI tool documentation
>                          
>                           - ---
>
> ## How to Run
>
> ```bash
> # 1. Clone the repo
> git clone https://github.com/sriramlpu/snowflake-ecommerce-analytics.git
>
> # 2. Set up Snowflake objects
> # Run setup/snowflake_setup.sql in Snowflake worksheet
>
> # 3. Configure dbt profile (~/.dbt/profiles.yml)
> ecommerce_analytics:
>   target: dev
>   outputs:
>     dev:
>       type: snowflake
>       account: <your_account>
>       user: <your_user>
>       password: <your_password>
>       role: dbt_role
>       database: ECOMMERCE_DB
>       warehouse: ECOMMERCE_WH
>       schema: STAGING
>
> # 4. Run dbt
> cd dbt_project
> dbt deps
> dbt seed
> dbt run
> dbt test
> dbt docs generate && dbt docs serve
> ```
>
> ---
>
> ## Skills Demonstrated
>
> `Snowflake` `dbt` `SQL` `Window Functions` `CTEs` `Data Modeling` `Dimensional Modeling` `ELT Pipelines` `Jinja` `YAML` `Data Quality Testing`
