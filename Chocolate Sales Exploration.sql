-- EXPLORING INDIVIDUAL TABLES --

-- For customers_st --
select * from customers_st
;

-- Checking the age bracket of the coffee drinkers
select min(age), max(age) from customers_st
order by 1                                           
;

/* Creating an age group name column, having: Young adult (18-35), 
		Middle age adult (36-64),
        Seior adult (>= 65)  */
ALTER TABLE customers_st
ADD age_group varchar(20)
;

UPDATE customers_st
SET age_group = (
	select case when age between 18 and 35 then "Youth"
				when age between 36 and 64 then "Adult"
				else "Senior" end as "age_group"
);


-- Age group distribution
select age_group, count(age_group)
from customers_st
group by age_group                         
;

-- Gender distribution 
select gender, count(gender)
from customers_st
group by gender                              
;

-- Difference between the both genders
select 25242 - 24758 as difference              
;

-- Age group distribution across gender
select distinct gender, age_group, count(age_group) 
from customers_st 
group by 1,2
order by 3 desc                                       
;

-- Distribution of the Loyalty members (1) of the brand VS the Non-loyalty members (0)
select distinct loyalty_member, count(loyalty_member) 
from customers_st 
group by 1
;

-- Difference between the members
select 25104 - 24896 as difference                    
;

-- Loyalty memebers distribution by gender
select distinct gender, loyalty_member, count(loyalty_member) 
from customers_st 
group by 1,2
order by 3 desc                                        
;

-- For products_st --
select * from products_st
;

-- Total number of different types of Chocolate
select count(distinct product_name) no_of_products from products_st              
;

-- For sales_st --
select * from sales_st
;

-- The first and the last order dates from 2023-2024
select min(order_date), max(order_date)
from sales_st                                     
;

-- Verifying the accuracy of the numerical columns
WITH cte_main as 
(
-- checking for the revenue column first
select trim(quantity), trim(unit_price), trim(discount), trim(cost) as existing_cost, 
    trim(revenue) as existing_revenue,
	cast(trim(quantity) * trim(unit_price) * (1 - trim(discount)) as decimal (10, 2)) as calculated_revenue,                -- Making the output have 2 decimal place
    case when trim(revenue)= cast(trim(quantity) * trim(unit_price) * (1 - trim(discount))as decimal (10, 2)) then "correct" else "error" end as revenue_status,
    trim(profit) as existing_profit
from sales_st
), error_fetch as 
(
-- Then, using the calculated revenue to solve for profit using CTE
select *, 
	cast(calculated_revenue - existing_cost as decimal(10, 2)) as calculated_profit,
	case when existing_profit= cast(calculated_revenue - existing_cost as decimal(10, 2)) then "correct" else "error" end as profit_status
from cte_main 
)
-- Using a second CTE to show incorrect values compared to the existing values
select * from error_fetch
where revenue_status= "error" or profit_status= "error"
;             


-- Changing the column datatypes to contain 2 decimal places
alter table sales_st
modify column revenue decimal(10, 2)
;

alter table sales_st
modify column profit decimal(10, 2)
;

-- Updating the revenue and profit columns with the correct calculated values at where necessary
UPDATE sales_st
SET revenue= cast(trim(quantity) * trim(unit_price) * (1 - trim(discount)) as decimal (10, 2)),
	profit= cast((trim(quantity) * trim(unit_price) * (1 - trim(discount))) - trim(cost) as decimal(10, 2))  
where  revenue <> cast(trim(quantity) * trim(unit_price) * (1 - trim(discount)) as decimal (10, 2))
  or   profit <> cast((trim(quantity) * trim(unit_price) * (1 - trim(discount))) - trim(cost) as decimal(10, 2))  
;

select 	* from sales_st                      
;

-- Total number of orders made
select count(distinct order_id) from sales_st                   
;

-- Total number of Chocolates sold
select sum(quantity) from sales_st                              
;

-- Total Cost of Production, Total Revenue, Total Profit  & Net Profit Margin
with totals as 
(
select round(sum(cost), 2) as total_cost,round(sum(revenue), 2) as total_revenue, round(sum(profit), 2) as total_profit
from sales_st
)
select *, round((total_profit / total_revenue) * 100, 2) as profit_margin
from totals
;	   


-- Monthly sales & Profitability trends
select *, round((sum(monthly_profit) / sum(monthly_revenue)) * 100, 2) as monthly_profit_margin
from (
select date_format(order_date, '%Y-%m') as sales_month, count(quantity) as total_order, round(sum(revenue), 2) as monthly_revenue,
round(sum(profit), 2) as monthly_profit
from sales_st group by 1 order by 1
) mon  
group by 1               
;

-- Totals for each Year
select YEAR(order_date), round(sum(cost), 2) as total_cost,round(sum(revenue), 2) as total_revenue, round(sum(profit), 2) as total_profit
from sales_st
group by 1            
;

-- Order Dates with the Least and the Most Buys
With purchase_per_date as 
(
-- Checking number of buys across dates
select order_date, count(order_id) as total_purchase
from sales_st group by 1
)
-- Finding the date with the least order
select order_date, total_purchase, 'Least Purchase' as purchase_type
from purchase_per_date
where total_purchase = (select min(total_purchase) from purchase_per_date)

UNION ALL

-- Finding the date with the highest order
select order_date, total_purchase, 'Most Purchase' as purchase_type
from purchase_per_date
where total_purchase = (select max(total_purchase) from purchase_per_date)
;                              


-- For stores_st --
select * from stores_st
;

select count(distinct store_id) from stores_st        
;

select distinct store_type from stores_st             
; 

--  Looking at city & country of the store               
select distinct country from stores_st 
;

select distinct city from stores_st  
; 


--  EXPLORING THE TABLES  --

-- Checking the position of some celebrations/holidays in relation to number of orders made on such days
with cte as 
(
select c.`date`, count(s.order_id) as num_of_orders,
	   row_number() over( order by count(s.order_id) desc) as row_num
from calendar_st c left join sales_st s on c.`date` = s.order_date
group by 1
) 
select * from cte 
where `date` IN ('2023-01-01','2024-01-01', '2023-02-14', '2024-02-14', '2023-05-01', '2023-10-01', '2023-12-25', '2024-12-25')
;                          


-- Finding if weekdays or weekends contribute to the want of buying chocolates.
select c.day_of_week, count(s.order_id) as num_of_orders
from calendar_st c left join sales_st s on c.`date` = s.order_date
group by 1
order by 2
;                                          

 -- Loyalty Members Number of Orders and the Revenue they generated
 select distinct c.loyalty_member, count(s.order_id) as num_of_purchase, round(sum(s.revenue), 2) as revenue_generated
 from sales_st s join customers_st c on s.customer_id = c.customer_id
 group by 1
 order by 2 desc
 ;                            
 
-- Customers Order Frequency and Revenue generated based on gender
select c.gender, count(s.order_id) as num_of_purchase, round(sum(s.revenue), 2) as revenue_generated
 from sales_st s join customers_st c on s.customer_id = c.customer_id
 group by 1
 order by 2 desc
 ;                           
 
-- Products vs Total Purchase, Revenue, & Profit 
select p.product_name, count(s.product_id) as total_order, sum(s.revenue) as total_revenue, sum(s.profit) as total_profit
from sales_st s join products_st p on s.product_id = p.product_id
group by 1
order by 3 desc
;                             
 
-- Category and Total Purchase by Age Group
select c.age_group, p.category, count(s.product_id) as total_order
from sales_st s join products_st p on s.product_id = p.product_id
				join customers_st c on s.customer_id = c.customer_id
group by 1, 2 
order by 3 desc                            
;                   

--  Chocolate Purchase Volume relativeness to Price
select p.product_name, p.brand, p.weight_g, s.unit_price, count(s.product_id) as total_order
from sales_st s join products_st p on s.product_id = p.product_id
				join customers_st c on s.customer_id = c.customer_id
group by 1, 2, 3, 4 
order by 5 desc     				
;                                    

-- Category Total Purchase
select p.category, count(s.product_id) as total_order
from sales_st s join products_st p on s.product_id = p.product_id
group by 1 
order by 2 desc
;

-- Brand Prices and Order
select p.brand, s.unit_price, count(s.product_id) as total_order
from sales_st s join products_st p on s.product_id = p.product_id
				join customers_st c on s.customer_id = c.customer_id
group by 1, 2 
order by 2 desc     				
;                             

select * from 
(
-- Each stores' Total sales, revenue and profit
select c.`year`, st.store_name, st.store_type, count(s.order_id) as total_sales, sum(s.revenue) as total_revenue, sum(s.profit) as total_profit
from calendar_st c join sales_st s on c.`date` = s.order_date
  				   join stores_st st on s.store_id = st.store_id
group by 1, 2, 3  Order by 4 desc
) yealy_performance
where store_name= 'Chocolate Store 42'
;


-- Store Types vs their Total Sales, Revenue and Profit
select st.store_type, count(s.order_id) as total_sales, sum(s.revenue) as total_revenue, sum(s.profit) as total_profit
from stores st join sales_st s on st.store_id = s.store_id
group by 1 
order by 3 desc
;                            

-- Including the Store Types
With top_sales as
-- Top 10 Chocolate Sales & Country
( 
select p.product_name, st.country, count(s.order_id) as total_sales
from products_st p join sales_st s on p.product_id = s.product_id
				   join stores_st st on s.store_id = st.store_id
group by 1, 2 order by 3 desc
Limit 10 
)
select t.*, st2.store_type 
from top_sales t left join stores_st st2 on t.country = st2.country
Limit 10
;


-- Country with the Most Profit & Revenue
select st.country, count(s.order_id) as total_sales, sum(s.revenue) as total_revenue, sum(s.profit) as total_profit
from stores_st st join sales_st s on st.store_id = s.store_id
group by 1 order by 2 desc
Limit 1
;

-- Cities and their top 2 most preferred Chocolates
select * from 
(
select st.city, p.product_name, count(s.order_id) as total_sales,
	row_number() over(partition by city order by count(s.order_id) desc) as row_num
from stores_st st join sales_st s on st.store_id = s.store_id
				  join products_st p on s.product_id = p.product_id
group by 1, 2 
) city_chocolates
where row_num in (1, 2)
;

