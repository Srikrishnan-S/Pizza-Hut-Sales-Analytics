-- PIZZA SALES ANALYTICS :
-- =======================================================================================

-- SELECT ALL
-- =======================================================================================

-- 1) Order_Details:
SELECT * FROM Pizza_Sales.dbo.order_details;

-- 2) Orders:
SELECT * FROM Pizza_Sales.dbo.orders;

-- 3) Pizzas:
SELECT * FROM Pizza_Sales.dbo.pizzas;

-- 4) Pizza_Types:
SELECT * FROM Pizza_Sales.dbo.pizza_types;

-- Exploraoty Data Analysis:
SELECT COUNT(DISTINCT pizza_type) FROM Pizza_Sales.dbo.order_details

SELECT COUNT(DISTINCT name) FROM Pizza_Sales.dbo.pizza_types;

SELECT OD.pizza_type, 
       PT.name
FROM Pizza_Sales.dbo.order_details AS OD
LEFT JOIN Pizza_Sales.dbo.pizzas AS P
ON OD.pizza_id = P.pizza_id
LEFT JOIN Pizza_Sales.dbo.pizza_types AS PT
ON P.pizza_type_id = PT.pizza_type_id
-- =======================================================================================

-- TRANSFORMATIONS:
-- =======================================================================================

-- 1) Rename Column: item_total to total_price:

EXEC sp_rename 'order_details.item_total', 'total_price', 'COLUMN';

-- =======================================================================================

-- 2) Remove Ingredient Column:

-- ALTER TABLE pizza_types
-- DROP COLUMN ingredients;

-- Im planning to delete this column in Power Bi 

-- =======================================================================================

-- METRICS:
-- =======================================================================================

-- 1) Total Sales / Revenue:

SELECT ROUND(SUM(total_price), 2) 
AS Total_Revenue
FROM Pizza_Sales.dbo.order_details;

-- =======================================================================================

-- 2) Total Number of Orders:

SELECT COUNT(DISTINCT order_id) 
AS Total_Number_of_Orders 
FROM Pizza_Sales.dbo.orders;

-- =======================================================================================

-- 3) Total Quanitity Sold:

SELECT SUM(quantity) 
AS Number_of_Quanitity_Sold
FROM Pizza_Sales.dbo.order_details;

-- =======================================================================================

-- 4) Average Order Value:

SELECT ROUND((SUM(total_price)/COUNT(DISTINCT order_id)), 2)
AS Average_Order_Value
FROM Pizza_Sales.dbo.order_details;

-- =======================================================================================

-- 5) Average Pizza per Order:

SELECT CEILING(SUM(quantity)/COUNT(DISTINCT order_id))
AS Average_Pizza_per_Order
FROM Pizza_Sales.dbo.order_details;

-- =======================================================================================

-- 6) SUMMARY METRICS: 

SELECT ROUND(SUM(OD.quantity * P.price), 2) AS Total_Revenue, 
       COUNT(DISTINCT O.order_id) AS Total_Orders,
       SUM(OD.quantity) AS Total_Quantity_Sold,
       ROUND(SUM(OD.quantity * P.price)/COUNT(DISTINCT O.order_id), 2) AS Average_Order_Value,
       CEILING(SUM(OD.quantity)/COUNT(DISTINCT O.order_id)) AS Average_Pizza_per_Order
FROM Pizza_Sales.dbo.order_details AS OD
LEFT JOIN Pizza_Sales.dbo.pizzas AS P
ON OD.pizza_id = P.pizza_id
LEFT JOIN Pizza_Sales.dbo.orders AS O
ON O.order_id = OD.order_id

-- =======================================================================================

-- 7) Metrics by Quarter:

WITH Pizza_Tables AS
(
SELECT O.order_id AS order_id,
       P.price AS price, 
       OD.quantity AS quantity, 
       DATEPART(QUARTER, O.date) AS quarters
FROM Pizza_Sales.dbo.order_details AS OD
LEFT JOIN Pizza_Sales.dbo.orders AS O
ON OD.order_id = O.order_id
LEFT JOIN Pizza_Sales.dbo.pizzas AS P
ON OD.pizza_id = P.pizza_id
)
SELECT quarters, 
       ROUND(SUM(price * quantity), 2) AS Total_Revenue,
       COUNT(DISTINCT order_id) AS Total_Orders,
       SUM(quantity) AS Total_Quantities,
       ROUND(SUM(price * quantity)/COUNT(DISTINCT order_id), 2) AS Average_Order_Value,
       CEILING(SUM(quantity)/COUNT(DISTINCT order_id)) AS Average_Pizza_per_Order
FROM Pizza_Tables
GROUP BY quarters
ORDER BY quarters ASC;

-- =======================================================================================

-- 8) Metrics by Months:

WITH Pizza_Tables AS
(
SELECT O.order_id AS order_id,
       P.price AS price, 
       OD.quantity AS quantity, 
       MONTH(O.date) AS month_num,
       DATENAME(MONTH, O.date) AS months
FROM Pizza_Sales.dbo.order_details AS OD
LEFT JOIN Pizza_Sales.dbo.orders AS O
ON OD.order_id = O.order_id
LEFT JOIN Pizza_Sales.dbo.pizzas AS P
ON OD.pizza_id = P.pizza_id
)
SELECT months, 
       month_num,
       ROUND(SUM(price * quantity), 2) AS Total_Revenue,
       COUNT(DISTINCT order_id) AS Total_Orders,
       SUM(quantity) AS Total_Quantities,
       ROUND(SUM(price * quantity)/COUNT(DISTINCT order_id), 2) AS Average_Order_Value,
       CEILING(SUM(quantity)/COUNT(DISTINCT order_id)) AS Average_Pizza_per_Order
FROM Pizza_Tables
GROUP BY months, month_num
ORDER BY month_num ASC;

-- =======================================================================================

-- 9) Metrics by Weekday or Weekend:

WITH Pizza_Tables AS
(
SELECT O.order_id AS order_id,
       P.price AS price, 
       OD.quantity AS quantity, 
       (CASE 
        WHEN DATEPART(WEEKDAY, O.date) <= 5 
        THEN 'Weekday' 
        ELSE 'Weekend'
        END) AS weekday_or_weekend
FROM Pizza_Sales.dbo.order_details AS OD
LEFT JOIN Pizza_Sales.dbo.orders AS O
ON OD.order_id = O.order_id
LEFT JOIN Pizza_Sales.dbo.pizzas AS P
ON OD.pizza_id = P.pizza_id
)
SELECT weekday_or_weekend, 
       ROUND(SUM(price * quantity), 2) AS Total_Revenue,
       COUNT(DISTINCT order_id) AS Total_Orders,
       SUM(quantity) AS Total_Quantities,
       ROUND(SUM(price * quantity)/COUNT(DISTINCT order_id), 2) AS Average_Order_Value,
       CEILING(SUM(quantity)/COUNT(DISTINCT order_id)) AS Average_Pizza_per_Order
FROM Pizza_Tables
GROUP BY weekday_or_weekend;

-- =======================================================================================

-- 10) Top 3 Pizza rank in Weekday and Weekend by Revenue: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        (CASE 
            WHEN DATEPART(WEEKDAY, O.date) <= 5 
            THEN 'Weekday' 
            ELSE 'Weekend'
         END) AS weekday_or_weekend
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        weekday_or_weekend,
        SUM(price * quantity) AS Total_Revenue,
        RANK() OVER (PARTITION BY weekday_or_weekend ORDER BY SUM(price * quantity) DESC) AS Revenue_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        weekday_or_weekend
)
SELECT 
    weekday_or_weekend,
    pizza_name,
    Total_Revenue,
    Revenue_Rank
FROM 
    Pizza_Revenue
WHERE 
    Revenue_Rank <= 3
ORDER BY 
    weekday_or_weekend, 
    Revenue_Rank;

-- =======================================================================================

-- 11) Top 3 Pizza rank in Weekday and Weekend by Orders: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        (CASE 
            WHEN DATEPART(WEEKDAY, O.date) <= 5 
            THEN 'Weekday' 
            ELSE 'Weekend'
         END) AS weekday_or_weekend
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        weekday_or_weekend,
        COUNT(DISTINCT order_id) AS Total_Orders,
        RANK() OVER (PARTITION BY weekday_or_weekend ORDER BY COUNT(DISTINCT order_id) DESC) AS Orders_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        weekday_or_weekend
)
SELECT 
    weekday_or_weekend,
    pizza_name,
    Total_Orders,
    Orders_Rank
FROM 
    Pizza_Revenue
WHERE 
    Orders_Rank <= 3
ORDER BY 
    weekday_or_weekend, 
    Orders_Rank;

-- =======================================================================================

-- 12) Top 3 Pizza rank in Weekday and Weekend by Quantities: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        (CASE 
            WHEN DATEPART(WEEKDAY, O.date) <= 5 
            THEN 'Weekday' 
            ELSE 'Weekend'
         END) AS weekday_or_weekend
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        weekday_or_weekend,
        SUM(quantity) AS Total_Quantities,
        RANK() OVER (PARTITION BY weekday_or_weekend ORDER BY SUM(quantity) DESC) AS Quantity_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        weekday_or_weekend
)
SELECT 
    weekday_or_weekend,
    pizza_name,
    Total_Quantities,
    Quantity_Rank
FROM 
    Pizza_Revenue
WHERE 
    Quantity_Rank <= 3
ORDER BY 
    weekday_or_weekend, 
    Quantity_Rank;       

-- =======================================================================================

-- 13) Top 3 Pizza rank in Weekday and Weekend by Avg_Order_Value: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        (CASE 
            WHEN DATEPART(WEEKDAY, O.date) <= 5 
            THEN 'Weekday' 
            ELSE 'Weekend'
         END) AS weekday_or_weekend
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        weekday_or_weekend,
        SUM(price * quantity) / COUNT(DISTINCT order_id) AS Avg_Order_Value,
        RANK() OVER (PARTITION BY weekday_or_weekend ORDER BY SUM(price * quantity) / COUNT(DISTINCT order_id) DESC) AS Avg_Order_Value_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        weekday_or_weekend
)
SELECT 
    weekday_or_weekend,
    pizza_name,
    Avg_Order_Value,
    Avg_Order_Value_Rank
FROM 
    Pizza_Revenue
WHERE 
    Avg_Order_Value_Rank <= 3
ORDER BY 
    weekday_or_weekend, 
    Avg_Order_Value_Rank;

-- =======================================================================================

-- 14) Top 3 Pizza rank in Weekday and Weekend by Avg_Pizza_per_Order: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        (CASE 
            WHEN DATEPART(WEEKDAY, O.date) <= 5 
            THEN 'Weekday' 
            ELSE 'Weekend'
         END) AS weekday_or_weekend
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        weekday_or_weekend,
        SUM(quantity) / COUNT(DISTINCT order_id) AS Avg_Pizza_per_Order,
        RANK() OVER (PARTITION BY weekday_or_weekend ORDER BY SUM(quantity) / COUNT(DISTINCT order_id) DESC) AS Avg_Pizza_per_Order_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        weekday_or_weekend
)
SELECT 
    weekday_or_weekend,
    pizza_name,
    Avg_Pizza_per_Order,
    Avg_Pizza_per_Order_Rank
FROM 
    Pizza_Revenue
WHERE 
    Avg_Pizza_per_Order_Rank <= 3
ORDER BY 
    weekday_or_weekend, 
    Avg_Pizza_per_Order_Rank;

-- =======================================================================================

-- 15) Metrics by Hours:

WITH Pizza_Tables AS
(
SELECT O.order_id AS order_id,
       P.price AS price, 
       OD.quantity AS quantity, 
       DATENAME(HOUR, O.time) AS time_hours
FROM Pizza_Sales.dbo.order_details AS OD
LEFT JOIN Pizza_Sales.dbo.orders AS O
ON OD.order_id = O.order_id
LEFT JOIN Pizza_Sales.dbo.pizzas AS P
ON OD.pizza_id = P.pizza_id
)
SELECT time_hours, 
       ROUND(SUM(price * quantity), 2) AS Total_Revenue,
       COUNT(DISTINCT order_id) AS Total_Orders,
       SUM(quantity) AS Total_Quantities,
       ROUND(SUM(price * quantity)/COUNT(DISTINCT order_id), 2) AS Average_Order_Value,
       CEILING(SUM(quantity)/COUNT(DISTINCT order_id)) AS Average_Pizza_per_Order
FROM Pizza_Tables
GROUP BY time_hours
ORDER BY time_hours;

-- =======================================================================================

-- 16) Top 3 Pizza rank in Hours by Revenue: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        DATEPART(HOUR, O.time) AS time_hours
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        time_hours,
        SUM(price * quantity) AS Total_Revenue,
        RANK() OVER (PARTITION BY time_hours ORDER BY SUM(price * quantity) DESC) AS Revenue_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        time_hours
)
SELECT 
    time_hours,
    pizza_name,
    Total_Revenue,
    Revenue_Rank
FROM 
    Pizza_Revenue
WHERE 
    Revenue_Rank <= 3
ORDER BY 
    time_hours, 
    Revenue_Rank;

-- =======================================================================================

-- 17) Top 3 Pizza rank in Hours by Orders: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        DATENAME(HOUR, O.time) AS time_hours
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        time_hours,
        COUNT(DISTINCT order_id) AS Total_Orders,
        RANK() OVER (PARTITION BY time_hours ORDER BY COUNT(DISTINCT order_id) DESC) AS Orders_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        time_hours
)
SELECT 
    time_hours,
    pizza_name,
    Total_Orders,
    Orders_Rank
FROM 
    Pizza_Revenue
WHERE 
    Orders_Rank <= 3
ORDER BY 
    time_hours, 
    Orders_Rank;

-- =======================================================================================

-- 18) Top 3 Pizza rank in Hours by Quantities: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        DATENAME(HOUR, O.time) AS time_hours
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        time_hours,
        SUM(quantity) AS Total_Quantities,
        RANK() OVER (PARTITION BY time_hours ORDER BY SUM(quantity) DESC) AS Quantity_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        time_hours
)
SELECT 
    time_hours,
    pizza_name,
    Total_Quantities,
    Quantity_Rank
FROM 
    Pizza_Revenue
WHERE 
    Quantity_Rank <= 3
ORDER BY 
    time_hours, 
    Quantity_Rank;       

-- =======================================================================================

-- 19) Top 3 Pizza rank in Hours by Avg_Order_Value: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        DATENAME(HOUR, O.time) AS time_hours
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        time_hours,
        SUM(price * quantity) / COUNT(DISTINCT order_id) AS Avg_Order_Value,
        RANK() OVER (PARTITION BY time_hours ORDER BY SUM(price * quantity) / COUNT(DISTINCT order_id) DESC) AS Avg_Order_Value_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        time_hours
)
SELECT 
    time_hours,
    pizza_name,
    Avg_Order_Value,
    Avg_Order_Value_Rank
FROM 
    Pizza_Revenue
WHERE 
    Avg_Order_Value_Rank <= 3
ORDER BY 
    time_hours, 
    Avg_Order_Value_Rank;

-- =======================================================================================

-- 20) Top 3 Pizza rank in Hours by Avg_Pizza_per_Order: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        DATENAME(HOUR, O.time) AS time_hours
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        time_hours,
        SUM(quantity) / COUNT(DISTINCT order_id) AS Avg_Pizza_per_Order,
        RANK() OVER (PARTITION BY time_hours ORDER BY SUM(quantity) / COUNT(DISTINCT order_id) DESC) AS Avg_Pizza_per_Order_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        time_hours
)
SELECT 
    time_hours,
    pizza_name,
    Avg_Pizza_per_Order,
    Avg_Pizza_per_Order_Rank
FROM 
    Pizza_Revenue
WHERE 
    Avg_Pizza_per_Order_Rank <= 3
ORDER BY 
    time_hours, 
    Avg_Pizza_per_Order_Rank;
  
-- =======================================================================================

-- 21) Metrics by Pizza Category:

WITH Pizza_Tables AS
(
SELECT O.order_id AS order_id,
       P.price AS price, 
       OD.quantity AS quantity, 
       PT.category AS pizza_category
FROM Pizza_Sales.dbo.order_details AS OD
LEFT JOIN Pizza_Sales.dbo.orders AS O
ON OD.order_id = O.order_id
LEFT JOIN Pizza_Sales.dbo.pizzas AS P
ON OD.pizza_id = P.pizza_id
LEFT JOIN Pizza_Sales.dbo.pizza_types AS PT
ON PT.pizza_type_id = P.pizza_type_id
)
SELECT pizza_category, 
       ROUND(SUM(price * quantity), 2) AS Total_Revenue,
       COUNT(DISTINCT order_id) AS Total_Orders,
       SUM(quantity) AS Total_Quantities,
       ROUND(SUM(price * quantity)/COUNT(DISTINCT order_id), 2) AS Average_Order_Value,
       CEILING(SUM(quantity)/COUNT(DISTINCT order_id)) AS Average_Pizza_per_Order
FROM Pizza_Tables
GROUP BY pizza_category;

-- =======================================================================================

-- 22) Top 3 Pizza rank in Pizza Category by Revenue: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        PT.category AS pizza_category
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        pizza_category,
        SUM(price * quantity) AS Total_Revenue,
        RANK() OVER (PARTITION BY pizza_category ORDER BY SUM(price * quantity) DESC) AS Revenue_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        pizza_category
)
SELECT 
    pizza_category,
    pizza_name,
    Total_Revenue,
    Revenue_Rank
FROM 
    Pizza_Revenue
WHERE 
    Revenue_Rank <= 3
ORDER BY  
    pizza_category,
    Revenue_Rank;

-- =======================================================================================

-- 23) Top 3 Pizza rank in Pizza Category by Orders: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        PT.category AS pizza_category
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        pizza_category,
        COUNT(DISTINCT order_id) AS Total_Orders,
        RANK() OVER (PARTITION BY pizza_category ORDER BY COUNT(DISTINCT order_id) DESC) AS Orders_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        pizza_category
)
SELECT 
    pizza_category,
    pizza_name,
    Total_Orders,
    Orders_Rank
FROM 
    Pizza_Revenue
WHERE 
    Orders_Rank <= 3
ORDER BY 
    pizza_category, 
    Orders_Rank;

-- =======================================================================================

-- 24) Top 3 Pizza rank in Pizza Category by Quantities: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        PT.category AS pizza_category
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        pizza_category,
        SUM(quantity) AS Total_Quantities,
        RANK() OVER (PARTITION BY pizza_category ORDER BY SUM(quantity) DESC) AS Quantity_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        pizza_category
)
SELECT 
    pizza_category,
    pizza_name,
    Total_Quantities,
    Quantity_Rank
FROM 
    Pizza_Revenue
WHERE 
    Quantity_Rank <= 3
ORDER BY 
    pizza_category, 
    Quantity_Rank;       

-- =======================================================================================

-- 25) Top 3 Pizza rank in Pizza Category by Avg_Order_Value: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        PT.category AS pizza_category
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        pizza_category,
        SUM(price * quantity) / COUNT(DISTINCT order_id) AS Avg_Order_Value,
        RANK() OVER (PARTITION BY pizza_category ORDER BY SUM(price * quantity) / COUNT(DISTINCT order_id) DESC) AS Avg_Order_Value_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        pizza_category
)
SELECT 
    pizza_category,
    pizza_name,
    Avg_Order_Value,
    Avg_Order_Value_Rank
FROM 
    Pizza_Revenue
WHERE 
    Avg_Order_Value_Rank <= 3
ORDER BY 
    pizza_category, 
    Avg_Order_Value_Rank;

-- =======================================================================================

-- 26) Top 3 Pizza rank in Pizza Category by Avg_Pizza_per_Order: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        PT.category AS pizza_category
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        pizza_category,
        SUM(quantity) / COUNT(DISTINCT order_id) AS Avg_Pizza_per_Order,
        RANK() OVER (PARTITION BY pizza_category ORDER BY SUM(quantity) / COUNT(DISTINCT order_id) DESC) AS Avg_Pizza_per_Order_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        pizza_category
)
SELECT 
    pizza_category,
    pizza_name,
    Avg_Pizza_per_Order,
    Avg_Pizza_per_Order_Rank
FROM 
    Pizza_Revenue
WHERE 
    Avg_Pizza_per_Order_Rank <= 3
ORDER BY 
    pizza_category, 
    Avg_Pizza_per_Order_Rank;

-- =======================================================================================

-- 27) Metrics by Sizes:

WITH Pizza_Tables AS
(
SELECT O.order_id AS order_id,
       P.price AS price, 
       OD.quantity AS quantity, 
       P.size as sizes
FROM Pizza_Sales.dbo.order_details AS OD
LEFT JOIN Pizza_Sales.dbo.orders AS O
ON OD.order_id = O.order_id
LEFT JOIN Pizza_Sales.dbo.pizzas AS P
ON OD.pizza_id = P.pizza_id
)
SELECT (CASE WHEN sizes = 'S' THEN 'Small'
       WHEN sizes = 'M' THEN 'Medium'
       WHEN sizes = 'L' THEN 'Large'
       WHEN sizes = 'XL' THEN 'Extra Large'
       ELSE 'Double Extra Large' END) AS pizza_sizes,
       ROUND(SUM(price * quantity), 2) AS Total_Revenue,
       COUNT(DISTINCT order_id) AS Total_Orders,
       SUM(quantity) AS Total_Quantities,
       ROUND(SUM(price * quantity)/COUNT(DISTINCT order_id), 2) AS Average_Order_Value,
       CEILING(SUM(quantity)/COUNT(DISTINCT order_id)) AS Average_Pizza_per_Order
FROM Pizza_Tables
GROUP BY sizes
ORDER BY (CASE WHEN sizes = 'S' THEN 1
       WHEN sizes = 'M' THEN 2
       WHEN sizes = 'L' THEN 3
       WHEN sizes = 'XL' THEN 4
       ELSE 5 END) ASC;

-- =======================================================================================

-- 28) Top 3 Pizza rank in Pizza Sizes by Revenue: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        (CASE WHEN P.size = 'S' THEN 'Small'
       WHEN P.size = 'M' THEN 'Medium'
       WHEN P.size = 'L' THEN 'Large'
       WHEN P.size = 'XL' THEN 'Extra Large'
       ELSE 'Double Extra Large' END) AS pizza_sizes
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        pizza_sizes,
        SUM(price * quantity) AS Total_Revenue,
        RANK() OVER (PARTITION BY pizza_sizes ORDER BY SUM(price * quantity) DESC) AS Revenue_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        pizza_sizes
)
SELECT 
    pizza_sizes,
    pizza_name,
    Total_Revenue,
    Revenue_Rank
FROM 
    Pizza_Revenue
WHERE 
    Revenue_Rank <= 3
ORDER BY  
    (CASE WHEN pizza_sizes = 'Small' THEN 1
       WHEN pizza_sizes = 'Medium' THEN 2
       WHEN pizza_sizes = 'Large' THEN 3
       WHEN pizza_sizes = 'Extra Large' THEN 4
       ELSE 5 END) ASC,
    Revenue_Rank;

-- =======================================================================================

-- 29) Top 3 Pizza rank in Pizza Sizes by Orders: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        (CASE WHEN P.size = 'S' THEN 'Small'
       WHEN P.size = 'M' THEN 'Medium'
       WHEN P.size = 'L' THEN 'Large'
       WHEN P.size = 'XL' THEN 'Extra Large'
       ELSE 'Double Extra Large' END) AS pizza_sizes
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        pizza_sizes,
        COUNT(DISTINCT order_id) AS Total_Orders,
        RANK() OVER (PARTITION BY pizza_sizes ORDER BY COUNT(DISTINCT order_id) DESC) AS Orders_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        pizza_sizes
)
SELECT 
    pizza_sizes,
    pizza_name,
    Total_Orders,
    Orders_Rank
FROM 
    Pizza_Revenue
WHERE 
    Orders_Rank <= 3
ORDER BY  
    (CASE WHEN pizza_sizes = 'Small' THEN 1
       WHEN pizza_sizes = 'Medium' THEN 2
       WHEN pizza_sizes = 'Large' THEN 3
       WHEN pizza_sizes = 'Extra Large' THEN 4
       ELSE 5 END) ASC,
    Orders_Rank;

-- =======================================================================================

-- 30) Top 3 Pizza rank in Pizza Sizes by Quantities: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        (CASE WHEN P.size = 'S' THEN 'Small'
       WHEN P.size = 'M' THEN 'Medium'
       WHEN P.size = 'L' THEN 'Large'
       WHEN P.size = 'XL' THEN 'Extra Large'
       ELSE 'Double Extra Large' END) AS pizza_sizes
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        pizza_sizes,
        SUM(quantity) AS Total_Quantities,
        RANK() OVER (PARTITION BY pizza_sizes ORDER BY SUM(quantity) DESC) AS Quantity_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        pizza_sizes
)
SELECT 
    pizza_sizes,
    pizza_name,
    Total_Quantities,
    Quantity_Rank
FROM 
    Pizza_Revenue
WHERE 
    Quantity_Rank <= 3
ORDER BY  
    (CASE WHEN pizza_sizes = 'Small' THEN 1
       WHEN pizza_sizes = 'Medium' THEN 2
       WHEN pizza_sizes = 'Large' THEN 3
       WHEN pizza_sizes = 'Extra Large' THEN 4
       ELSE 5 END) ASC,
    Quantity_Rank;      

-- =======================================================================================

-- 31) Top 3 Pizza rank in Pizza Sizes by Avg_Order_Value: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        (CASE WHEN P.size = 'S' THEN 'Small'
       WHEN P.size = 'M' THEN 'Medium'
       WHEN P.size = 'L' THEN 'Large'
       WHEN P.size = 'XL' THEN 'Extra Large'
       ELSE 'Double Extra Large' END) AS pizza_sizes
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        pizza_sizes,
        SUM(price * quantity) / COUNT(DISTINCT order_id) AS Avg_Order_Value,
        RANK() OVER (PARTITION BY pizza_sizes ORDER BY SUM(price * quantity) / COUNT(DISTINCT order_id) DESC) AS Avg_Order_Value_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        pizza_sizes
)
SELECT 
    pizza_sizes,
    pizza_name,
    Avg_Order_Value,
    Avg_Order_Value_Rank
FROM 
    Pizza_Revenue
WHERE 
    Avg_Order_Value_Rank <= 3
ORDER BY  
    (CASE WHEN pizza_sizes = 'Small' THEN 1
       WHEN pizza_sizes = 'Medium' THEN 2
       WHEN pizza_sizes = 'Large' THEN 3
       WHEN pizza_sizes = 'Extra Large' THEN 4
       ELSE 5 END) ASC,
    Avg_Order_Value_Rank; 

-- =======================================================================================

-- 32) Top 3 Pizza rank in Pizza Sizes by Avg_Pizza_per_Order: 

WITH Pizza_Tables AS
(
    SELECT 
        PT.name AS pizza_name, 
        O.order_id AS order_id,
        P.price AS price, 
        OD.quantity AS quantity, 
        (CASE WHEN P.size = 'S' THEN 'Small'
       WHEN P.size = 'M' THEN 'Medium'
       WHEN P.size = 'L' THEN 'Large'
       WHEN P.size = 'XL' THEN 'Extra Large'
       ELSE 'Double Extra Large' END) AS pizza_sizes
    FROM Pizza_Sales.dbo.order_details AS OD
    LEFT JOIN Pizza_Sales.dbo.orders AS O
        ON OD.order_id = O.order_id
    LEFT JOIN Pizza_Sales.dbo.pizzas AS P
        ON OD.pizza_id = P.pizza_id
    LEFT JOIN Pizza_Sales.dbo.pizza_types PT
        ON P.pizza_type_id = PT.pizza_type_id
), 
Pizza_Revenue AS
(
    SELECT 
        pizza_name, 
        pizza_sizes,
        SUM(quantity) / COUNT(DISTINCT order_id) AS Avg_Pizza_per_Order,
        RANK() OVER (PARTITION BY pizza_sizes ORDER BY SUM(quantity) / COUNT(DISTINCT order_id) DESC) AS Avg_Pizza_per_Order_Rank
    FROM 
        Pizza_Tables
    GROUP BY 
        pizza_name, 
        pizza_sizes
)
SELECT 
    pizza_sizes,
    pizza_name,
    Avg_Pizza_per_Order,
    Avg_Pizza_per_Order_Rank
FROM 
    Pizza_Revenue
WHERE 
    Avg_Pizza_per_Order_Rank <= 3
ORDER BY  
    (CASE WHEN pizza_sizes = 'Small' THEN 1
       WHEN pizza_sizes = 'Medium' THEN 2
       WHEN pizza_sizes = 'Large' THEN 3
       WHEN pizza_sizes = 'Extra Large' THEN 4
       ELSE 5 END) ASC,
    Avg_Pizza_per_Order_Rank; 

-- =======================================================================================

-- END

-- =======================================================================================
