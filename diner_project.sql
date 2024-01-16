CREATE DATABASE DINER;

USE Diner;

CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);

CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);

INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');

-- 1. Total amount each customer spent in the restaurant

SELECT s.customer_id, SUM(m.price) AS total_spent
FROM diner.sales s
INNER JOIN diner.menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT s.customer_id, COUNT(DISTINCT s.order_date) AS days_visited
FROM diner.sales s
GROUP BY s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH customer_first_purchase AS(
	SELECT s.customer_id, MIN(s.order_date) AS first_purchase_date
	FROM diner.sales s
	GROUP BY s.customer_id
)
SELECT cfp.customer_id, cfp.first_purchase_date, m.product_name
FROM customer_first_purchase cfp
INNER JOIN diner.sales s ON s.customer_id = cfp.customer_id
AND cfp.first_purchase_date = s.order_date
INNER JOIN diner.menu m on m.product_id = s.product_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name, COUNT(s.product_id) AS total_purchased
FROM sales s
INNER JOIN menu m on s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchased DESC
limit 1;

-- 5. Which item was the most popular for each customer?

WITH customer_popularity AS (
    SELECT s.customer_id, m.product_name, COUNT(*) AS purchase_count,
        DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS Ranks
    FROM sales s
    INNER JOIN menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, purchase_count
FROM customer_popularity
WHERE ranks = 1;

-- 6. Which item was purchased just before the customer became a member?

WITH last_purchase_before_membership AS (
    SELECT s.customer_id, MAX(s.order_date) AS last_purchase_date
    FROM diner.sales s
    JOIN diner.members mb ON s.customer_id = mb.customer_id
    WHERE s.order_date < mb.join_date
    GROUP BY s.customer_id
)
SELECT lpbm.customer_id, m.product_name
FROM last_purchase_before_membership lpbm
JOIN diner.sales s ON lpbm.customer_id = s.customer_id 
AND lpbm.last_purchase_date = s.order_date
JOIN diner.menu m ON s.product_id = m.product_id;

-- 7. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(*) as total_items, SUM(m.price) AS total_spent
FROM diner.sales s
JOIN diner.menu m ON s.product_id = m.product_id
JOIN diner.members mb ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;


-- 8. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id, SUM(
	CASE 
		WHEN m.product_name = 'sushi' THEN m.price*20 
		ELSE m.price*10 END) AS total_points
FROM diner.sales s
JOIN diner.menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;