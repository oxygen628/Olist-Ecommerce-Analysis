-- 3.1复购率
WITH user_orders AS (
  SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS order_cnt,
    MIN(o.order_purchase_timestamp) AS first_order_time,
    MAX(o.order_purchase_timestamp) AS last_order_time
  FROM orders o
  JOIN dim_customers c ON o.customer_id = c.customer_id
  WHERE o.order_status NOT IN ('canceled','unavailable')
  GROUP BY c.customer_unique_id
)
SELECT
  COUNT(*) AS total_users,
  SUM(order_cnt >= 2) AS repeat_users,
  ROUND(SUM(order_cnt >= 2) * 100.0 / COUNT(*), 2) AS repeat_rate_pct,
  ROUND(AVG(order_cnt), 2) AS avg_orders_per_user,
  MAX(order_cnt) AS max_orders
FROM user_orders;
-- 2.2复购间隔分布
WITH user_orders AS (
  SELECT
    c.customer_unique_id,
    o.order_purchase_timestamp,
    LAG(o.order_purchase_timestamp) OVER (
      PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp
    ) AS prev_order_time
  FROM orders o
  JOIN dim_customers c ON o.customer_id = c.customer_id
  WHERE o.order_status NOT IN ('canceled','unavailable')
)
SELECT
  CASE
    WHEN diff_days <= 30 THEN '0-30天'
    WHEN diff_days <= 90 THEN '31-90天'
    WHEN diff_days <= 180 THEN '91-180天'
    WHEN diff_days <= 365 THEN '181-365天'
    ELSE '365天以上'
  END AS interval_bucket,
  COUNT(*) AS cnt
FROM (
  SELECT TIMESTAMPDIFF(DAY, prev_order_time, order_purchase_timestamp) AS diff_days
  FROM user_orders
  WHERE prev_order_time IS NOT NULL
) t
GROUP BY interval_bucket
ORDER BY interval_bucket;