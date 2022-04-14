# Case Study 1 Dannys Dinner  

************************************************************************************************************************************************************************
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

***********************************************************************************************************************************************************************

SELECT * FROM db.sales ;
SELECT * FROM db.menu ;
SELECT * FROM db.members ;

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id , SUM(price) total_amount FROM db.sales AS s
LEFT JOIN db.menu m ON s.product_id = m.product_id
GROUP BY customer_id;

- - Total amounts of A,B,C groups are 76,74,36.

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id , COUNT(DISTINCT(order_date)) AS number_of_visits  FROM db.sales
GROUP BY customer_id
ORDER BY customer_id ;


-- 3. What was the first item from the menu purchased by each customer

WITH product_cte
AS (
SELECT customer_id, product_id, DENSE_RANK() OVER (PARTITION BY  customer_id ORDER BY order_date)  AS ranking
FROM db.sales)
SELECT c.customer_id,  m.product_name
FROM product_cte c
JOIN db.menu m on c.product_id=m.product_id
WHERE ranking = 1
ORDER BY c.customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name, COUNT(s.product_id) AS most_purchased 
FROM db.sales s 
JOIN db.menu m 
ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY most_purchased DESC
LIMIT 1;

-- 5.Which item was the most popular for each customer?


WITH CustomerProduct AS (
  SELECT s.customer_id ,product_id, count(s.product_id) as items 
  FROM db.sales s
  GROUP BY customer_id, product_id
) 
, CustomerProductRanking AS (
	SELECT c.customer_id , m.product_name, c.items, dense_rank() over ( partition by customer_id order by c.items ) as ranking 
	FROM CustomerProduct c
	JOIN db.menu m 
	ON c.product_id = m.product_id)

SELECT customer_id , product_name FROM CustomerProductRanking 
WHERE ranking = 1 ;


-- 6 . Which item was purchased first by the customer after they became a member?

WITH ProductDate AS(
	SELECT s.customer_id, m.join_date, s.order_date, s.product_id, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS ranking
	FROM db.sales s
	JOIN db.members m
	ON s.customer_id = m.customer_id
	WHERE s.order_date >= m.join_date
) 
SELECT p.customer_id ,p.join_date, p.order_date, menu.product_name 
FROM ProductDate p
JOIN menu
ON p.product_id = menu.product_id
WHERE ranking = 1
ORDER BY customer_id ;

--7. Which item was purchased just before the customer became a member?

WITH ProductDate AS(
	SELECT s.customer_id, s.order_date, s.product_id, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) ranking
	FROM db.sales s
	JOIN db.members m
	ON s.customer_id = m.customer_id
	WHERE s.order_date < m.join_date
) 
SELECT p.customer_id ,  p.order_date, menu.product_name 
FROM ProductDate p
JOIN menu
ON p.product_id = menu.product_id
WHERE ranking = 1
ORDER BY customer_id ;


-- 8.What is the total items and amount spent for each member before they became a member?


SELECT s.customer_id, COUNT(m.product_name) product_count, SUM(m.price) total_price  
FROM db.sales s
JOIN db.members mb
ON s.customer_id = mb.customer_id
JOIN db.menu m
ON s.product_id = m.product_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;



-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH points AS (
	SELECT product_id, product_name,
	CASE 
	WHEN m.product_id =1 THEN price * 20
	ELSE price * 10
	END points
	FROM db.menu m
)
SELECT customer_id, SUM(p.points) total_points 
FROM db.sales s
JOIN points p
ON s.product_id = p.product_id 
GROUP BY customer_id
ORDER BY customer_id;



-- 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

CREATE FUNCTION end_of_month(date)
RETURNS date AS
$$
SELECT (date_trunc('month', $1) + interval '1 month' - interval '1 day')::date;
$$ LANGUAGE 'sql'
IMMUTABLE STRICT;


WITH date_cte AS(
	SELECT s.customer_id ,m.product_name, s.order_date,  mb.join_date, mb.join_date + integer '6' as valid_date, end_of_month(mb.join_date) as end_of_month, m.price
	FROM db.members mb
	JOIN db.sales s
	ON mb.customer_id = s.customer_id
	JOIN db.menu m 
	ON s.product_id = m.product_id 
)
SELECT d.customer_id, d.product_name, 
SUM(
	CASE
	WHEN d.product_name = 'sushi' THEN d.price * 2*10 
	WHEN d.order_date  BETWEEN d.join_date AND d.valid_date THEN d.price * 2 * 10 
	ELSE d.price * 10 END
) AS total_points 
FROM date_cte d
WHERE d.order_date < d.end_of_month
GROUP BY d.customer_id , d.product_name ;




-- Bonus Questions
-- Join All The Things

SELECT s.customer_id, s.order_date, s.product_id, m.product_name, m.price,
CASE 
WHEN mb.join_date > s.order_date THEN 'N'
WHEN mb.join_date <= s.order_date THEN 'Y'
ELSE 'N' END  member
FROM db.sales s
LEFT JOIN db.members mb
ON s.customer_id = mb.customer_id
JOIN db.menu m
ON s.product_id = m.product_id;


----- Rank All The Things


WITH all_cte AS(
	SELECT s.customer_id, s.order_date, s.product_id, m.product_name, m.price,
	CASE 
	WHEN mb.join_date > s.order_date THEN 'N'
	WHEN mb.join_date <= s.order_date THEN 'Y'
	ELSE 'N' END  member
	FROM db.sales s
LEFT JOIN db.members mb
ON s.customer_id = mb.customer_id
JOIN db.menu m
ON s.product_id = m.product_id)
SELECT * , 
CASE
WHEN member = 'Y' THEN  RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date ) 
ELSE  NULL
END AS ranking
FROM all_cte;
