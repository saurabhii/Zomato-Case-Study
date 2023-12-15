  DROP TABLE IF EXISTS driver;
CREATE TABLE driver(driver_id INT,reg_date DATE); 

INSERT INTO driver VALUES (1,'01-01-2021'), (2,'01-03-2021'), (3,'01-08-2021'), (4,'01-15-2021');


DROP TABLE IF EXISTS ingredients;
CREATE TABLE ingredients(ingredients_id INT, ingredients_name VARCHAR(60)); 

INSERT INTO ingredients VALUES (1,'BBQ Chicken'), (2,'Chilli Sauce'), (3,'Chicken'), (4,'Cheese'), (5,'Kebab'),
(6,'Mushrooms'), (7,'Onions'), (8,'Egg'), (9,'Peppers'), (10,'schezwan sauce'), (11,'Tomatoes'), (12,'Tomato Sauce');


DROP TABLE IF EXISTS rolls;
CREATE TABLE rolls(roll_id INT,roll_name VARCHAR(30)); 

INSERT INTO rolls VALUES (1	,'Non Veg Roll'), (2, 'Veg Roll');


DROP TABLE IF EXISTS rolls_recipes;
CREATE TABLE rolls_recipes(roll_id INT, ingredients VARCHAR(60)); 

INSERT INTO rolls_recipes VALUES (1,'1,2,3,4,5,6,8,10'), (2,'4,6,7,9,11,12');


DROP TABLE IF EXISTS driver_order;
CREATE TABLE driver_order(order_id INT, driver_id INT, pickup_time DATETIME, distance VARCHAR(7),
			 duration VARCHAR(10), cancellation VARCHAR(23));
INSERT INTO driver_order VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2021 21:30:45','25km','25mins',null),
(8,2,'01-10-2021 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2021 18:50:20','10km','10minutes',null);


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders(order_id INT, customer_id INT, roll_id INT, not_include_items VARCHAR(4),
			 extra_items_included VARCHAR(4), order_date DATETIME);
INSERT INTO customer_orders VALUES (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

A. Roll metrics
B. Driver and Customer experience
C. Ingredient Optimization
D. Pricing and Ratings

A. Roll metrics

-- 1) How many rolls were ordered ? 
SELECT COUNT(roll_id) FROM customer_orders;

-- 2) How many unique customer orders were made?
SELECT COUNT(DISTINCT customer_id) FROM customer_orders;

--  3) How many successful orders were delivered by each driver?
SELECT driver_id, COUNT(order_id) 
	FROM driver_order 
		WHERE cancellation NOT IN ('Cancellation','Customer Cancellation')
		GROUP BY driver_id;

-- 4)  How many of each type of rolls were delivered (not ordered)
SELECT roll_id, COUNT(roll_id) FROM customer_orders WHERE order_id IN
(SELECT order_id FROM
(SELECT *,
		CASE WHEN cancellation in ('Cancellation','Customer Cancellation') THEN 'c' ELSE 'nc' END AS 
			order_cancel_details FROM driver_order) x WHERE order_cancel_details = 'nc')
GROUP BY roll_id;

-- 5) How many rolls and non-veg rolls were ordered by each customer 
SELECT x.*, r.roll_name FROM
(SELECT customer_id, roll_id, COUNT(order_id) Roll_count
	FROM customer_orders 
		GROUP BY customer_id, roll_id) x
INNER JOIN rolls r ON x.roll_id= r.roll_id;

-- 6) What was the maximum no. of rolls delivered in a single order?
SELECT TOP 1 y.order_id, COUNT(y.order_id)  FROM
(SELECT * FROM
(SELECT *,
		CASE WHEN cancellation in ('Cancellation','Customer Cancellation') THEN 'c' ELSE 'nc' END AS 
			order_cancel_details FROM driver_order) x WHERE order_cancel_details='nc') y INNER JOIN customer_orders co
			ON y.order_id=co.order_id GROUP BY y.order_id ORDER BY COUNT(y.order_id) DESC;

-- 7) For each customer, how many delivered rolls had at least 1 change and how many had no change
WITH temp_customer_orders  AS 
( SELECT order_id, customer_id, roll_id, 
	 CASE WHEN not_include_items IS NULL OR not_include_items = ' ' THEN '0' ELSE not_include_items END AS new_not_include_items,
	 CASE WHEN extra_items_included IS NULL OR extra_items_included = ' ' OR extra_items_included = 'NaN' OR extra_items_included ='NULL' THEN '0' ELSE extra_items_included END AS new_extra_items_included,
	 order_date FROM customer_orders
) ,
temp_driver_order AS ( SELECT order_id, driver_id, pickup_time, distance, duration,
	CASE WHEN cancellation IN ('cancellation', 'customer cancellation') THEN '0' ELSE '1' END AS new_cancellation
FROM driver_order)

SELECT customer_id, chg_no_chg, COUNT(order_id) FROM 
(SELECT *, CASE WHEN new_not_include_items='0' AND new_extra_items_included='0' THEN 'no change' ELSE 'change' END AS chg_no_chg
	FROM temp_customer_orders
		WHERE order_id IN (SELECT order_id FROM temp_driver_order WHERE new_cancellation!=0)) a
GROUP BY customer_id, chg_no_chg;

-- 8) How many rolls delivered had both exclusions and extras?
-- Modifying the above query to get the answer.
WITH temp_customer_orders  AS 
( SELECT order_id, customer_id, roll_id, 
	 CASE WHEN not_include_items IS NULL OR not_include_items = ' ' THEN '0' ELSE not_include_items END AS new_not_include_items,
	 CASE WHEN extra_items_included IS NULL OR extra_items_included = ' ' OR extra_items_included = 'NaN' OR extra_items_included ='NULL' THEN '0' ELSE extra_items_included END AS new_extra_items_included,
	 order_date FROM customer_orders
) ,
temp_driver_order AS ( SELECT order_id, driver_id, pickup_time, distance, duration,
	CASE WHEN cancellation IN ('cancellation', 'customer cancellation') THEN '0' ELSE '1' END AS new_cancellation
FROM driver_order)

SELECT chg_no_chg, COUNT(chg_no_chg) FROM 
(SELECT *, CASE WHEN new_not_include_items!='0' AND new_extra_items_included!='0' THEN 'both_inc' ELSE 'either_one_ornot' END AS chg_no_chg
	FROM temp_customer_orders
		WHERE order_id IN (SELECT order_id FROM temp_driver_order WHERE new_cancellation!=0)) a
GROUP BY chg_no_chg;

-- 9) What was the total no. of rolls ordered for each hour of the day?
SELECT hourly_window, COUNT(hourly_window) FROM
(SELECT *, 
	    CONCAT(CAST(DATEPART(HOUR, order_date) AS VARCHAR),'-', CAST(DATEPART(HOUR, order_date)+1 AS VARCHAR)) 
			AS hourly_window FROM customer_orders) x 
GROUP BY hourly_window;

-- 10) What was the number of orders for each day of the week?
SELECT DoW, COUNT(DISTINCT order_id) FROM
(SELECT *, DATENAME(DW, order_date) DoW FROM customer_orders) x
GROUP BY DoW;

-- 11) What was the average time in minutes it took for each driver to arrive at the faasos HK to pickup the order
SELECT driver_id, SUM(Diff)/ COUNT(order_id) Avg_time FROM
(SELECT *, ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY Diff) AS Rnk FROM
(SELECT co.order_id, co.customer_id, co.roll_id, co.order_date, do.driver_id, do.pickup_time, do.cancellation, 
	   DATEDIFF(MINUTE, co.order_date, do.pickup_time) Diff
		FROM customer_orderS co INNER JOIN driver_order do ON co.order_id=do.order_id 
			WHERE do.pickup_time IS NOT NULL) x) y
WHERE Rnk=1
GROUP BY driver_id;

-- 12) Is there any relationship between the no of rolls and how long the order takes to prepare?
SELECT order_id, COUNT(roll_id) cnt_rolls, SUM(Diff)/COUNT(roll_id) tyme FROM
(SELECT co.order_id, co.customer_id, co.roll_id, co.not_include_items, co.extra_items_included, co.order_date,
		do.driver_id, do.pickup_time, do.distance, DATEDIFF(MINUTE, co.order_date, do.pickup_time) Diff
			FROM customer_orders co INNER JOIN driver_order do ON co.order_id=do.order_id
				WHERE do.pickup_time IS NOT NULL) x
GROUP BY order_id;

-- 13) What was the average distance travelled for each customer
SELECT customer_id, SUM(distance)/COUNT(roll_id) FROM
(SELECT *, ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY Diff) rnk FROM
(SELECT co.order_id, co.customer_id, co.roll_id, co.order_date, do.driver_id, do.pickup_time, 
		CAST(TRIM(REPLACE(LOWER(do.distance), 'km','')) AS decimal(4,2)) distance,
	    DATEDIFF(MINUTE, co.order_date, do.pickup_time) Diff
			FROM customer_orders co INNER JOIN driver_order do ON co.order_id=do.order_id
				WHERE do.pickup_time IS NOT NULL) x)y WHERE rnk=1 GROUP BY customer_id

-- 14) What is the difference between shortest and longest delivery time for all orders?
SELECT MAX(duration) - MIN(duration) Diff FROM 
(SELECT CAST(CASE WHEN duration like '%min%' THEN LEFT(duration, CHARINDEX('m',duration)-1) ELSE duration END AS INT)
	AS duration FROM driver_order 
		WHERE duration IS NOT NULL) x;

-- 15) What was the average speed for each driver for each delivery
SELECT a.order_id, a.driver_id, a.distance/a.duration speed, b.cnt FROM
(SELECT driver_id, order_id,
       CAST(TRIM(REPLACE(LOWER(distance),'km','')) AS DECIMAL(4,2)) AS Distance,
	   CAST(CASE WHEN duration LIKE '%min%' THEN LEFT(duration, CHARINDEX('m',duration)-1) ELSE duration END AS INT) AS duration
		FROM driver_order WHERE duration IS NOT NULL) a INNER JOIN 
		(SELECT order_id, COUNT(roll_id) cnt FROM customer_orders GROUP BY order_id) b ON a.order_id=b.order_id

-- 16) What is the successful delivery percentage for each driver?
SELECT driver_id, (SUM(Can_num)*1.0/COUNT(Can_num))*100 AS Del_per 
FROM
	(SELECT order_id, driver_id, 
			CASE WHEN LOWER(cancellation) LIKE '%cancel%' THEN 0 ELSE 1 END AS Can_num
				FROM driver_order) x GROUP BY driver_id







			