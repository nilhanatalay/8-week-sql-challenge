--1.What is the total amount each customer spent at the restaurant?

SELECT 
  sales.customer_id, 
  SUM(menu.price) as "total_amount" 
FROM 
  dannys_diner.sales 
  INNER JOIN dannys_diner.menu ON sales.product_id = menu.product_id 
GROUP BY 
  sales.customer_id 
ORDER BY 
  sales.customer_id;
  
  
--2.How many days each customer visited the restaurant?

SELECT 
  sales.customer_id, 
  COUNT(DISTINCT sales.order_date) as "days_visited" 
FROM 
  dannys_diner.sales 
GROUP BY 
  sales.customer_id 
ORDER BY 
  sales.customer_id;
  
  
--3. What was the first item from the menu purchased by each customer?

SELECT 
  DISTINCT ON (sales.customer_id) sales.customer_id, 
  menu.product_name 
FROM 
  dannys_diner.sales 
  JOIN dannys_diner.menu ON sales.product_id = menu.product_id 
ORDER BY 
  sales.customer_id, 
  sales.order_date, 
  sales.product_id;
  
  
--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
  
SELECT 
  menu.product_name AS "most_purchased_item", 
  COUNT(*) AS "total_orders" 
FROM 
  dannys_diner.sales 
  JOIN dannys_diner.menu ON sales.product_id = menu.product_id 
GROUP BY 
  menu.product_name 
ORDER BY 
  "total_orders" DESC 
LIMIT 
  1; 
  
--5. Which item was the most popular for each customer?

SELECT
  customer_id,
  product_name,
  COUNT(product_name) AS total_purchase_quantity
FROM
  sales AS s
  INNER JOIN menu AS m ON s.product_id = m.product_id
GROUP BY
  customer_id,
  product_name
ORDER BY
  total_purchase_quantity DESC
  
--6. Which item was purchased first by the customer after they became a member?

SELECT 
  customer_id, 
  first_order_date, 
  product_name 
FROM 
  (
    SELECT 
      s.customer_id, 
      s.order_date AS first_order_date, 
      m.product_name, 
      ROW_NUMBER() OVER (
        PARTITION BY s.customer_id 
        ORDER BY 
          s.order_date ASC
      ) AS order_number 
    FROM 
      dannys_diner.sales AS s 
      JOIN dannys_diner.menu AS m ON s.product_id = m.product_id 
      JOIN dannys_diner.members AS mem ON s.customer_id = mem.customer_id 
      AND s.order_date >= mem.join_date
  ) as sub 
WHERE 
  order_number = 1;

--7. Which item was purchased just before the customer became a member?

WITH orders as (
  SELECT 
    s.customer_id, 
    M.product_name, 
    s.order_date, 
    mem.join_date, 
    DENSE_RANK() OVER (
      PARTITION BY s.customer_id 
      ORDER BY 
        s.order_date
    ) as rank_num 
  FROM 
    dannys_diner.sales AS s 
    JOIN dannys_diner.menu AS M ON m.product_id = s.product_id 
    JOIN dannys_diner.members AS mem ON mem.customer_id = s.customer_id 
  WHERE 
    s.order_date < mem.join_date
) 
SELECT 
  customer_id, 
  product_name, 
  order_date, 
  join_date 
FROM 
  orders 
WHERE 
  rank_num = 1;
  
--8. What is the total items and amount spent for each member before they became a member?

SELECT 
  s.customer_id, 
  COUNT(s.product_id) AS total_items, 
  SUM(m.price) AS total_amount 
FROM 
  dannys_diner.sales s 
  JOIN dannys_diner.menu m ON s.product_id = m.product_id 
  LEFT JOIN dannys_diner.members mem ON s.customer_id = mem.customer_id 
  AND s.order_date >= mem.join_date 
WHERE 
  mem.customer_id IS NULL 
GROUP BY 
  s.customer_id 
ORDER BY 
  s.customer_id;
  
  
  
--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT 
  s.customer_id, 
  SUM(
    m.price * CASE WHEN m.product_name = 'sushi' THEN 2 ELSE 1 END
  ) AS total_amount_spent, 
  SUM(
    m.price * CASE WHEN m.product_name = 'sushi' THEN 2 ELSE 1 END
  ) * 10 AS total_points 
FROM 
  dannys_diner.sales s 
  JOIN dannys_diner.menu m ON s.product_id = m.product_id 
GROUP BY 
  s.customer_id 
ORDER BY 
  s.customer_id;
  
  
--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January

WITH members AS (
  SELECT 
    s.customer_id, 
    s.product_id, 
    order_date, 
    join_date 
  FROM 
    dannys_diner.sales s 
    INNER JOIN dannys_diner.members m ON s.customer_id = m.customer_id 
    AND s.order_date >= m.join_date
) 
SELECT 
  customer_id, 
  SUM(
    CASE WHEN order_date < join_date + INTERVAL '7 day' THEN price * 20 WHEN product_name = 'sushi' THEN price * 20 ELSE price * 10 END
  ) AS points 
FROM 
  members 
  INNER JOIN dannys_diner.menu USING (product_id) 
WHERE 
  order_date <= '2021-01-31' 
GROUP BY 
  customer_id 
ORDER BY 
  customer_id;
  
  
  
  
  
--Bonus Questions

--Join All The Things

SELECT 
  s.customer_id, 
  s.order_date, 
  M.product_name, 
  M.price, 
  CASE WHEN s.order_date >= mem.join_date THEN 'Y' ELSE 'N' END AS member 
FROM 
  dannys_diner.members AS mem 
  RIGHT JOIN dannys_diner.sales AS s ON s.customer_id = mem.customer_id 
  INNER JOIN dannys_diner.menu AS M ON M.product_id = s.product_id 
ORDER BY 
  s.customer_id, 
  s.order_date, 
  M.product_name;
  
  
--Rank All The Things

WITH member_check AS(
  SELECT 
    s.customer_id, 
    s.order_date, 
    product_name, 
    price, 
    CASE WHEN s.order_date >= join_date THEN 'Y' ELSE 'N' END AS member 
  FROM 
    dannys_diner.sales s 
    LEFT JOIN dannys_diner.menu as m ON s.product_id = m.product_id 
    LEFT JOIN dannys_diner.members AS mem ON s.customer_id = mem.customer_id
) 
SELECT 
  *, 
  CASE WHEN member = 'N' THEN NULL ELSE RANK() OVER(
    PARTITION BY customer_id, 
    member 
    ORDER BY 
      order_date
  ) END AS ranking 
FROM 
  member_check 
ORDER BY 
  customer_id, 
  order_date;
  
  
  
