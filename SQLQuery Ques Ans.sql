/*Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
business in the  APAC  region. 
*/
--Question-1

select market
from dim_customer
where customer= 'Atliq Exclusive' and region = 'APAC'
group by market
order by market

----------------------------------------------------------------------------------------------------
--Question-2
/*  What is the percentage of unique product increase in 2021 vs. 2020? The 
final output contains these fields, 
unique_products_2020 
unique_products_2021 
percentage_chg */

with xoxo as (
select count(distinct product_code) as A
from fact_sales_monthly
where fiscal_year = 2021 ), 
yoyo as (
select count(distinct product_code) as B
from fact_sales_monthly
where fiscal_year = 2020 )    
select yoyo.B as unique_products_2020,xoxo.A as unique_products_2021,
round(((A-B)*100/B),2) as percentage_chg
from xoxo
inner join yoyo on 1=1

-------------------------------------------------------------------------------------------------
--Question-3

/*Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
2 fields, 
segment 
product_count  */

select segment, count(distinct product_code) as product_count 
from dim_product
group by segment
order by product_count desc

---------------------------------------------------------------------------------------------------------
--Question-4
/* Follow-up: Which segment had the most increase in unique products in 
2021 vs 2020? The final output contains these fields, 
segment 
product_count_2020 
product_count_2021 
difference */

with t_products as (
select segment, fiscal_year, count(distinct dp.product_code) as total_products
from fact_sales_monthly fs
left join dim_product dp on fs.product_code = dp.product_code
group by segment, fiscal_year)

select a.segment, a.total_products as unique_products_2020,
b.total_products as unique_products_2021, b.total_products - a.total_products as difference
--(b.total_products-a.total_products)/a.total_products*100 as percentage_chg
from t_products a
inner join t_products b on  a.segment = b.segment AND a.fiscal_year = 2020 
AND b.fiscal_year = 2021
order by difference desc

---------------------------------------------------------------------------------------------
--Question-5
/*  Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code 
product 
manufacturing_cost */

select d2.product_code,d1.product,d2.manufacturing_cost
from dim_product d1
inner join fact_manufacturing_cost d2 on d1.product_code = d2.product_code
where manufacturing_cost IN (
select max(manufacturing_cost) from fact_manufacturing_cost
union all
select min(manufacturing_cost) from fact_manufacturing_cost
)
order by manufacturing_cost desc

-------------------------------------------------------------------------------------------------------
--Question-06
/*  Generate a report which contains the top 5 customers who received an 
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
Indian  market. The final output contains these fields, 
customer_code 
customer 
average_discount_percentage */

with cte as (
select customer_code,avg(pre_invoice_discount_pct) as A
from fact_pre_invoice_deductions
where fiscal_year = 2021
group by customer_code ),
cte2 as (
select customer_code,customer
from dim_customer
where market = 'India')
select top 5 c2.customer_code,c2.customer,round(c1.A,4)*100 as average_discount_percentage
from cte c1
inner join cte2 c2 on c1.customer_code=c2.customer_code
order by average_discount_percentage desc

---------------------------------------------------------------------------------------------------------
--Question-7

/* Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions. 
The final report contains these columns: 
Month 
Year 
Gross sales Amount */

select * from fact_sales_monthly
select * from fact_gross_price
select * from dim_customer

select datepart(year,c1.date) as Year, datepart(Month,c1.date) as Month, round(sum(c1.sold_quantity*c2.gross_price),2) as Gross_sales_Amount
from fact_sales_monthly c1
inner join fact_gross_price c2 on c1.product_code = c2.product_code --and c1.fiscal_year = c2.fiscal_year
inner join dim_customer c3 on c3.customer_code = c1.customer_code
where c3.customer = 'Atliq Exclusive'
group by datepart(year,date), datepart(Month,date)
order by datepart(year,date), datepart(Month,date)

/* select distinct date from fact_sales_monthly
order by date   */

--------------------------------------------------------------------------------------------------------------
--Question-8
/*  In which quarter of 2020, got the maximum total_sold_quantity? The final 
output contains these fields sorted by the total_sold_quantity, 
Quarter 
total_sold_quantity */

SELECT CASE WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then 1  
            WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then 2
            WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then 3
            WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then 4
            END AS Quarters, SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
ORDER BY total_sold_quantity DESC

----------------------------------------------------------------------------------------------------------
--Question-9 
/* Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?  The final output  contains these fields, 
channel 
gross_sales_mln 
percentage */

select * from fact_gross_price
select * from fact_sales_monthly
select * from dim_customer

with cte as (
select c1.channel,sum(c2.sold_quantity*c3.gross_price/1000000) as gross_sales_mln
from dim_customer c1
inner join fact_sales_monthly c2 on c1.customer_code=c2.customer_code
inner join fact_gross_price c3 on c3.product_code=c2.product_code --and c2.fiscal_year=c3.fiscal_year
where c2.fiscal_year=2021
group by c1.channel )
select concat(gross_sales_mln,' M'), concat(round(gross_sales_mln * 100 / (select sum(gross_sales_mln) from cte),2), ' %') as pct_contributions
from cte

---------------------------------------------------------------------------------------------------------------
--Question-10
/*  Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these 
fields, 
division 
product_code 
product 
total_sold_quantity 
rank_order    */

select * from dim_product
select * from fact_sales_monthly

with ranked_prod as (
select d1.product,d1.division,d2.product_code,sum(d2.sold_quantity) as total_sold_quantity,
rank()over(partition by d1.division order by sum(d2.sold_quantity) desc) as rank_order
from dim_product d1
inner join fact_sales_monthly d2 on d1.product_code = d2.product_code
where d2.fiscal_year = 2021
group by d1.product,d1.division,d2.product_code )
select * from ranked_prod
where rank_order <=3

---------------------------------------------------------------------------------------------------------
