-- 2.1订单级漏斗
WITH base AS (
  SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date
  FROM orders
  WHERE order_status NOT IN ('canceled','unavailable')
)
SELECT
  COUNT(*) AS created_cnt,
  COUNT(order_approved_at) AS approved_cnt,
  COUNT(order_delivered_carrier_date) AS shipped_cnt,
  COUNT(order_delivered_customer_date) AS delivered_cnt,
  ROUND(COUNT(order_approved_at) * 100.0 / COUNT(*), 2) AS approve_rate,
  ROUND(COUNT(order_delivered_carrier_date) * 100.0 / COUNT(order_approved_at), 2) AS ship_rate,
  ROUND(COUNT(order_delivered_customer_date) * 100.0 / COUNT(order_delivered_carrier_date), 2) AS deliver_rate,
  ROUND(COUNT(order_delivered_customer_date) * 100.0 / COUNT(*), 2) AS overall_deliver_rate
FROM base;
-- 2.2发货时长、送达时长与延迟率
SELECT
  ROUND(AVG(approval_hours), 2) AS avg_approval_hours,
  ROUND(AVG(TIMESTAMPDIFF(HOUR, order_approved_at, order_delivered_carrier_date)), 2) AS avg_ship_hours,
  ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
  ROUND(AVG(TIMESTAMPDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date)), 2) AS avg_delay_days,
  SUM(order_delivered_customer_date > order_estimated_delivery_date) AS late_cnt,
  COUNT(order_delivered_customer_date) AS delivered_cnt,
  ROUND(SUM(order_delivered_customer_date > order_estimated_delivery_date) * 100.0
        / COUNT(order_delivered_customer_date), 2) AS late_rate_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;