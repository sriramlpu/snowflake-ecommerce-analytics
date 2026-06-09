-- ================================================================
-- E-Commerce Analytics: Business Questions & SQL Answers
-- Dataset: Kaggle - Brazilian E-Commerce (Olist) Dataset
-- Snowflake SQL  |  dbt mart: ECOMMERCE_DB.MARTS
-- ================================================================

-- ---------------------------------------------------------------
-- Q1. What is the monthly revenue trend over time?
-- ---------------------------------------------------------------
SELECT
    order_month,
    COUNT(DISTINCT order_id)              AS total_orders,
    ROUND(SUM(order_revenue), 2)          AS total_revenue,
    ROUND(AVG(order_revenue), 2)          AS avg_order_value,
    ROUND(
          100.0 * (SUM(order_revenue) - LAG(SUM(order_revenue)) OVER (ORDER BY order_month))
          / NULLIF(LAG(SUM(order_revenue)) OVER (ORDER BY order_month), 0),
      2)                                    AS revenue_mom_pct
FROM ECOMMERCE_DB.MARTS.fct_orders
WHERE order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;


-- ---------------------------------------------------------------
-- Q2. Which Brazilian states generate the highest revenue?
-- ---------------------------------------------------------------
SELECT
    customer_state,
    COUNT(DISTINCT order_id)              AS total_orders,
    COUNT(DISTINCT customer_unique_id)    AS unique_customers,
    ROUND(SUM(order_revenue), 2)          AS total_revenue,
    ROUND(AVG(order_revenue), 2)          AS avg_order_value,
    ROUND(SUM(order_revenue) * 100.0 /
            SUM(SUM(order_revenue)) OVER (), 2) AS revenue_pct
FROM ECOMMERCE_DB.MARTS.fct_orders
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY total_revenue DESC
LIMIT 10;


-- ---------------------------------------------------------------
-- Q3. What is the on-time delivery rate by seller state?
-- ---------------------------------------------------------------
WITH seller_delivery AS (
      SELECT
          s.seller_state,
          COUNT(fo.order_id)                AS total_orders,
          SUM(fo.is_on_time_delivery::INT)  AS on_time_orders,
          ROUND(
              100.0 * SUM(fo.is_on_time_delivery::INT) / COUNT(fo.order_id),
          1)                                AS on_time_pct,
          ROUND(AVG(fo.actual_delivery_days), 1) AS avg_delivery_days
      FROM ECOMMERCE_DB.MARTS.fct_orders fo
      JOIN ECOMMERCE_DB.STAGING.stg_order_items oi ON fo.order_id = oi.order_id
      JOIN ECOMMERCE_DB.STAGING.stg_sellers     s  ON oi.seller_id = s.seller_id
      WHERE fo.order_status = 'delivered'
      GROUP BY s.seller_state
  )
SELECT * FROM seller_delivery ORDER BY on_time_pct DESC;


-- ---------------------------------------------------------------
-- Q4. What are the top 10 product categories by revenue?
-- ---------------------------------------------------------------
SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id)           AS total_orders,
    SUM(oi.quantity)                      AS units_sold,
    ROUND(SUM(oi.price), 2)               AS total_revenue,
    ROUND(AVG(oi.price), 2)               AS avg_price,
    ROUND(AVG(r.review_score), 2)         AS avg_review_score
FROM ECOMMERCE_DB.STAGING.stg_order_items  oi
JOIN ECOMMERCE_DB.STAGING.stg_products      p  ON oi.product_id = p.product_id
JOIN ECOMMERCE_DB.STAGING.stg_orders        o  ON oi.order_id   = o.order_id
LEFT JOIN ECOMMERCE_DB.STAGING.stg_order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 10;


-- ---------------------------------------------------------------
-- Q5. What is customer repeat purchase rate?
-- ---------------------------------------------------------------
WITH customer_orders AS (
      SELECT
          customer_unique_id,
          COUNT(DISTINCT order_id)  AS order_count,
          MIN(ordered_at)           AS first_order_at,
          MAX(ordered_at)           AS last_order_at,
          SUM(order_revenue)        AS lifetime_value
      FROM ECOMMERCE_DB.MARTS.fct_orders
      WHERE order_status = 'delivered'
      GROUP BY customer_unique_id
  )
SELECT
    CASE
        WHEN order_count = 1 THEN '1 order (one-time)'
        WHEN order_count = 2 THEN '2 orders'
        WHEN order_count BETWEEN 3 AND 5 THEN '3-5 orders'
        ELSE '6+ orders'
    END                                    AS order_segment,
    COUNT(customer_unique_id)              AS customer_count,
    ROUND(AVG(lifetime_value), 2)          AS avg_ltv,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers
FROM customer_orders
GROUP BY order_segment
ORDER BY customer_count DESC;


-- ---------------------------------------------------------------
-- Q6. What is the average review score by payment method?
-- ---------------------------------------------------------------
SELECT
    p.payment_type,
    COUNT(DISTINCT fo.order_id)           AS total_orders,
    ROUND(AVG(r.review_score), 2)         AS avg_review_score,
    ROUND(AVG(fo.order_revenue), 2)       AS avg_order_value,
    ROUND(AVG(fo.max_installments), 1)    AS avg_installments
FROM ECOMMERCE_DB.MARTS.fct_orders        fo
JOIN ECOMMERCE_DB.STAGING.stg_order_payments p ON fo.order_id = p.order_id
LEFT JOIN ECOMMERCE_DB.STAGING.stg_order_reviews r ON fo.order_id = r.order_id
WHERE fo.order_status = 'delivered'
GROUP BY p.payment_type
ORDER BY avg_review_score DESC;


-- ---------------------------------------------------------------
-- Q7. Rolling 3-month revenue (window function)
-- ---------------------------------------------------------------
WITH monthly_revenue AS (
      SELECT
          order_month,
          ROUND(SUM(order_revenue), 2) AS monthly_revenue
      FROM ECOMMERCE_DB.MARTS.fct_orders
      WHERE order_status = 'delivered'
      GROUP BY order_month
  )
SELECT
    order_month,
    monthly_revenue,
    ROUND(AVG(monthly_revenue) OVER (
          ORDER BY order_month
          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
      ), 2)                            AS rolling_3m_avg,
    ROUND(SUM(monthly_revenue) OVER (
          ORDER BY order_month
      ), 2)                            AS cumulative_revenue
FROM monthly_revenue
ORDER BY order_month;
