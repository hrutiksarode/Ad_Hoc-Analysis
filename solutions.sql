#Codebasics SQL Challenge
#Requests:


/*1. Provide the list of markets in which customer "Atliq Exclusive" 
operates its business in the APAC region. 
*/

select distinct(market) 
from dim_customer
where customer  = 'Atliq Exclusive' AND region = 'APAC'
order by market ASC;

/*
2.What is the percentage of unique product increase in 2021 vs. 2020?
The final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg 
*/

select up_2020 as unique_products_2020,up_2021 as unique_products_2021,
 round(((up_2021-up_2020)*100/up_2020),2) as percentage_chg
from
 (
	(select count(distinct(product_code)) as up_2020
	from fact_sales_monthly where fiscal_year = 2020) as A,

	(select count(distinct(product_code)) as up_2021
	from fact_sales_monthly where fiscal_year = 2021) as B
 )
 
/*
3.Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count 
*/

select segment, count(distinct(product_code)) as product_count 
from dim_product
group by segment 
order by product_count DESC; 

/*
4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference 
*/

with cte1 as
(select p.segment as col1, count(distinct(p.product_code)) as col2
from dim_product as p 
join fact_sales_monthly as s
on p.product_code = s.product_code
where s.fiscal_year  = 2020
group by p.segment
order by col2 DESC),
cte2 as 
(select p.segment as col3, count(distinct(p.product_code)) as col4
from dim_product as p 
join fact_sales_monthly as s
on p.product_code = s.product_code
where s.fiscal_year  = 2021
group by p.segment
order by col4 DESC)

select 
	col1 as segment,
    col2 as product_count_2020,
    col4 as product_count_2021,
    (col4-col2) as difference 
from
	cte1,cte2
where
	col1 = col3
order by difference DESC;

/*
5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost
*/

select p.product_code, p.product, m.manufacturing_cost
from dim_product as p
join fact_manufacturing_cost as m
on m.product_code = p.product_code
where manufacturing_cost in (
(select min(manufacturing_cost) from fact_manufacturing_cost),
(select max(manufacturing_cost) from fact_manufacturing_cost))
order by manufacturing_cost DESC;

/*
6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage
*/

SET sql_mode="";  
#temporarily disable the ONLY_FULL_GROUP_BY mode for the current session using it.

select c.customer_code,
c.customer,
concat(round(avg(pre_invoice_discount_pct)*100,2),' %') as average_discount_percentage
from dim_customer as c
join fact_pre_invoice_deductions as pre
on pre.customer_code = c.customer_code
where pre.fiscal_year = 2021 AND c.market = 'India'
group by c.customer_code
order by avg(pre_invoice_discount_pct) DESC
limit 5

/*
7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount
*/

select month(s.date) as Month,year(s.date) as Year,sum(s.sold_quantity*g.gross_price) as Gross_sales_amount
from fact_sales_monthly as s
join fact_gross_price as g
on g.product_code = s.product_code AND
   g.fiscal_year = s.fiscal_year
join dim_customer as c
on c.customer_code  = s.customer_code
where c.customer = 'Atliq Exclusive'
group by month(s.date),year(s.date)
order by Year,Month;

/*
8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity
*/

with cte1 as 
(select
	date,
    sold_quantity
from fact_sales_monthly
where fiscal_year = 2020)

select 
	case
		when month(date) in (09,10,11) then 'Q1'
        when month(date) in (12,01,02) then 'Q2'
        when month(date) in (03,04,05) then 'Q3'
        when month(date) in (06,07,08) then 'Q4'
	end as Quarter, sum(sold_quantity) as total_sold_quantity
from cte1
group by Quarter 
order by total_sold_quantity DESC;

/*
9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage
*/

with cte1 as 
(select 
	c.channel,
    round(sum((s.sold_quantity*g.gross_price)/1000000),2) as gross_sales_mln
from  fact_sales_monthly as s
join dim_customer as c
on c.customer_code = s.customer_code
join fact_gross_price as g
on g.product_code = s.product_code
where s.fiscal_year = 2021
group by c.channel)

select 
	*,
	round((gross_sales_mln*100/sum(gross_sales_mln) over() ),2) as percentage
from cte1;

/*
10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order
*/

with cte1 as 
(select 
	p.division,
	p.product_code,
    p.product,
    sum(s.sold_quantity) as total_sold_quantity
from dim_product as p
join fact_sales_monthly as s
on p.product_code = s.product_code
where s.fiscal_year = 2021
group by p.product_code,p.division,p.product),
cte2 as (select 
	*,
	 rank() over( partition by division order by total_sold_quantity DESC) as rank_order
from cte1)

select * from cte2
where rank_order <=3;
