--Case Study #2 Pizza Runner

--Create schema and tables

CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

-- DATA MANIPULATION 

CREATE TEMP TABLE customer_orders_temp AS 
SELECT 
   order_id , customer_id, pizza_id,
   CASE 
       WHEN exclusions IS null OR exclusions LIKE 'null' THEN ''
	   ELSE exclusions
	   END exclusions,
   CASE  
	   WHEN extras IS null OR extras LIKE 'null' THEN ''
	   ELSE extras
   END extras, order_time FROM pizza_runner.customer_orders;


SELECT * FROM customer_orders_temp;


CREATE TEMP TABLE runner_orders_temp AS
SELECT order_id,runner_id,
CASE WHEN pickup_time IS null OR pickup_time LIKE 'null' THEN '' 
     ELSE pickup_time
	 END pickup_time,
CASE when distance IS null OR distance LIKE 'null' THEN ''
WHEN distance LIKE '%km' THEN TRIM('km'from distance)
ELSE distance
END AS distance ,

CASE 
WHEN duration IS null OR duration LIKE 'null' THEN ''
WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)
WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)
WHEN duration LIKE '%mins' THEN TRIM('mins' from duration)
ELSE duration
END AS duration,

CASE 
WHEN cancellation IS null OR cancellation LIKE 'null' THEN ''
ELSE cancellation
END AS cancellation
FROM pizza_runner.runner_orders;

SELECT * FROM runner_orders_temp;

ALTER TABLE runner_orders_temp
ALTER COLUMN pickup_time  TYPE  TIMESTAMP USING(CASE WHEN pickup_time = '' THEN null ELSE pickup_time:: TIMESTAMP END),
ALTER COLUMN distance TYPE FLOAT USING(CASE WHEN distance = '' THEN NULL ELSE distance:: FLOAT END),
ALTER COLUMN duration TYPE INT USING(CASE WHEN duration = '' THEN NULL ELSE duration:: INT END); 

-- CASE STUDY QUESTIONS

-- A. Pizza Metrics

--1. How many pizzas were ordered?
 
SELECT COUNT(pizza_id) FROM customer_orders_temp;

-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT(customer_id)) FROM customer_orders_temp;

-- 3. How many successful orders were delivered by each runner?

SELECT runner_id,COUNT(order_id) AS total_order FROM runner_orders_temp
WHERE distance IS NOT NULL AND distance != 0 
GROUP BY runner_id
ORDER BY runner_id;

-- 4.How many of each type of pizza was delivered?

SELECT p.pizza_name, COUNT(r.order_id) FROM runner_orders_temp AS r
JOIN customer_orders_temp AS c
ON r.order_id = c.order_id 
JOIN pizza_runner.pizza_names AS p
ON c.pizza_id = p.pizza_id
WHERE r.distance != 0
GROUP BY p.pizza_name; 

--5.  How many Vegetarian and Meatlovers were ordered by each customer?

SELECT c.customer_id, p.pizza_name, COUNT(c.order_id) FROM customer_orders_temp AS c
JOIN pizza_runner.pizza_names AS p
ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id, p.pizza_name
ORDER BY c.customer_id; 

--6. What was the maximum number of pizzas delivered in a single order?

SELECT c.order_id, COUNT(c.pizza_id) AS max_pizza FROM customer_orders_temp AS c
JOIN runner_orders_temp AS r
ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY c.order_id
ORDER BY max_pizza DESC
LIMIT 1;

--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT c.customer_id,
        SUM(CASE WHEN c.exclusions != '' OR c.extras != '' THEN 1 ELSE 0 END) AS yes_change,
	SUM(CASE WHEN c.exclusions = '' AND c.extras = '' THEN 1  ELSE 0 END) AS no_change
FROM customer_orders_temp AS c
JOIN runner_orders_temp AS r
  ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY c.customer_id
ORDER BY c.customer_id; 

--8. How many pizzas were delivered that had both exclusions and extras?

SELECT SUM( CASE WHEN c.exclusions != '' AND c.extras != '' THEN 1 ELSE 0 END) AS pizza_extras_exclusions
FROM customer_orders_temp AS c
JOIN runner_orders_temp AS r
  ON c.order_id = r.order_id
WHERE r.distance != 0 

--9. What was the total volume of pizzas ordered for each hour of the day?

SELECT date_part('hour', order_time)  AS hour_of_the_day , COUNT(pizza_id) AS pizza_count 
FROM customer_orders_temp
GROUP BY hour_of_the_day 
ORDER BY hour_of_the_day;


--10. What was the volume of orders for each day of the week?

SELECT TO_CHAR(order_time , 'Day') AS  day, count(order_id) AS total_pizzas 
FROM customer_orders_temp 
GROUP BY day
ORDER BY day;

-- B. Runner and Customer Experience

--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT MIN(r.registration_date) AS week_start, COUNT(r.runner_id) AS runner_signup
FROM pizza_runner.runners AS r 
WHERE '20210101' <= r.registration_date
GROUP BY DATE_PART('week', r.registration_date)
ORDER BY week_start;


--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT r.runner_id,
ROUND(AVG(EXTRACT(epoch FROM (r.pickup_time- c.order_time))/60),2) 
FROM customer_orders_temp  AS c
JOIN runner_orders_temp AS r
ON c.order_id = r.order_id
WHERE r.distance != 0 
GROUP BY r.runner_id
ORDER BY r.runner_id;

--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH prepare_time_cte AS(
	SELECT c.order_id,
	COUNT(c.order_id) AS pizza_order,
	ROUND(AVG(EXTRACT(epoch FROM (r.pickup_time- c.order_time))/60),2) AS prepare_time
	FROM customer_orders_temp  AS c
	JOIN runner_orders_temp AS r
	ON c.order_id = r.order_id
	WHERE r.distance != 0 
	GROUP BY c.order_id)
SELECT pizza_order,round(AVG(prepare_time),0) AS avg_prepare_time 
FROM prepare_time_cte
GROUP BY pizza_order
ORDER BY pizza_order;


--4. What was the average distance travelled for each customer?

SELECT c.customer_id, ROUND(AVG(r.distance)) AS avg_distance
FROM customer_orders_temp  AS c
JOIN runner_orders_temp AS r
ON c.order_id = r.order_id
WHERE r.distance != 0 
GROUP BY  c.customer_id
ORDER BY c.customer_id;


--5. What was the difference between the longest and shortest delivery times for all orders?

SELECT (MAX(duration) - min(duration)) AS delivery_time_diff FROM runner_orders_temp


--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?


SELECT runner_id , order_id,  ROUND(distance / duration * 60)  AS  avg_speed FROM runner_orders_temp
WHERE distance !=0
GROUP BY order_id, runner_id, avg_speed
ORDER BY runner_id, order_id;

--7. What is the successful delivery percentage for each runner?

SELECT runner_id,ROUND((100* SUM(CASE WHEN distance != 0 THEN 1 ELSE 0 END) / COUNT(*))) AS success_percantage  
FROM runner_orders_temp
GROUP BY runner_id
ORDER BY runner_id;

--C. Ingredient Optimisation

--1. What are the standard ingredients for each pizza?

CREATE TEMP TABLE pizza_temp AS(
	
	WITH pizza_recipes_temp AS
(SELECT
  pizza_id,
  REGEXP_SPLIT_TO_TABLE(toppings, '[,\s]+')::INTEGER AS topping_id
FROM pizza_runner.pizza_recipes )
	
SELECT pr.pizza_id, pn.pizza_name, pr.topping_id, pt.topping_name
FROM pizza_recipes_temp AS pr
JOIN pizza_runner.pizza_names AS pn
ON pr.pizza_id = pn.pizza_id
JOIN pizza_runner.pizza_toppings AS pt
ON pr.topping_id =  pt.topping_id
ORDER BY pn.pizza_name, pr.topping_id, pt.topping_name)

--2. What was the most commonly added extra?

WITH extras_cte AS(
SELECT pizza_id, REGEXP_SPLIT_TO_TABLE(extras, '[,\s]+')::INTEGER AS extras FROM customer_orders_temp
WHERE extras !='') 
SELECT extras ,COUNT(*) AS most_added_extra FROM extras_cte
GROUP BY extras
ORDER BY most_added_extra DESC
LIMIT 1 ;


--3. What was the most common exclusion?

WITH exclusion_cte AS(
SELECT pizza_id, REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+')::INTEGER AS exclusions FROM customer_orders_temp
WHERE exclusions !='') 
SELECT exclusions , COUNT(*) AS most_exclusion FROM exclusion_cte
GROUP BY exclusions;

--4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

--5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

--6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

SELECT p.topping_name, COUNT(p.topping_name) as ingredient_quantity FROM pizza_temp AS p
JOIN customer_orders_temp AS c
ON p.pizza_id = c.pizza_id 
JOIN runner_orders_temp AS r
ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY p.topping_name                                                                 
ORDER BY ingredient_quantity DESC;

--D. Pricing and Ratings

--1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
WITH prices AS(
SELECT p.pizza_name, CASE WHEN p.pizza_name = 'Meatlovers'  THEN 20 ELSE 10 END  price  FROM pizza_runner.pizza_names AS p
JOIN customer_orders_temp AS c
ON p.pizza_id = c.pizza_id
JOIN runner_orders_temp AS r
	ON r.order_id = c.order_id
	WHERE r.distance != 0
)
SELECT SUM(price)  AS total_prices FROM prices;

