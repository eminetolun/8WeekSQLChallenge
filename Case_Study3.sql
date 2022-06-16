
--  Merging plans table and subscriptions table

CREATE TEMP TABLE customers AS
SELECT s.customer_id, s.plan_id, p.plan_name, s.start_date, p.price FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p
ON s.plan_id = p.plan_id
ORDER BY s.customer_id;


-- 1. How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT(customer_id)) FROM customers

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value.

SELECT 
 DATE_PART('month',start_date) AS month_date, 
 TO_CHAR(start_date, 'Month') AS month_name, 
 COUNT(plan_id)  AS total_plan 
FROM customers
WHERE plan_name = 'trial'
GROUP BY month_date, month_name ;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name. 

SELECT plan_id, plan_name, COUNT(plan_name) AS count_of_events 
FROM customers 
WHERE start_date >= '2021–01–01'
GROUP BY plan_id , plan_name
ORDER BY plan_id;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT COUNT(*) AS churn_id, 
ROUND(( COUNT(*)::NUMERIC / (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions))::NUMERIC * 100,2) AS percantege
FROM customers
WHERE plan_name = 'churn'


-- 5. How many customers have churned straight after their initial free trial,what percentage is this rounded to the nearest whole number?

WITH ranking_cus AS(
SELECT * , DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY start_date ) AS rn FROM customers
)
SELECT COUNT(*) as churn_count, 
ROUND(( COUNT(*)::NUMERIC / (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions))::NUMERIC * 100) AS percentage
FROM ranking_cus 
WHERE rn = 2 AND plan_name = 'churn' ; 

-- 6. What is the number and percentage of customer plans after their initial free trial?

WITH ranking_cte AS(
SELECT * , DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY start_date ) AS rn FROM customers) 
SELECT plan_id , plan_name AS next_plan, 
COUNT(*) AS changes, 
ROUND((COUNT(*)::NUMERIC /(SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions))::NUMERIC * 100,2) AS percentage 
FROM ranking_cte
WHERE rn = 2 
GROUP BY plan_id, plan_name;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?


WITH lastdate_cte AS(
SELECT customer_id, MAX(start_date) AS last_date FROM customers
GROUP BY customer_id
ORDER BY customer_id
)
SELECT c.plan_name, COUNT(c.plan_name) AS plan_count,
ROUND((COUNT(*)::NUMERIC /(SELECT COUNT(DISTINCT customer_id) FROM customers))::NUMERIC * 100,2) AS percentage 
FROM customers AS c
JOIN lastdate_cte AS l
ON c.customer_id = l.customer_id
WHERE c.start_date = l.last_date and l.last_date <= '2020–12–31'
GROUP BY c.plan_name

-- 8. How many customers have upgraded to an annual plan in 2020?


SELECT COUNT(DISTINCT(customer_id)) AS annual_cus FROM customers
WHERE start_date <= '2020-12-31' AND plan_id = '3';

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH trial_cte AS(
SELECT * FROM customers
WHERE plan_id = 0 
), annual_cte AS(
SELECT * FROM customers
WHERE plan_id = 3)
SELECT ROUND(AVG(a.start_date - t.start_date)) FROM trial_cte AS t
JOIN annual_cte AS a 
ON t.customer_id = a.customer_id  ;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

WITH trial_plan AS 
(SELECT 
  customer_id, 
  start_date AS trial_date
FROM customers
WHERE plan_id = '0'
),
annual_plan AS
(SELECT 
  customer_id, 
  start_date AS annual_date
FROM customers
WHERE plan_id ='3'
),
bins AS 
(SELECT 
  WIDTH_BUCKET(ap.annual_date - tp.trial_date, 0, 360 , 12) AS avg_days_to_upgrade
FROM trial_plan tp
JOIN annual_plan ap
  ON tp.customer_id = ap.customer_id)
SELECT 
  ((avg_days_to_upgrade - 1) * 30 || ' - ' || (avg_days_to_upgrade) * 30) || ' days' AS breakdown, 
  COUNT(*) AS customers_count
FROM bins
GROUP BY avg_days_to_upgrade
ORDER BY avg_days_to_upgrade;

-- 11. How many customers were downgraded from a pro monthly to a basic monthly plan in 2020?

WITH ranking_cte AS(
SELECT * , DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY start_date ) AS rn FROM customers
where plan_id != '0') 
SELECT COUNT(*) FROM ranking_cte 
WHERE (rn = 1 AND plan_id = '2') AND (rn = 2 and plan_id = '1')
GROUP BY customer_id;
