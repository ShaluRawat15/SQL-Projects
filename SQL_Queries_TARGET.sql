/*1-Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset:


1.1- Data type of all columns in the "customers" table.*/

select column_name, data_type
from `Target.INFORMATION_SCHEMA.COLUMNS`
where table_name = 'customers';


/* 1.2- Get the time range between which the orders were placed. */

SELECT MIN(order_purchase_timestamp) AS min_purchase_time,
MAX(order_purchase_timestamp) AS max_purchase_time
FROM `Target.orders`;


/* 1.3-  Count the Cities & States of customers who ordered during the given period.

Let's take the given period is the time range in above question.*/

SELECT COUNT(DISTINCT customer_state) AS num_states,COUNT(DISTINCT customer_city) AS num_cities
FROM `Target.customers` c
left join `Target.orders` o
on c.customer_id=o.customer_id
where order_purchase_timestamp between (select min(order_purchase_timestamp)from `Target.orders`)
AND (select max(order_purchase_timestamp)from `Target.orders`)

---------------------------------------------------------------------------------------------------------------------------



/* 2-In-depth Exploration:

2.1- Is there a growing trend in the no. of orders placed over the past years?*/

select extract(year from order_purchase_timestamp) as year,count(*) as no_of_orders
from `Target.orders`
group by 1
order by 1

/* Insights- Yes, there is a growing trend in the number of orders over the years.



2.2- Can we see some kind of monthly seasonality in terms of the no. of orders being placed?*/

select extract(month from order_purchase_timestamp) as month,count(*) as no_of_orders
from `Target.orders`
group by 1
order by 1

/* Insights- May, July and August have high numbers of orders.


2.3- During what time of the day, do the Brazilian customers mostly place their orders? */

select  case when extract(hour from order_purchase_timestamp) between 0 and 6 then 'Dawn'
when extract(hour from order_purchase_timestamp) between 7 and 12 then 'Mornings'
when extract(hour from order_purchase_timestamp) between 13 and 18 then 'Afternoon'
when extract(hour from order_purchase_timestamp) between 19 and 23 then 'Night'
end as time_of_the_day, count(*) as no_of_orders
from `Target.orders`
group by time_of_the_day
order by no_of_orders desc

/* Insights- During the afternoon, Brazilian customers mostly place their orders.


----------------------------------------------------------------------------------------------------------------



3. Evolution of E-commerce orders in the Brazil region:

3.1-Get the month on month no. of orders placed in each state. */

select c.customer_state as state,
extract(month from o.order_purchase_timestamp) as month,count(*) as no_of_orders
from `Target.orders` o
left join `Target.customers` c  
on o.customer_id=c.customer_id
group by 1,2
order by 1,2

/* Insights- SP has the highest number of orders in almost every month.



3.2-How are the customers distributed across all the states? */

select customer_state as state, count(distinct customer_id) as no_of_customer
from `Target.customers`
group by 1
order by 2 desc

/* Insights- Sp has the highest number of customers as well as the highest number of orders.


----------------------------------------------------------------------------------------------------------------



4.Impact on Economy: Analyse the money movement by e-commerce by looking at order prices, freight and others.
 

4.1- Get the % increase in the cost of orders from 2017 to 2018 (include months between Jan to Aug only). */

with orders_2017_2018 as(
  select *
  from(
    select
    extract(year from o.order_purchase_timestamp)as purchase_year,
    extract(month from o.order_purchase_timestamp)as purchase_month,
    round(sum(p.payment_value),2) as total_pay
    from `Target.orders` as o
    left join `Target.payments` as p
    on o.order_id = p.order_id
    group by 1,2
    order by 1,2
  )
  where purchase_year IN (2017, 2018)AND purchase_month BETWEEN 1 AND 8
)
select round(((sum(case when purchase_year = 2018 then total_pay end) -
sum(case when purchase_year = 2017 then total_pay end)) /
sum(case when purchase_year = 2017 then total_pay end) * 100),3) as cost_increase_percentage
from orders_2017_2018



/* 4.2- Calculate the Total & Average value of order price for each state. */

select c.customer_state as state, round(sum(p.price),2) as total_price,
round(avg(p.price),2) as avg_price
from `Target.customers` as c
left join `Target.orders` as o
on c.customer_id = o.customer_id
left join `Target.payments` as p
on o.order_id=p.order_id
group by 1
order by 2



/*4.3-  Calculate the Total & Average value of order freight for each state. */

select c.customer_state,
round(sum(oi.freight_value),2) as total_order_freight,
round(avg(oi.freight_value),2) as avg_order_freight
from `Target.customers` as c
join `Target.orders` as o
on c.customer_id = o.customer_id
join `Target.order_items` as oi
on o.order_id = oi.order_id
group by 1
order by 1


---------------------------------------------------------------------------------------------------------------------------



/* 5- Analysis based on sales, freight and delivery time.


5.1- Find the no. of days taken to deliver each order from the orderâ€™s purchase date as delivery time. */

select order_id,
timestamp_diff (order_delivered_customer_date, order_purchase_timestamp, DAY) as delivery_time,
timestamp_diff (order_estimated_delivery_date, order_delivered_customer_date, DAY) as delivery_difference
from `Target.orders`


/* 5.2-Find out the top 5 states with the highest & lowest average freight value. */

with order_freight as (
  select o.order_id,c.customer_state as state, oi.freight_value
  from`Target.orders` as o
  join`Target.order_items` as oi
  on o.order_id = oi.order_id
  join `Target.customers` as c
  on o.customer_id = c.customer_id
)
select state,round(avg(freight_value),2) AS highest_avg_freight
from order_freight
group by 1
order by 2 desc
limit 5
select state,round(avg(freight_value),2) as lowest_avg_freight
from order_freight
group by 1
order by 2
limit 5

/* Insights- Freight cost can be reduced by collaborating with different carriers and fulfilment centres, practising cost-saving strategies, and working on packaging departments.



5.3-Find out the top 5 states with the highest & lowest average delivery time.*/

with delivery_times as (
  select customer_state as state,
  round(avg(date_diff(order_delivered_carrier_date,order_purchase_timestamp, DAY)),2) as avg_delivery_time
  from `Target.customers` c
  join `Target.orders` o  
  on c.customer_id=o.customer_id
  where order_status = 'delivered'
  group by 1
)
select state,avg_delivery_time
from delivery_times
order by 2 DESC
LIMIT 5
select state,avg_delivery_time
from delivery_times
order by 2
limit 5


/* 5.4- Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.*/

select c.customer_state as state,
round(avg(date_diff(order_estimated_delivery_date, order_delivered_customer_date, DAY)),2) as delivery_difference
from `Target.orders` as o
join `Target.customers` as c
on o.customer_id = c.customer_id
where order_status = 'delivered'
group by 1
order by 2 desc
limit 5

/*5.3 & 5.4-Insights-  Average difference in days in above result is between 16-20 days. We need to focus on optimising the CORRECT estimated date because some customers won't even place an order if they see such a long estimated period of delivery. This way we can also boost our number of orders  also if we provide an almost exact estimated date and this also has an impact on customer satisfaction also.


---------------------------------------------------------------------------------------------------------------------------



6-Analysis based on the payments:

6.1-Find the month on month no. of orders placed using different payment types.*/

select p.payment_type,
extract(month from o.order_purchase_timestamp) as month, count(distinct o.order_id) as order_count
from `Target.orders` o
join `Target.payments` p
on o.order_id=p.order_id
group by 1,2
order by 3 desc

/*The most popular payment type is through credit cards. Least popular are through vouchers and debit cards, we can offer some exciting discounts or offers to customers during peak time for increasing no of orders.


6.2- Find the no. of orders placed on the basis of the payment instalments that have been paid. */

select payment_installments,
count(distinct order_id) as order_count
from `Target.payments`
group by 1
order by 1


/*Insights- It can be noticed that the majority of orders have a low number of payment instalments, this indicates that customers prefer to pay upfront or in fewer instalments. */


