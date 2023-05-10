--1.How many pizzas were ordered?

SELECT
  COUNT(pizza_id) AS number_of_pizza_ordered
FROM
  pizza_runner.customer_orders;

--2.How many unique customer orders were made?

SELECT
  customer_id,
  COUNT(DISTINCT order_id) AS unique_customer_orders
FROM
  pizza_runner.customer_orders
GROUP BY
  customer_id;

--3.How many successful orders were delivered by each runner?

SELECT
  runner_id,
  COUNT(order_id) AS delivered_orders
FROM
  pizza_runner.runner_orders
WHERE
  pickup_time != 'null'
  AND distance != 'null'
  AND duration != 'null'
GROUP BY
  1
ORDER BY
  1;
  
--4.How many of each type of pizza was delivered?

SELECT
  pizza_name,
  COUNT(pizza_name) AS number_of_pizzas_delivered
FROM
  pizza_runner.customer_orders AS c
  JOIN pizza_runner.pizza_names AS n ON c.pizza_id = n.pizza_id
  JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
WHERE
  pickup_time != 'null'
  AND distance != 'null'
  AND duration != 'null'
GROUP BY
  1
ORDER BY
  1;

--5.How many Vegetarian and Meatlovers were ordered by each customer?

SELECT
  customer_id,
  pizza_name,
  COUNT(pizza_name) AS number_of_pizzas_delivered
FROM
  pizza_runner.customer_orders AS c
  JOIN pizza_runner.pizza_names AS n ON c.pizza_id = n.pizza_id
GROUP BY
  customer_id,
  pizza_name
ORDER BY
  customer_id;


--6.What was the maximum number of pizzas delivered in a single order?

WITH rank_added AS (
  SELECT
    c.order_id,
    c.customer_id,
    COUNT(c.order_id) AS items_in_order,
    rank() OVER (
      ORDER BY
        COUNT(c.order_id) DESC
    ) AS rank
  FROM
    pizza_runner.customer_orders AS c
    JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
  WHERE
    pickup_time != 'null'
    AND distance != 'null'
    AND duration != 'null'
  GROUP BY
    c.order_id,
    c.customer_id
)
SELECT
  order_id,
  customer_id,
  items_in_order
FROM
  rank_added
WHERE
  rank = 1;

--7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT
  customer_id,
  changes,
  COUNT(changes) AS number_of_pizzas
FROM
  (
    WITH ranked AS (
      SELECT
        *,
        ROW_NUMBER() OVER () AS rank
      FROM
        pizza_runner.customer_orders
    )
    SELECT
      customer_id,
      c.order_id,
      CASE
        WHEN exclusions ~ '^[0-9, ]+$'
        OR extras ~ '^[0-9, ]+$' THEN 'Have changes'
        ELSE 'No changes'
      END AS changes,
      rank
    FROM
      ranked AS c
      JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
    WHERE
      pickup_time != 'null'
      AND distance != 'null'
      AND duration != 'null'
    GROUP BY
      exclusions,
      extras,
      customer_id,
      c.order_id,
      rank
  ) AS changes
GROUP BY
  changes,
  customer_id
ORDER BY
  customer_id;

--8.How many pizzas were delivered that had both exclusions and extras?

SELECT
  CASE
    WHEN exclusions ~ '^[0-9, ]+$'
    AND extras ~ '^[0-9, ]+$' THEN 'Have exclusions and extras'
  END AS exclusions_and_extras,
  COUNT(exclusions) AS number_of_pizzas
FROM
  pizza_runner.customer_orders AS c
  JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
WHERE
  pickup_time != 'null'
  AND distance != 'null'
  AND duration != 'null'
GROUP BY
  exclusions,
  extras
HAVING
  extras ~ '^[0-9, ]+$'
  AND exclusions ~ '^[0-9, ]+$';
  
--9.What was the total volume of pizzas ordered for each hour of the day?

SELECT
  hours,
  SUM(pizzas_ordered) AS pizzas_ordered
FROM
  (
    SELECT
      EXTRACT(
        hour
        FROM
          order_time
      ) AS hours,
      COUNT(
        EXTRACT(
          hour
          FROM
            order_time
        )
      ) AS pizzas_ordered
    FROM
      pizza_runner.customer_orders AS c
    GROUP BY
      order_time
  ) AS count_hours
GROUP BY
  hours
ORDER BY
  pizzas_ordered DESC;

--10.What was the volume of orders for each day of the week?

SELECT
  dow AS day_of_week,
  SUM(pizzas_ordered) AS pizzas_ordered
FROM
  (
    SELECT
      CASE
        WHEN EXTRACT(
          isodow
          FROM
            order_time
        ) = 1 THEN 'Monday'
        WHEN EXTRACT(
          isodow
          FROM
            order_time
        ) = 2 THEN 'Tuesday'
        WHEN EXTRACT(
          isodow
          FROM
            order_time
        ) = 3 THEN 'Wednesnday'
        WHEN EXTRACT(
          isodow
          FROM
            order_time
        ) = 4 THEN 'Thursday'
        WHEN EXTRACT(
          isodow
          FROM
            order_time
        ) = 5 THEN 'Friday'
        WHEN EXTRACT(
          isodow
          FROM
            order_time
        ) = 6 THEN 'Saturday'
        WHEN EXTRACT(
          isodow
          FROM
            order_time
        ) = 7 THEN 'Sunday'
      END AS dow,
      COUNT(
        EXTRACT(
          isodow
          from
            order_time
        )
      ) AS pizzas_ordered
    FROM
      pizza_runner.customer_orders AS c
    GROUP BY
      order_time
  ) AS count_dow
GROUP BY
  dow
ORDER BY
  pizzas_ordered DESC;
  
  