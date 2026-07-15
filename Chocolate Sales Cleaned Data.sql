-- DATA CLEANING --

-- 1. CREATING STAGING TABLES (TABLES TO USE INSTEAD OF THE RAW ONES)
CREATE TABLE calendar_st LIKE calendar ;
INSERT INTO calendar_st 
SELECT * FROM calendar
;

CREATE TABLE customers_st LIKE customers ;
INSERT INTO customers_st 
SELECT * FROM customers
;

CREATE TABLE products_st LIKE products ;
INSERT INTO products_st 
SELECT * FROM products
;

CREATE TABLE sales_st LIKE sales ;
INSERT INTO sales_st 
SELECT * FROM sales
;

CREATE TABLE stores_st LIKE stores ;
INSERT INTO stores_st 
SELECT * FROM stores
;

-- 2. REMOVE DUPLICATES
-- (Using ROW _NUMBER since there's no unique identifer indicated)

-- For calendar_st table --
with duplicate_cte as
(select *, 
row_number() over(partition by `date`, `year`, `month`, `day`, `week`, day_of_week) as row_num
from calendar_st
)
select * from duplicate_cte
where row_num > 1
;

-- For customers_st table --
with duplicate_cte as
(select *, 
row_number() over(partition by customer_id, age, gender, loyalty_member, join_date) as row_num
from customers_st
)
select * from duplicate_cte
where row_num > 1
;

-- For products_st table --
with duplicate_cte as
(select *, 
row_number() over(partition by product_id, product_name, brand, category, cocoa_percent, weight_g) as row_num
from products_st
)
select * from duplicate_cte
where row_num > 1
;

-- For sales_st table --
with duplicate_cte as
(select *, 
row_number() over(partition by order_id, order_date, product_id, store_id, customer_id, quantity, unit_price,
discount, revenue, cost, profit) as row_num
from sales_st
)
select * from duplicate_cte
where row_num > 1
;

-- For stores_st table --
with duplicate_cte as
(select *, 
row_number() over(partition by store_id, store_name, city, country, store_type) as row_num
from stores_st
)
select * from duplicate_cte
where row_num > 1
;

-- 3. STANDARDIZING DATA
-- (distinct, trim, datatype check)

-- For calendar_st --
ALTER TABLE calendar_st
modify column `date` DATE,
modify column `year` YEAR,
modify column `month` TINYINT UNSIGNED
;

-- For customers_st --
select distinct gender from customers_st
;
select distinct loyalty_member from customers_st
;
ALTER TABLE customers_st
modify column join_date DATE
;

-- For products_st --
select distinct product_name from products_st
order by 1
;
select distinct brand from products_st
order by 1
;
select distinct category from products_st
order by 1
;

-- For sales_st --
alter table sales_st
modify column order_date date
;

-- For stores_st --
select  distinct store_name from stores_st
;
select  distinct store_type from stores_st
order by 1
;

-- 4. Null / BLANK VALUES

-- For calendar_str --
select * from calendar_st
where `date` is null or ''
	and `year` is null or ''
    and `month` is null or ''
    and `day` is null or ''
    and `week` is null or ''
    and day_of_week is null or ''
;

-- For customers_st --
select * from customers_st
where customer_id is null or ''
	and age is null or ''
    and gender is null or ''
    and loyalty_member is null or ''
    and join_date is null or ''
;

-- For products_st --
select * from products_st
where product_id is null or ''
	and product_name is null or ''
    and brand is null or ''
    and category is null or ''
    and cocoa_percent is null or ''
    and weight_g is null or ''
;

-- For stores_st --
select * from stores_st
where store_name is null or ''
	and city is null or ''
    and country is null or ''
    and store_type is null or ''
;















