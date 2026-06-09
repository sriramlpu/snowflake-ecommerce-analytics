-- ============================================================
-- Snowflake Setup: E-Commerce Analytics
-- Dataset: Kaggle - Brazilian E-Commerce Public Dataset (Olist)
-- ============================================================

-- Step 1: Create Warehouse, Database, Schemas
CREATE WAREHOUSE IF NOT EXISTS ECOMMERCE_WH
  WAREHOUSE_SIZE = 'X-SMALL'
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE
  COMMENT = 'Warehouse for e-commerce analytics workloads';

CREATE DATABASE IF NOT EXISTS ECOMMERCE_DB
  COMMENT = 'Brazilian E-Commerce (Olist) Analytics Database';

CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DB.RAW
  COMMENT = 'Raw ingested data from Kaggle CSV files';

CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DB.STAGING
  COMMENT = 'Cleaned and typed staging models (dbt)';

CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DB.MARTS
  COMMENT = 'Business-facing dimensional models (dbt)';

USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;

-- Step 2: Create File Format for CSV ingestion
CREATE OR REPLACE FILE FORMAT csv_format
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  NULL_IF = ('NULL', 'null', '')
  EMPTY_FIELD_AS_NULL = TRUE;

-- Step 3: Create Stage pointing to Kaggle CSV data
CREATE OR REPLACE STAGE ecommerce_stage
  FILE_FORMAT = csv_format
  COMMENT = 'Internal stage for Olist CSVs';

-- Step 4: Create Raw Tables
CREATE OR REPLACE TABLE raw_orders (
    order_id              VARCHAR(50),
    customer_id           VARCHAR(50),
    order_status          VARCHAR(20),
    order_purchase_ts     TIMESTAMP_NTZ,
    order_approved_ts     TIMESTAMP_NTZ,
    order_delivered_ts    TIMESTAMP_NTZ,
    order_estimated_ts    TIMESTAMP_NTZ
  );

CREATE OR REPLACE TABLE raw_order_items (
    order_id              VARCHAR(50),
    order_item_id         NUMBER,
    product_id            VARCHAR(50),
    seller_id             VARCHAR(50),
    shipping_limit_date   TIMESTAMP_NTZ,
    price                 FLOAT,
    freight_value         FLOAT
  );

CREATE OR REPLACE TABLE raw_customers (
    customer_id           VARCHAR(50),
    customer_unique_id    VARCHAR(50),
    customer_zip          VARCHAR(10),
    customer_city         VARCHAR(100),
    customer_state        CHAR(2)
  );

CREATE OR REPLACE TABLE raw_products (
    product_id            VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_length   NUMBER,
    product_desc_length   NUMBER,
    product_photos_qty    NUMBER,
    product_weight_g      FLOAT,
    product_length_cm     FLOAT,
    product_height_cm     FLOAT,
    product_width_cm      FLOAT
  );

CREATE OR REPLACE TABLE raw_sellers (
    seller_id             VARCHAR(50),
    seller_zip            VARCHAR(10),
    seller_city           VARCHAR(100),
    seller_state          CHAR(2)
  );

CREATE OR REPLACE TABLE raw_order_reviews (
    review_id             VARCHAR(50),
    order_id              VARCHAR(50),
    review_score          NUMBER,
    review_comment_title  VARCHAR(255),
    review_comment_msg    TEXT,
    review_creation_date  TIMESTAMP_NTZ,
    review_answer_ts      TIMESTAMP_NTZ
  );

CREATE OR REPLACE TABLE raw_order_payments (
    order_id              VARCHAR(50),
    payment_sequential    NUMBER,
    payment_type          VARCHAR(30),
    payment_installments  NUMBER,
    payment_value         FLOAT
  );

-- Step 5: Load data from stage (run after uploading CSVs to stage)
-- COPY INTO raw_orders FROM @ecommerce_stage/olist_orders_dataset.csv;
-- COPY INTO raw_order_items FROM @ecommerce_stage/olist_order_items_dataset.csv;
-- COPY INTO raw_customers FROM @ecommerce_stage/olist_customers_dataset.csv;
-- COPY INTO raw_products FROM @ecommerce_stage/olist_products_dataset.csv;
-- COPY INTO raw_sellers FROM @ecommerce_stage/olist_sellers_dataset.csv;
-- COPY INTO raw_order_reviews FROM @ecommerce_stage/olist_order_reviews_dataset.csv;
-- COPY INTO raw_order_payments FROM @ecommerce_stage/olist_order_payments_dataset.csv;

-- Step 6: Grant permissions to dbt role
CREATE ROLE IF NOT EXISTS dbt_role;
GRANT USAGE ON WAREHOUSE ECOMMERCE_WH TO ROLE dbt_role;
GRANT USAGE ON DATABASE ECOMMERCE_DB TO ROLE dbt_role;
GRANT ALL ON ALL SCHEMAS IN DATABASE ECOMMERCE_DB TO ROLE dbt_role;
GRANT ALL ON ALL TABLES IN SCHEMA ECOMMERCE_DB.RAW TO ROLE dbt_role;
GRANT CREATE TABLE ON SCHEMA ECOMMERCE_DB.STAGING TO ROLE dbt_role;
GRANT CREATE TABLE ON SCHEMA ECOMMERCE_DB.MARTS TO ROLE dbt_role;
GRANT CREATE VIEW ON SCHEMA ECOMMERCE_DB.STAGING TO ROLE dbt_role;
GRANT CREATE VIEW ON SCHEMA ECOMMERCE_DB.MARTS TO ROLE dbt_role;
