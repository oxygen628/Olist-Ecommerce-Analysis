-- 4.1品类销售 Top 20
SELECT
  p.product_category_name_english AS category,
  COUNT(DISTINCT o.order_id) AS order_cnt,
  SUM(i.order_item_id IS NOT NULL) AS item_cnt,
  ROUND(SUM(i.price), 2) AS product_gmv,
  ROUND(SUM(i.freight_value), 2) AS freight_gmv,
  ROUND(SUM(i.price + i.freight_value), 2) AS total_gmv,
  ROUND(AVG(i.price), 2) AS avg_price
FROM fact_order_items i
JOIN dim_products p ON i.product_id = p.product_id
JOIN orders o ON i.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled','unavailable')
GROUP BY p.product_category_name_english
ORDER BY total_gmv DESC
LIMIT 20;
-- 4.2品类评分与差评率
WITH order_category AS (
  SELECT DISTINCT
    i.order_id,
    p.product_category_name_english AS category
  FROM fact_order_items i
  JOIN dim_products p ON i.product_id = p.product_id
),
order_review AS (
  SELECT order_id, AVG(review_score) AS score
  FROM reviews
  GROUP BY order_id
)
SELECT
  oc.category,
  COUNT(*) AS order_cnt,
  ROUND(AVG(r.score), 2) AS avg_score,
  SUM(r.score <= 2) AS bad_review_cnt,
  ROUND(SUM(r.score <= 2) * 100.0 / COUNT(*), 2) AS bad_review_rate_pct
FROM order_category oc
JOIN order_review r ON oc.order_id = r.order_id
GROUP BY oc.category
HAVING COUNT(*) >= 100
ORDER BY bad_review_rate_pct DESC
LIMIT 20;
-- 4.3卖家履约与差评率
WITH seller_delivery AS (
  SELECT
    i.seller_id,
    COUNT(DISTINCT o.order_id) AS order_cnt,
    ROUND(SUM(i.price + i.freight_value), 2) AS gmv,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, o.order_approved_at, o.order_delivered_carrier_date)), 2) AS avg_ship_hours,
    ROUND(AVG(o.delivery_days), 2) AS avg_delivery_days,
    SUM(o.order_delivered_customer_date > o.order_estimated_delivery_date) AS late_cnt
  FROM fact_order_items i
  JOIN orders o ON i.order_id = o.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY i.seller_id
),
seller_review AS (
  SELECT
    i.seller_id,
    AVG(r.review_score) AS avg_score,
    SUM(r.review_score <= 2) AS bad_cnt,
    COUNT(*) AS review_cnt
  FROM fact_order_items i
  JOIN reviews r ON i.order_id = r.order_id
  GROUP BY i.seller_id
)
SELECT
  s.seller_id,
  s.order_cnt,
  s.gmv,
  s.avg_ship_hours,
  s.avg_delivery_days,
  ROUND(s.late_cnt * 100.0 / s.order_cnt, 2) AS late_rate_pct,
  ROUND(r.avg_score, 2) AS avg_score,
  ROUND(r.bad_cnt * 100.0 / r.review_cnt, 2) AS bad_review_rate_pct
FROM seller_delivery s
LEFT JOIN seller_review r ON s.seller_id = r.seller_id
WHERE s.order_cnt >= 20
ORDER BY s.gmv DESC
LIMIT 20;
-- 4.4支付方式分析
SELECT
  payment_type,
  COUNT(DISTINCT order_id) AS order_cnt,
  ROUND(SUM(payment_value), 2) AS pay_amount,
  ROUND(AVG(payment_value), 2) AS avg_pay,
  ROUND(AVG(payment_installments), 2) AS avg_installments
FROM payments
GROUP BY payment_type
ORDER BY pay_amount DESC;