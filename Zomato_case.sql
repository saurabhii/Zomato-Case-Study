-- Creating and using the database 
DROP DATABASE IF EXISTS zomato;

CREATE DATABASE zomato;

USE zomato;

-- Creating the structure of various tables in the database
DROP TABLE IF EXISTS goldusers_signup;
CREATE TABLE goldusers_signup(
	userid INT PRIMARY KEY,
	gold_signup_date DATE); 

INSERT INTO goldusers_signup VALUES (1,'09-22-2017'), (3,'04-21-2017');

DROP TABLE IF EXISTS users;
CREATE TABLE users(
	userid INT PRIMARY KEY,
	signup_date DATE); 

INSERT INTO users VALUES (1,'09-02-2014'), (2,'01-15-2015'), (3,'04-11-2014');

DROP TABLE IF EXISTS sales;
CREATE TABLE sales(
	userid INT,
	created_date DATE,
	product_id INT); 

INSERT INTO sales VALUES (1,'04-19-2017',2), (3,'12-18-2019',1), (2,'07-20-2020',3), (1,'10-23-2019',2), (1,'03-19-2018',3),
(3,'12-20-2016',2), (1,'11-09-2016',1), (1,'05-20-2016',3), (2,'09-24-2017',1), (1,'03-11-2017',2), (1,'03-11-2016',1),
(3,'11-10-2016',1), (3,'12-07-2017',2), (3,'12-15-2016',2), (2,'11-08-2017',2), (2,'09-10-2018',3);


DROP TABLE IF EXISTS product;
CREATE TABLE product(
	product_id INT PRIMARY KEY,
	product_name TEXT,
	price INT); 

INSERT INTO product VALUES (1,'p1',980), (2,'p2',870), (3,'p3',330);

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- 1) The total amount spent by each customer
SELECT a.userid, SUM(b.price) AS total_amt_spent
	FROM sales a INNER JOIN product b  
		ON a.product_id = b.product_id
GROUP BY a.userid;

-- 2) Total no. of days each customer visited zomato
SELECT userid, COUNT(DISTINCT created_date)AS total_visited_days 
	FROM sales 
GROUP BY userid;

-- 3) first product purchased by each customer
SELECT * FROM
(SELECT s.userid, s.created_date, s.product_id, p.product_name, RANK() OVER(PARTITION BY userid ORDER BY created_date) as rnk
	FROM sales s INNER JOIN product p 
		ON s.product_id = p.product_id) m
WHERE rnk = 1;

-- 4) No.of times each item sold by zomato bought by customer
SELECT product_id, COUNT(product_id) max_times_purchased
	FROM sales
GROUP BY product_id
ORDER BY COUNT(product_id) DESC;

-- 5) mostly sold item bought by each customer 'n' times
SELECT userid, COUNT(product_id) cnt
	FROM sales
		WHERE product_id = 2
GROUP BY userid;

-- 6) item most popular among each customer 
WITH CTE AS (
SELECT userid, product_id,
	   COUNT(product_id) cnt,
	   RANK() OVER(PARTITION BY userid ORDER BY COUNT(product_id) DESC) rnk
	FROM sales
GROUP BY userid, product_id)
SELECT * FROM CTE WHERE rnk = 1;

-- 7) The product first purchased by customer after they signedup for gold membership
SELECT * FROM
(SELECT g.userid, g.created_date, g.product_id, g.gold_signup_date, p.product_name, 
	    RANK() OVER(PARTITION BY userid ORDER BY created_date) rnk 
	FROM 
(SELECT s.userid, s.product_id, s.created_date, gus.gold_signup_date
	FROM sales s INNER JOIN goldusers_signup gus 
		ON s.userid = gus.userid 
		WHERE created_date>= gold_signup_date ) g 
INNER JOIN 
product p ON g.product_id = p.product_id) x
WHERE rnk =1;

-- 8) The last product purchased by customers before signing up for gold membership
SELECT * FROM
(SELECT g.userid, g.created_date, g.product_id, g.gold_signup_date, p.product_name, 
	    RANK() OVER(PARTITION BY userid ORDER BY created_date DESC) rnk 
	FROM 
(SELECT s.userid, s.product_id, s.created_date, gus.gold_signup_date
	FROM sales s INNER JOIN goldusers_signup gus 
		ON s.userid = gus.userid 
		WHERE created_date<= gold_signup_date ) g 
INNER JOIN 
product p ON g.product_id = p.product_id) x
WHERE rnk =1;

-- 9) total amount spent and total orders placed by customers before becoming a member.
SELECT g.userid, COUNT(g.product_id) total_orders, SUM(p.price) total_amt_spent
	    FROM 
(SELECT s.userid, s.product_id, s.created_date, gus.gold_signup_date
	FROM sales s INNER JOIN goldusers_signup gus 
		ON s.userid = gus.userid 
		WHERE created_date<= gold_signup_date) g 
INNER JOIN 
product p ON g.product_id = p.product_id
GROUP BY userid;

-- 10) Adding zomato points corresponding to each Re spent against paricular products EX: p1: 5 Rs = 1 pt, p2: 10Rs = 5 pt, p3: 5Rs = 1 pt

-- Calculate points coolected by each customer and for which product most points have been given till now
WITH points_availed AS (
SELECT *, y.total_price/y.pt_per_Rs total_points FROM  (
 SELECT * , CASE WHEN x.product_id = 1 THEN 5
	 			 WHEN x.product_id = 2 THEN 2
				 WHEN x.product_id = 3 THEN 5
		    ELSE 0 END AS pt_per_Rs
	 FROM (
 SELECT s.userid, s.product_id, SUM(p.price) total_price
	 FROM sales s INNER JOIN product p 
		 ON s.product_id=p.product_id
		 GROUP BY s.userid, s.product_id) x) y)
SELECT userid, SUM(total_points) total_points_earned FROM points_availed
GROUP BY userid;

-- if 5Rs = 2 points then these points can be converted into Rs by multiplying 2.5 in SUM(total_points)


-- 11) Modifying the above query to get product-wise points earned and getting the highest point product amongst them

WITH most_points_product AS (
SELECT z.product_id, SUM(z.total_points) total_points_earned, RANK() OVER(ORDER BY SUM(z.total_points) DESC) rnk  FROM(
SELECT *, y.total_price/y.pt_per_Rs total_points FROM  (
 SELECT * , CASE WHEN x.product_id = 1 THEN 5
	 			 WHEN x.product_id = 2 THEN 2
				 WHEN x.product_id = 3 THEN 5
		    ELSE 0 END AS pt_per_Rs
	 FROM (
 SELECT s.userid, s.product_id, SUM(p.price) total_price
	 FROM sales s INNER JOIN product p 
		 ON s.product_id=p.product_id
		 GROUP BY s.userid, s.product_id) x) y) z
GROUP BY product_id)
SELECT * FROM most_points_product WHERE rnk=1;

-- 12) In the first year after joining the gold program (including the join date) irrespective of what the cusdtomer has purchased
-- they earn 5 zomato points for every 10 rs spent, who earned more (cust 1 or 3) and their corresponding points earning that same year
-- 0.5 pt = 1Re 
SELECT c.*, d.price*0.5 pts_earned  FROM 
(SELECT s.userid, s.product_id, s.created_date, gus.gold_signup_date
	FROM sales s INNER JOIN goldusers_signup gus 
		ON s.userid = gus.userid 
		WHERE created_date>= gold_signup_date and created_date <= DATEADD(YEAR, 1, gold_signup_date)) c
INNER JOIN product d 
	ON c.product_id=d.product_id;


-- 13) Rank all the transactions of the customers
SELECT * , RANK() OVER (PARTITION BY userid ORDER BY created_date)
	FROM sales;

-- 14) Rank all the transaction for each member where they are a gold member & for every non gold member transaction mark NA
SELECT *, CASE WHEN rnk=0 THEN 'NA' ELSE rnk END AS rnkk     FROM
(SELECT x.*, CAST((CASE WHEN gold_signup_date IS NULL THEN 0 ELSE RANK() OVER (PARTITION BY userid ORDER BY gold_signup_date DESC) END) AS VARCHAR) rnk FROM 
(SELECT s.userid, s.created_date, s.product_id, gs.gold_signup_date
	FROM sales s LEFT JOIN goldusers_signup gs 
		ON s.userid = gs.userid and created_date >= gold_signup_date)x)y;



