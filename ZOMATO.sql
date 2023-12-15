USE zomato;

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
	userid INT PRIMARY KEY,
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