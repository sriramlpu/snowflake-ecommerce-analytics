-- stg_orders.sql: Clean and type raw orders

WITH source AS (
      SELECT * FROM {{ source('raw', 'raw_orders') }}
  ),

renamed AS (
      SELECT
          order_id,
          customer_id,
          LOWER(TRIM(order_status))                         AS order_status,
          order_purchase_ts::TIMESTAMP_NTZ                  AS ordered_at,
          order_approved_ts::TIMESTAMP_NTZ                  AS approved_at,
          order_delivered_ts::TIMESTAMP_NTZ                 AS delivered_at,
          order_estimated_ts::TIMESTAMP_NTZ                 AS estimated_delivery_at,
          DATEDIFF('day', order_purchase_ts, order_delivered_ts)  AS actual_delivery_days,
          DATEDIFF('day', order_purchase_ts, order_estimated_ts)  AS estimated_delivery_days,
          CASE
              WHEN order_delivered_ts <= order_estimated_ts THEN TRUE
              ELSE FALSE
          END                                               AS is_on_time_delivery,
          CURRENT_TIMESTAMP()                               AS _loaded_at
      FROM source
      WHERE order_id IS NOT NULL
        AND customer_id IS NOT NULL
  )

SELECT * FROM renamed
