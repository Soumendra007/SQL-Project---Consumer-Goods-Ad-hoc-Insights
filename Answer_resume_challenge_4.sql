#Codebasics Resume Project challange 4

#Task 1
Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
business in the  APAC  region. 

#Answer
SELECT DISTINCT market FROM dim_customer WHERE customer = "Atliq Exclusive" AND region = "APAC";

#Task 2
What is the percentage of unique product increase in 2021 vs. 2020? The 
final output contains these fields, 
unique_products_2020 
unique_products_2021 
percentage_chg 

#Answer

WITH unique_prod_cnt AS ( 
SELECT 
	COUNT(DISTINCT CASE WHEN fiscal_year=2020 THEN product_code END) AS unique_products_2020 ,
    COUNT(DISTINCT CASE WHEN fiscal_year=2021 THEN product_code END) AS unique_products_2021
FROM fact_sales_monthly)
SELECT 
    unique_products_2020,unique_products_2021, 
    ROUND((unique_products_2021 - unique_products_2020 ) * 100/unique_products_2020,2) AS percentage_chg  
FROM unique_prod_cnt

#Task 3
Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
2 fields, 
segment 
product_count

#Answer

SELECT segment, COUNT(DISTINCT(product_code)) AS product_count FROM dim_product
GROUP BY segment
ORDER BY product_count DESC ;

#Task 4
Follow-up: Which segment had the most increase in unique products in 
2021 vs 2020? The final output contains these fields, 
segment 
product_count_2020 
product_count_2021 
difference 

#Answer

WITH uni_prod_cnt AS (
SELECT p.segment,
    COUNT(DISTINCT CASE WHEN fiscal_year=2020 THEN s.product_code END) AS uni_product_count_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year=2021 THEN s.product_code END) AS uni_product_count_2021
FROM
fact_sales_monthly s
JOIN dim_product p 
ON s.product_code=p.product_code 
GROUP BY 
p.segment )
SELECT *, (uni_product_count_2021 - uni_product_count_2020) AS difference FROM uni_prod_cnt ORDER BY difference DESC


#Task 5
Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code 
product 
manufacturing_cost

#Answer
SELECT 
m.product_code,
p.product,
m.cost_year,
m.manufacturing_cost
FROM fact_manufacturing_cost m  
JOIN dim_product p
ON m.product_code=p.product_code
WHERE manufacturing_cost IN (
    (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost),
    (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost))
ORDER BY manufacturing_cost DESC

#Task 6
Generate a report which contains the top 5 customers who received an 
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
Indian  market. The final output contains these fields, 
customer_code 
customer 
average_discount_percentage 

#Answer
SELECT 
i.customer_code, 
c.customer,
AVG(i.pre_invoice_discount_pct) AS average_discount_percentage 
FROM fact_pre_invoice_deductions i
JOIN
dim_customer c
ON
i.customer_code=c.customer_code
WHERE i.fiscal_year=2021 AND c.market="india"
GROUP BY c.customer,i.customer_code
ORDER BY average_discount_percentage  DESC
LIMIT 5

#Task 7
Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions. 
The final report contains these columns: 
Month 
Year 
Gross sales Amount 

#Answer
SELECT
MONTH(s.date) AS month_no,
MONTHNAME(s.date) AS month_name,
YEAR(s.date) AS f_year,
CONCAT(ROUND(SUM(s.sold_quantity * g.gross_price)/1000000,2),'M') AS Gross_sales_Amount
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON s.product_code=g.product_code 
JOIN dim_customer c
ON c.customer_code=s.customer_code
WHERE c.customer="Atliq Exclusive"
GROUP BY month_no,month_name,f_year

#Task 8
In which quarter of 2020, got the maximum total_sold_quantity? The final 
output contains these fields sorted by the total_sold_quantity, 
Quarter 
total_sold_quantity 

#Answer
WITH cte1 AS (
SELECT 
    date,
    MONTH(DATE_ADD(date,INTERVAL 4 MONTH)) AS fiscal_month,
    fiscal_year,
    sold_quantity
FROM fact_sales_monthly
)
SELECT 
    CASE
        WHEN fiscal_month BETWEEN 1 AND 3 THEN 'Q1'
        WHEN fiscal_month BETWEEN 4 AND 6 THEN 'Q2'
        WHEN fiscal_month BETWEEN 7 AND 9 THEN 'Q3'
        WHEN fiscal_month BETWEEN 10 AND 12 THEN 'Q4'
	END AS Quarter,
    CONCAT(ROUND(SUM(sold_quantity)/1000000,2),'M') AS total_sold_quantity_mill
    FROM cte1 WHERE fiscal_year=2020 GROUP BY Quarter ORDER BY total_sold_quantity_mill DESC

# TASK 9
Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?  The final output  contains these fields, 
channel 
gross_sales_mln 
percentage 

# Answer
WITH cte1 AS (
SELECT c.channel AS channel, 
SUM(g.gross_price * s.sold_quantity) AS gross_sale
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON s.product_code=g.product_code
JOIN dim_customer c
ON c.customer_code=s.customer_code 
WHERE s.fiscal_year=2021 
GROUP BY c.channel
)
SELECT
channel,
CONCAT(ROUND(gross_sale/1000000,2),'M') AS gross_sales_mln,
ROUND(gross_sale/ SUM(gross_sale) OVER(),4)  * 100 AS percentage
FROM cte1 
ORDER BY percentage DESC

# Task 10
 Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these 
fields, 
division 
product_code 
product 
total_sold_quantity 
rank_order

# Answer
WITH cte1 AS (
SELECT 
p.division,
p.product_code,
p.product,
SUM(s.sold_quantity) AS total_sold_quantity,
row_number() OVER(partition by p.division order by SUM(s.sold_quantity) DESC ) AS rank_order
FROM fact_sales_monthly s
JOIN dim_product p
ON p.product_code=s.product_code
WHERE s.fiscal_year=2021
GROUP BY 
 p.division,p.product_code,p.product
 )
 SELECT * FROM cte1 WHERE rank_order IN(1,2,3)
