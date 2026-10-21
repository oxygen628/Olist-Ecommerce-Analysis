USE olist_analysis;

-- 6.1 月度经营总览（直接用汇总表）
CREATE OR REPLACE VIEW v_monthly_overview AS
SELECT order_month, order_cnt, gmv, avg_order_value
FROM summary_monthly_gmv
ORDER BY order_month;

-- 6.2 品类销售（直接用汇总表）
CREATE OR REPLACE VIEW v_category_sales AS
SELECT category, order_cnt, total_gmv, avg_price
FROM summary_category_gmv
ORDER BY total_gmv DESC;

-- 6.3 履约漏斗
CREATE OR REPLACE VIEW v_funnel AS
SELECT
  COUNT(*) AS created_cnt,
  COUNT(order_approved_at) AS approved_cnt,
  COUNT(order_delivered_carrier_date) AS shipped_cnt,
  COUNT(order_delivered_customer_date) AS delivered_cnt,
  ROUND(COUNT(order_approved_at) * 100.0 / COUNT(*), 2) AS approve_rate,
  ROUND(COUNT(order_delivered_carrier_date) * 100.0 / COUNT(order_approved_at), 2) AS ship_rate,
  ROUND(COUNT(order_delivered_customer_date) * 100.0 / COUNT(order_delivered_carrier_date), 2) AS deliver_rate,
  ROUND(COUNT(order_delivered_customer_date) * 100.0 / COUNT(*), 2) AS overall_deliver_rate
FROM orders
WHERE order_status NOT IN ('canceled','unavailable');

-- 6.4 复购率
CREATE OR REPLACE VIEW v_repeat_rate AS
WITH user_orders AS (
  SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS order_cnt
  FROM orders o
  JOIN dim_customers c ON o.customer_id = c.customer_id
  WHERE o.order_status NOT IN ('canceled','unavailable')
  GROUP BY c.customer_unique_id
)
SELECT
  COUNT(*) AS total_users,
  SUM(order_cnt >= 2) AS repeat_users,
  ROUND(SUM(order_cnt >= 2) * 100.0 / COUNT(*), 2) AS repeat_rate_pct,
  ROUND(AVG(order_cnt), 2) AS avg_orders_per_user
FROM user_orders;

-- 6.5 州分布
CREATE OR REPLACE VIEW v_state_sales AS
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

-- 6.6 支付方式
CREATE OR REPLACE VIEW v_payment AS
SELECT
  payment_type,
  COUNT(DISTINCT order_id) AS order_cnt,
  ROUND(SUM(payment_value), 2) AS pay_amount,
  ROUND(AVG(payment_value), 2) AS avg_pay,
  ROUND(AVG(payment_installments), 2) AS avg_installments
FROM payments
GROUP BY payment_type
ORDER BY pay_amount DESC;

-- 6.7 履约时效
CREATE OR REPLACE VIEW v_delivery_perf AS
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
CREATE OR REPLACE VIEW v_state_performance AS
SELECT
  c.customer_state,
  COUNT(DISTINCT o.order_id) AS order_cnt,
  ROUND(SUM(i.price + i.freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
  ROUND(SUM(o.order_delivered_customer_date > o.order_estimated_delivery_date) * 100.0
        / COUNT(o.order_delivered_customer_date), 2) AS late_rate
FROM orders o
JOIN fact_order_items i ON o.order_id = i.order_id
JOIN dim_customers c ON o.customer_id = c.customer_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.customer_state
HAVING COUNT(DISTINCT o.order_id) > 100; -- 过滤掉订单量太小的州，避免数据波动太大