-- ====== (A) Fresh database ======
DROP DATABASE IF EXISTS sales_analytics;
CREATE DATABASE sales_analytics
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE sales_analytics;
---------------------------------------------------------
-- ====== (B) Main table ======
-- Schema inferred from CSV:
-- Columns:
--   Transaction ID (int)      -> transaction_id
--   Date (YYYY-MM-DD)         -> order_date (DATE)
--   Product Category (text)   -> product_category
--   Product Name (text)       -> product_name
--   Units Sold (int)          -> units_sold
--   Unit Price (decimal)      -> unit_price
--   Total Revenue (decimal)   -> total_revenue
--   Region (text)             -> region
--   Payment Method (text)     -> payment_method

DROP TABLE IF EXISTS online_sales;

CREATE TABLE online_sales (
  transaction_id  INT          NOT NULL PRIMARY KEY,
  order_date      DATE         NOT NULL,
  product_category VARCHAR(100),
  product_name     VARCHAR(255),
  units_sold      INT          NOT NULL,
  unit_price      DECIMAL(10,2) NOT NULL,
  total_revenue   DECIMAL(12,2) NOT NULL,
  region          VARCHAR(100),
  payment_method  VARCHAR(100),
  KEY idx_order_date (order_date)
);
----------------------------------------------------------------------------------------------------
-- ====== (C) Load CSV ======
-- Replace the path below with your actual path.
-- NOTES:
--   * We use user variables (@...) to handle the header names with spaces.
--   * STR_TO_DATE for YYYY-MM-DD format.
--   * IGNORE 1 LINES skips the header row.
LOAD DATA LOCAL INFILE 'D:\\Data Analyst Internship\\Task_6\\Online Sales Data.csv'
INTO TABLE online_sales
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@transaction_id, @date_str, @product_category, @product_name, @units_sold,
 @unit_price, @total_revenue, @region, @payment_method)
SET
  transaction_id   = NULLIF(@transaction_id,''),
  order_date       = STR_TO_DATE(@date_str, '%Y-%m-%d'),
  product_category = @product_category,
  product_name     = @product_name,
  units_sold       = NULLIF(@units_sold,''),
  unit_price       = NULLIF(@unit_price,''),
  total_revenue    = NULLIF(@total_revenue,''),
  region           = @region,
  payment_method   = @payment_method;

-- Optional sanity checks
SELECT COUNT(*) AS rows_loaded FROM online_sales;
SELECT MIN(order_date) AS min_date, MAX(order_date) AS max_date FROM online_sales;
----------------------------------------------------------------------------------------------------
-- ====== (D) Core monthly trend query ======

SELECT
  EXTRACT(YEAR  FROM order_date) AS year,
  EXTRACT(MONTH FROM order_date) AS month,
  ROUND(SUM(total_revenue), 2)   AS total_revenue,
  COUNT(DISTINCT transaction_id) AS order_volume
FROM online_sales
GROUP BY EXTRACT(YEAR  FROM order_date),
         EXTRACT(MONTH FROM order_date)
ORDER BY year, month;
---------------------------------------------------------------------------------------
-- ====== (E) Filter to a specific period (example: 2024-01 to 2024-06) ======
SELECT
  EXTRACT(YEAR  FROM order_date) AS year,
  EXTRACT(MONTH FROM order_date) AS month,
  ROUND(SUM(total_revenue), 2)   AS total_revenue,
  COUNT(DISTINCT transaction_id) AS order_volume
FROM online_sales
WHERE order_date BETWEEN '2024-01-01' AND '2024-06-30'
GROUP BY EXTRACT(YEAR  FROM order_date),
         EXTRACT(MONTH FROM order_date)
ORDER BY year, month;
-------------------------------------------------------------------------------------------
-- ====== (F) Create a reusable view ======
CREATE OR REPLACE VIEW monthly_sales_trend AS
SELECT
  EXTRACT(YEAR  FROM order_date) AS year,
  EXTRACT(MONTH FROM order_date) AS month,
  ROUND(SUM(total_revenue), 2)   AS total_revenue,
  COUNT(DISTINCT transaction_id) AS order_volume
FROM online_sales
GROUP BY EXTRACT(YEAR  FROM order_date),
         EXTRACT(MONTH FROM order_date);

-- Use the view
SELECT * FROM monthly_sales_trend ORDER BY year, month;

----------------------------------------------------------------------------------------------
-- 1) Full monthly trend (+ AOV & units)
SELECT
  EXTRACT(YEAR  FROM order_date) AS year,
  EXTRACT(MONTH FROM order_date) AS month,
  ROUND(SUM(total_revenue), 2)   AS total_revenue,
  COUNT(DISTINCT transaction_id) AS order_volume,
  SUM(units_sold)                AS units_sold,
  ROUND(SUM(total_revenue) / NULLIF(COUNT(DISTINCT transaction_id), 0), 2) AS avg_order_value
FROM online_sales
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
ORDER BY year, month;

-- 2) Specific period (Jan–Jun 2024)
SELECT
  EXTRACT(YEAR FROM order_date)  AS year,
  EXTRACT(MONTH FROM order_date) AS month,
  ROUND(SUM(total_revenue), 2)   AS total_revenue,
  COUNT(DISTINCT transaction_id) AS order_volume
FROM online_sales
WHERE order_date BETWEEN '2024-01-01' AND '2024-06-30'
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
ORDER BY year, month;

-- 3) Current year only
SELECT
  EXTRACT(YEAR FROM order_date)  AS year,
  EXTRACT(MONTH FROM order_date) AS month,
  ROUND(SUM(total_revenue), 2)   AS total_revenue,
  COUNT(DISTINCT transaction_id) AS order_volume
FROM online_sales
WHERE YEAR(order_date) = YEAR(CURDATE())
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
ORDER BY year, month;

-- 4) Last 6 months (relative), sorted oldest→newest
WITH m AS (
  SELECT
    EXTRACT(YEAR FROM order_date)  AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    ROUND(SUM(total_revenue), 2)   AS total_revenue,
    COUNT(DISTINCT transaction_id) AS order_volume
  FROM online_sales
  GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
)
SELECT *
FROM (
  SELECT * FROM m ORDER BY year DESC, month DESC LIMIT 6
) t
ORDER BY year, month;

-- 5) Top 3 months by revenue
WITH m AS (
  SELECT
    EXTRACT(YEAR FROM order_date)  AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    ROUND(SUM(total_revenue), 2)   AS total_revenue,
    COUNT(DISTINCT transaction_id) AS order_volume
  FROM online_sales
  GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
)
SELECT * FROM m
ORDER BY total_revenue DESC
LIMIT 3;

-- 6) Months with revenue over a threshold
SELECT
  EXTRACT(YEAR FROM order_date)  AS year,
  EXTRACT(MONTH FROM order_date) AS month,
  ROUND(SUM(total_revenue), 2)   AS total_revenue,
  COUNT(DISTINCT transaction_id) AS order_volume
FROM online_sales
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)
HAVING SUM(total_revenue) > 50000
ORDER BY total_revenue DESC;

-- 7) Year/Month totals + grand total (ROLLUP)
SELECT
  EXTRACT(YEAR FROM order_date)  AS year,
  EXTRACT(MONTH FROM order_date) AS month,
  ROUND(SUM(total_revenue), 2)   AS total_revenue,
  COUNT(DISTINCT transaction_id) AS order_volume
FROM online_sales
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date) WITH ROLLUP;
--------------------------------------------------------------------------------------------------
-- B) Monthly trends by dimension (base table)
-- 8) By Region (month x region)
SELECT
  EXTRACT(YEAR FROM order_date)  AS year,
  EXTRACT(MONTH FROM order_date) AS month,
  region,
  ROUND(SUM(total_revenue), 2)   AS total_revenue,
  COUNT(DISTINCT transaction_id) AS order_volume
FROM online_sales
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date), region
ORDER BY year, month, region;

-- 9) By Product Category (month x category)
SELECT
  EXTRACT(YEAR FROM order_date)  AS year,
  EXTRACT(MONTH FROM order_date) AS month,
  product_category,
  ROUND(SUM(total_revenue), 2)   AS total_revenue,
  COUNT(DISTINCT transaction_id) AS order_volume
FROM online_sales
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date), product_category
ORDER BY year, month, total_revenue DESC;

-- 10) Top category per month (ranked)
WITH cat AS (
  SELECT
    EXTRACT(YEAR FROM order_date)  AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    product_category,
    SUM(total_revenue)             AS revenue
  FROM online_sales
  GROUP BY 1,2,3
),
ranked AS (
  SELECT
    year, month, product_category, revenue,
    RANK() OVER (PARTITION BY year, month ORDER BY revenue DESC) AS rnk
  FROM cat
)
SELECT year, month, product_category, ROUND(revenue,2) AS revenue
FROM ranked
WHERE rnk = 1
ORDER BY year, month;

-- 11) Monthly payment method split
SELECT
  EXTRACT(YEAR FROM order_date)  AS year,
  EXTRACT(MONTH FROM order_date) AS month,
  payment_method,
  ROUND(SUM(total_revenue), 2)   AS total_revenue,
  COUNT(DISTINCT transaction_id) AS order_volume
FROM online_sales
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date), payment_method
ORDER BY year, month, total_revenue DESC;
----------------------------------------------------------------------------------------------

-- C) Using the view monthly_sales_trend
-- The view has: year, month, total_revenue, order_volume.

-- 12) Add AOV easily
SELECT
  year, month, total_revenue, order_volume,
  ROUND(total_revenue / NULLIF(order_volume, 0), 2) AS avg_order_value
FROM monthly_sales_trend
ORDER BY year, month;

-- 13) Top 3 months by revenue
SELECT year, month, total_revenue, order_volume
FROM monthly_sales_trend
ORDER BY total_revenue DESC
LIMIT 3;

-- 14) Bottom 3 months by volume
SELECT year, month, total_revenue, order_volume
FROM monthly_sales_trend
ORDER BY order_volume ASC
LIMIT 3;

-- 15) YTD running totals (per year)
SELECT
  year, month, total_revenue, order_volume,
  SUM(total_revenue) OVER (PARTITION BY year ORDER BY month ROWS UNBOUNDED PRECEDING) AS ytd_revenue,
  SUM(order_volume)  OVER (PARTITION BY year ORDER BY month ROWS UNBOUNDED PRECEDING) AS ytd_orders
FROM monthly_sales_trend
ORDER BY year, month;

-- 16) 3-month moving average (revenue)
SELECT
  year, month, total_revenue,
  ROUND(AVG(total_revenue) OVER (ORDER BY year, month ROWS 2 PRECEDING), 2) AS ma3_revenue
FROM monthly_sales_trend
ORDER BY year, month;

-- 17) Filter a time window using year/month
SELECT *
FROM monthly_sales_trend
WHERE (year = 2024 AND month BETWEEN 1 AND 6)
ORDER BY year, month;

-- 18) Most recent 6 months (via view)
SELECT *
FROM (
  SELECT * FROM monthly_sales_trend ORDER BY year DESC, month DESC LIMIT 6
) t
ORDER BY year, month;