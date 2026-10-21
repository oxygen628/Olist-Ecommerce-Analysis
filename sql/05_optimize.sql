USE olist_analysis;

-- ============================================================
-- 05 MySQL 性能优化专项
-- 目标：对 3 条核心查询做 EXPLAIN 分析，建汇总表，对比耗时
-- ============================================================

-- ---------- 5.1 优化前：记录耗时 ----------
-- 在 MySQL 命令行执行，不要在 Workbench 里看“耗时”列（不准）
-- 方式：SET profiling = 1; 执行查询; SHOW PROFILES;

SET profiling = 1;

-- 查询 1：月度 GMV
SELECT o.order_month, COUNT(DISTINCT o.order_id) AS order_cnt,
       ROUND(SUM(i.price + i.freight_value), 2) AS gmv
FROM orders o JOIN fact_order_items i ON o.order_id = i.order_id
WHERE o.order_status NOT IN ('canceled','unavailable')
GROUP BY o.order_month ORDER BY o.order_month;

-- 查询 2：复购率
WITH user_orders AS (
  SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS order_cnt
  FROM orders o JOIN dim_customers c ON o.customer_id = c.customer_id
  WHERE o.order_status NOT IN ('canceled','unavailable')
  GROUP BY c.customer_unique_id
)
SELECT COUNT(*) AS total_users, SUM(order_cnt >= 2) AS repeat_users,
       ROUND(SUM(order_cnt >= 2) * 100.0 / COUNT(*), 2) AS repeat_rate_pct
FROM user_orders;

-- 查询 3：品类销售
SELECT p.product_category_name_english AS category,
       ROUND(SUM(i.price + i.freight_value), 2) AS total_gmv
FROM fact_order_items i
JOIN dim_products p ON i.product_id = p.product_id
JOIN orders o ON i.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled','unavailable')
GROUP BY p.product_category_name_english ORDER BY total_gmv DESC;

SHOW PROFILES;

-- ---------- 5.2 EXPLAIN 看执行计划 ----------
EXPLAIN SELECT o.order_month, COUNT(DISTINCT o.order_id) AS order_cnt
FROM orders o JOIN fact_order_items i ON o.order_id = i.order_id
WHERE o.order_status NOT IN ('canceled','unavailable')
GROUP BY o.order_month;
-- 看：type 是否 ref/range，key 是否用了索引，rows 是否全表扫描，Extra 是否有 Using temporary/filesort

-- ---------- 5.3 建汇总表 ----------
DROP TABLE IF EXISTS summary_monthly_gmv;
CREATE TABLE summary_monthly_gmv AS
SELECT o.order_month,
       COUNT(DISTINCT o.order_id) AS order_cnt,
       ROUND(SUM(i.price + i.freight_value), 2) AS gmv,
       ROUND(SUM(i.price + i.freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o JOIN fact_order_items i ON o.order_id = i.order_id
WHERE o.order_status NOT IN ('canceled','unavailable')
GROUP BY o.order_month;

ALTER TABLE summary_monthly_gmv ADD PRIMARY KEY (order_month);

DROP TABLE IF EXISTS summary_category_gmv;
CREATE TABLE summary_category_gmv AS
SELECT p.product_category_name_english AS category,
       COUNT(DISTINCT o.order_id) AS order_cnt,
       ROUND(SUM(i.price + i.freight_value), 2) AS total_gmv,
       ROUND(AVG(i.price), 2) AS avg_price
FROM fact_order_items i
JOIN dim_products p ON i.product_id = p.product_id
JOIN orders o ON i.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled','unavailable')
GROUP BY p.product_category_name_english;

ALTER TABLE summary_category_gmv ADD PRIMARY KEY (category);

-- ---------- 5.4 优化后：查汇总表，对比耗时 ----------
SET profiling = 1;
SELECT * FROM summary_monthly_gmv ORDER BY order_month;
SELECT * FROM summary_category_gmv ORDER BY total_gmv DESC;
SHOW PROFILES;