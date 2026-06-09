-- fct_orders.sql: Order-level fact table

WITH orders AS (
      SELECT * FROM {{ ref('stg_orders') }}
  ),
order_items_agg AS (
      SELECT
          order_id,
          COUNT(DISTINCT order_item_id) AS item_count,
          SUM(price)                    AS items_revenue,
          SUM(freight_value)            AS freight_total,
          SUM(price + freight_value)    AS order_revenue
      FROM {{ ref('stg_order_items') }}
      GROUP BY order_id
  ),
payments_agg AS (
      SELECT
          order_id,
          SUM(payment_value)            AS total_payment,
          MAX(payment_installments)     AS max_installments,
          LISTAGG(DISTINCT payment_type, ', ')
              WITHIN GROUP (ORDER BY payment_type) AS payment_types
      FROM {{ ref('stg_order_payments') }}
      GROUP BY order_id
  ),
customers AS (
      SELECT * FROM {{ ref('stg_customers') }}
  ),
final AS (
      SELECT
          o.order_id,
          o.customer_id,
          c.customer_unique_id,
          o.order_status,
          c.customer_city,
          c.customer_state,
          DATE_TRUNC('month', o.ordered_at)  AS order_month,
          o.ordered_at,
          o.delivered_at,
          o.estimated_delivery_at,
          oi.item_count,
          oi.items_revenue,
          oi.freight_total,
          oi.order_revenue,
          p.total_payment,
          p.max_installments,
          p.payment_types,
          o.actual_delivery_days,
          o.estimated_delivery_days,
          o.is_on_time_delivery,
          CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END AS is_delivered,
          CASE WHEN o.order_status = 'canceled'  THEN 1 ELSE 0 END AS is_canceled
      FROM orders o
      LEFT JOIN order_items_agg oi ON o.order_id = oi.order_id
      LEFT JOIN payments_agg    p  ON o.order_id = p.order_id
      LEFT JOIN customers       c  ON o.customer_id = c.customer_id
  )
SELECT * FROM final
