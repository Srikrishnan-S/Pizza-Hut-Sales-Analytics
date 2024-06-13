/* how many customers per day */
SELECT date,
	COUNT(order_id) as customers_per_day
FROM Maven.dbo.orders
GROUP BY date
ORDER BY date

/* are there any peak hours 
hours with high order volume*/
-- overall hours vs traffic aggregated
SELECT DATEPART(hour, time) AS HourOfDay, COUNT(*) AS NumOrders
FROM maven.dbo.Orders
GROUP BY DATEPART(hour, time)
ORDER BY NumOrders DESC;

-- broken into dates
SELECT date, 
	DATEPART(hour, time) AS HourOfDay, 
	COUNT(*) AS NumOrders
FROM maven.dbo.Orders
GROUP BY date, DATEPART(hour, time)
ORDER BY date, NumOrders DESC;

/* how many pizzas per order & any best sellers?
1. Order_id gives date and time. Orders gives order_id and order_details_id...we need just order_id
2. counting order_id will miss quantities ordered (ie order_id 17 has 11 pizzas, counting order_id will net 10*/
--1-4 pizzas per order

--step 1. Pizzas per order

SELECT order_id,
	SUM(quantity) as total
FROM maven.dbo.order_details
--WHERE order_id = 17
GROUP BY order_id
ORDER BY order_id -- order_id 17 has 11 pizzas, we're on the right track! 

--step 1.1 Adding in date information by JOIN `orders` table
--I now have total quantity ordered listed by date and order_id =)
SELECT o.date,
	d.order_id,
	SUM(d.quantity) as total
FROM maven.dbo.order_details as d
JOIN maven.dbo.orders as o
ON d.order_id = o.order_id
--WHERE order_id = 17
GROUP BY d.order_id, o.date
ORDER BY d.order_id

-- step 2 best selling pizzas
-- by count
SELECT pizza_id,
	COUNT(pizza_id) as total_ordered
FROM maven.dbo.order_details
GROUP BY pizza_id
ORDER BY total_ordered DESC

-- step 2.2 I'd like to know the percentage of the pie per pizza_id ordered
-- total ordered: 48620 - I'm still learning, and want to verify % will be accurate
WITH total_count as (
	SELECT pizza_id,
		COUNT(pizza_id) as total_ordered
	FROM maven.dbo.order_details
	GROUP BY pizza_id
		)
SELECT SUM(total_ordered)
FROM total_count
-- back on track:
SELECT pizza_id,
       COUNT(pizza_id) AS total_ordered,
       ROUND(100 * COUNT(pizza_id) / SUM(COUNT(pizza_id)) OVER(), 2) AS percentage_sold
FROM maven.dbo.order_details
GROUP BY pizza_id
ORDER BY total_ordered DESC;
-- top 5 pizzas: big meat, thai chicken, five cheese, four cheese, classic deluxe

/* how much money was made this year? is there any seasonality to the sales?
1. `dbo.pizzas` holds pricing information
2. `dbo.order_details` holds quantity information
3. `dbo.orders` holds date information*/
--dates from 1/2015 thru 12/2015
-- for overall sales: quantity * price
-- for seasonality: sales over time (monthly)

-- sales per order per day
SELECT 
	o.date,
	d.order_id,
	SUM(d.quantity) as num_pizzas,
	SUM(p.price) as sales
FROM maven.dbo.pizzas as p
JOIN maven.dbo.order_details as d
ON d.pizza_id = p.pizza_id
JOIN maven.dbo.orders as o
ON o.order_id = d.order_id
GROUP BY o.date, d.order_id
ORDER BY o.date

-- sales per day

SELECT 
	o.date,
	SUM(d.quantity) as num_pizzas,
	ROUND(SUM(p.price),2) as sales
FROM maven.dbo.pizzas as p
JOIN maven.dbo.order_details as d
ON d.pizza_id = p.pizza_id
JOIN maven.dbo.orders as o
ON o.order_id = d.order_id
GROUP BY o.date
--HAVING SUM(d.quantity) >0 --verify if any days had no sales. 
ORDER BY o.date

-- sales per month (run from SELECT, using CTE for more diving below)

WITH monthly_sales as
(
SELECT 
	DATEPART(year,o.date) as year,
	DATEPART(month,o.date) as month,
	SUM(d.quantity) as num_pizzas,
	ROUND(SUM(p.price),2) as sales
FROM maven.dbo.pizzas as p
JOIN maven.dbo.order_details as d
ON d.pizza_id = p.pizza_id
JOIN maven.dbo.orders as o
ON o.order_id = d.order_id
GROUP BY DATEPART(month,o.date), DATEPART(year,o.date)
ORDER BY DATEPART(month,o.date)
)
-- now to find min and max sales over the year (use CTE above with query below, comment out ORDER BY above to run CTE)
SELECT
	year,
	MAX(sales) as max_sales,
	MIN(sales) as min_sales
FROM monthly_sales
GROUP BY year;
/* max sales: $71027.45 - July
 min sales: $62566.50 - October
 */

 -- annual sales: $801,944.70 with 49574 total pizzas sold
 SELECT 
	DATEPART(year,o.date) as year,
	SUM(d.quantity) as num_pizzas,
	ROUND(SUM(p.price),2) as sales
FROM maven.dbo.pizzas as p
JOIN maven.dbo.order_details as d
ON d.pizza_id = p.pizza_id
JOIN maven.dbo.orders as o
ON o.order_id = d.order_id
GROUP BY DATEPART(year,o.date)


 /* find the sales per pizza to see if changes are needed 
 we have the queries established with our top quantity pizzas and bottom
 we have sales figures. now we combine them */

SELECT 
	t.name as pizzas,
	--DATEPART(year,o.date) as year,
	--DATEPART(month,o.date) as month,
	SUM(d.quantity) as num_pizzas,
	ROUND(SUM(p.price),2) as sales
FROM maven.dbo.pizzas as p
JOIN maven.dbo.order_details as d
ON d.pizza_id = p.pizza_id
JOIN maven.dbo.orders as o
ON o.order_id = d.order_id
JOIN maven.dbo.pizza_types as t
ON t.pizza_type_id = p.pizza_type_id
GROUP BY t.name
ORDER BY ROUND(SUM(p.price),2) DESC

/*an overview shows Brie Carre pizza severely lags in quantity sold and overall sales
Sold: 490 for $11,352
Next is the Green Garden Pizza
Sold: 997 for $13819.50
The top is the Thai Chicken
Sold 2371 for $42,332.25

