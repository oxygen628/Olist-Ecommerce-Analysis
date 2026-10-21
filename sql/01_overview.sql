-- 1.1 月度 GMV、订单数、客单价
SELECT
  o.order_month,
  COUNT(DISTINCT o.order_id) AS order_cnt,
  ROUND(SUM(i.price + i.freight_value), 2) AS gmv,
  ROUND(SUM(i.price), 2) AS product_gmv,
  ROUND(SUM(i.freight_value), 2) AS freight_gmv,
  ROUND(SUM(i.price + i.freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN fact_order_items i ON o.order_id = i.order_id
WHERE o.order_status NOT IN ('canceled','unavailable')
GROUP BY o.order_month
ORDER BY o.order_month;
-- 1.2 订单状态分布与取消率
SELECT
  order_status,
  COUNT(*) AS cnt,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM orders
GROUP BY order_status
ORDER BY cnt DESC;

SELECT
  COUNT(*) AS total_orders,
  SUM(order_status = 'canceled') AS canceled_cnt,
  SUM(order_status = 'unavailable') AS unavailable_cnt,
  ROUND((SUM(order_status = 'canceled') + SUM(order_status = 'unavailable')) * 100.0 / COUNT(*), 2) AS cancel_rate_pct
FROM orders;
-- 1.3 按州 GMV 与订单
SELECT
  c.customer_state,
  COUNT(DISTINCT o.order_id) AS order_cnt,
  ROUND(SUM(i.price + i.freight_value), 2) AS gmv,
  ROUND(SUM(i.price + i.freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN fact_order_items i ON o.order_id = i.order_id
JOIN dim_customers c ON o.customer_id = c.customer_id
WHERE o.order_status NOT IN ('canceled','unavailable')
GROUP BY c.customer_state
ORDER BY gmv DESC;
-- 1.4 月度订单趋势