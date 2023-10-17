-- TASK 1
    SELECT DISTINCT market
FROM dim_customer
WHERE region = 'APAC' AND customer = 'Atliq Exclusive';

-- Task 2
SELECT
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) as unique_products_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) as unique_products_2021,
    round(((COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) - COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END)) / NULLIF(COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END), 0)) * 100,2) as percentage_chg
FROM fact_sales_monthly;

-- Task 3
WITH ProductCounts AS (
  SELECT
    segment,
    COUNT(DISTINCT product_code) AS product_count
  FROM
    dim_product
  GROUP BY
    segment
)

SELECT
  segment,
  product_count
FROM
  ProductCounts
ORDER BY
  product_count DESC;

-- TASK 4
SELECT p.product_code, p.product, mc.manufacturing_cost
FROM product p
JOIN manufacturing_cost mc ON p.product_code = mc.product_code
WHERE mc.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM manufacturing_cost)
   OR mc.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM manufacturing_cost);

-- Task 5

SELECT
    c.customer_code,
    c.customer,
    ROUND(AVG(pre_invoice_discount_pct), 4) AS average_discount_percentage
FROM
    dim_customer c
JOIN
    fact_pre_invoice_deductions f USING(customer_code)
WHERE
    fiscal_year = 2021
    AND market = 'India'
GROUP BY
    c.customer, c.customer_code
ORDER BY
    average_discount_percentage DESC
LIMIT 5;

-- task 6
 SELECT
    MONTHNAME(f.date) AS month,
    YEAR(f.date) AS year,
    CONCAT(ROUND(SUM(g.gross_price * f.sold_quantity) / 1000000, 2), 'M') AS gross_sales_amount
FROM
    fact_sales_monthly f
JOIN
    fact_gross_price g ON f.fiscal_year = g.fiscal_year AND f.product_code = g.product_code
JOIN
    dim_customer c ON c.customer_code = f.customer_code
WHERE
    customer = 'Atliq Exclusive'
GROUP BY
    month, year
ORDER BY
    year, month;

   
   -- tASK 7
      SELECT 
  SUM(sold_quantity) AS total_sold_quantity,
  (
    CASE  
      WHEN date BETWEEN '2019-09-01' AND '2019-11-30' THEN 'Q1'
      WHEN date BETWEEN '2019-12-01' AND '2020-02-29' THEN 'Q2'
      WHEN date BETWEEN '2020-03-01' AND '2020-05-31' THEN 'Q3'
      ELSE 'Q4'
    END
  ) AS quarter 
FROM 
  fact_sales_monthly  
GROUP BY 
  quarter 
ORDER BY 
  total_sold_quantity DESC;
  
  -- TASK 8
  
 WITH GrossSales AS (
    SELECT
        c.channel,
        SUM(sp.gross_price) AS gross_sales_mln
    FROM
        fact_sales_monthly sm
    JOIN
        fact_gross_price sp ON sm.product_code = sp.product_code AND sm.fiscal_year = sp.fiscal_year
    JOIN
        dim_customer c ON sm.customer_code = c.customer_code
    WHERE
        sm.fiscal_year = 2021  -- Filter for fiscal year 2021
    GROUP BY
        c.channel
),
TotalGrossSales AS (
    SELECT SUM(gross_sales_mln) AS total_gross_sales_mln FROM GrossSales
)
SELECT
    gs.channel,
    gs.gross_sales_mln,
    (gs.gross_sales_mln / tgs.total_gross_sales_mln) * 100 AS percentage
FROM
    GrossSales gs
CROSS JOIN
    TotalGrossSales tgs;
    
    -- TASK 9
    
WITH RankedProducts AS (
  SELECT
    p.division,
    p.product_code,
    p.product,
    SUM(s.sold_quantity) AS total_sold_quantity,
    RANK() OVER (PARTITION BY p.division ORDER BY SUM(s.sold_quantity) DESC) AS rank_order
  FROM
    dim_product p
    INNER JOIN fact_sales_monthly s ON p.product_code = s.product_code
  WHERE
    s.fiscal_year = 2021
  GROUP BY
    p.division, p.product_code, p.product
)
SELECT
  division,
  product_code,
  product,
  total_sold_quantity,
  rank_order
FROM
  RankedProducts
WHERE
  rank_order <= 3
ORDER BY
  division, rank_order;






