/***********
8 Weeks SQL Challenge
************/

==============
-- Danny's Dinner
==============

-- 1. What is the total amount each customer spent at the restaurant?

select
s.customer_id, 
sum(m.price) as total_amout
from dannys_diner.sales s 
join 
dannys_diner.menu m 
on s.product_id = m.product_id
group by s.customer_id

-- 2. How many days has each customer visited the restaurant?

select 
customer_id, 
count(distinct order_date)
from dannys_diner.sales 
group by customer_id


-- 3. What was the first item from the menu purchased by each customer?

select 
	customer_id, 
    product_name 
from 
(
  select 
      s.customer_id, 
      s.order_date,
      s.product_id,
      m.product_name,
      dense_rank() over (partition by customer_id order by order_date asc) as rnk 
  from 
      dannys_diner.sales s 
  inner join 
      dannys_diner.menu m 
   on 
      s.product_id = m.product_id 

    order by s.customer_id, s.order_date, s.product_id
) a 
where rnk = 1

--Using CTE

with order_sales as 
(
select 
      s.customer_id, 
      s.order_date,
      s.product_id,
      m.product_name,
      dense_rank() over (partition by customer_id order by order_date asc) as rnk 
  from 
      dannys_diner.sales s 
  inner join 
      dannys_diner.menu m 
   on 
      s.product_id = m.product_id 

    order by s.customer_id, s.order_date, s.product_id

)
select 
	customer_id, 
	product_name
from 
	order_sales
where rnk = 1


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

with  pop_product
as
(
select 
product_id, 
count( product_id) as cnt
from 
	dannys_diner.sales s
group by product_id
)
select 
	m.product_name,
    pp.cnt
from
	pop_product pp 
 inner join 
 	dannys_diner.menu m
on pp.product_id = m.product_id
order by cnt desc limit 1
; 

-- using simple join 

SELECT 
  menu.product_name,
  COUNT(sales.product_id) AS most_purchased_item
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY most_purchased_item DESC
LIMIT 1;


-- 5. Which item was the most popular for each customer?

-- 5. Which item was the most popular for each customer?
with q1 as 
(
select 
	customer_id, s.product_id, m.product_name, count(s.product_id) as cnt
from dannys_diner.sales s
inner join 
	dannys_diner.menu m 
on s.product_id = m.product_id
group by customer_id, s.product_id, product_name
)
select 	
	customer_id, 
    product_name,
    cnt
from 
(
	select *, rank() over (partition by customer_id order by cnt desc) as rnk from q1
) q2 
	where rnk = 1


-- 6. Which item was purchased first by the customer after they became a member?

with q1 as 
(
select 
	s.customer_id, 
    s.order_date, 
    s.product_id, 
    mn.product_name,
    m.join_date as join_date, 
  	dense_rank() over (partition by s.customer_id order by order_date asc) rnk

from 
	dannys_diner.sales s 
 inner join 
 	dannys_diner.members m 
  on s.customer_id = m.customer_id
inner join 
	dannys_diner.menu mn
  on s.product_id = mn.product_id
where
	s.order_date > m.join_date
) 
select customer_id,product_name from q1
where rnk = 1

-- 7. Which item was purchased just before the customer became a member?


with q1 as 
(
select 
	s.customer_id, 
    s.order_date, 
    s.product_id, 
    mn.product_name,
    m.join_date as join_date, 
  	dense_rank() over (partition by s.customer_id order by order_date desc) rnk

from 
	dannys_diner.sales s 
 inner join 
 	dannys_diner.members m 
  on s.customer_id = m.customer_id
inner join 
	dannys_diner.menu mn
  on s.product_id = mn.product_id
where
	s.order_date < m.join_date
) 

select * from q1 
where rnk = 1


-- 8. What is the total items and amount spent for each member before they became a member?
 
 select 
  s.customer_id
    , sum(price) as tot_amt
    , count(s.product_id) as total_items
 from 
  dannys_diner.sales s 
 left outer join 
  dannys_diner.members m 
 on s.customer_id = m.customer_id 
 left outer join 
  dannys_diner.menu mn
 on s.product_id = mn.product_id 
 where
  s.order_date < m.join_date
group by s.customer_id
; 

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with q1 as
(
  select
      s.customer_id
      ,mn.product_name
      ,case when product_name = 'sushi' then mn.price*2*10 else mn.price*10 end as points
  from  
      dannys_diner.sales s
  left outer join 
      dannys_diner.members m 
   on s.customer_id = m.customer_id
  left outer join 
      dannys_diner.menu mn 
   on s.product_id = mn.product_id 
) 
select customer_id, sum(points) 
from q1
group by customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


with q1 as 
(
select
  s.customer_id, 
    s.order_date, 
    m.join_date, 
    s.product_id
from 
  dannys_diner.sales s 
left outer join 
  dannys_diner.members m 
on s.customer_id = m.customer_id 
where 
  s.order_date >= m.join_Date and s.order_date <= date(m.join_date + Interval '7 day')
) 

select 
  customer_id, 
    sum(2*10*m.price) as total_points
from q1 
inner join 
  dannys_diner.menu m
on q1.product_id = m.product_id
group by customer_id


-- Bonus Question 1: 

select 
  s.customer_id
    , s.order_date
    , mn.product_name
    , mn.price
    , case when s.order_date > m.join_date then 'Y' else 'N' end as member

from 
  dannys_diner.sales s 
left outer join 
  dannys_diner.members m 
 on s.customer_id = m.customer_id
left outer join 
  dannys_diner.menu mn 
 on s.product_id = mn.product_id 


 --Bonus question 2:

 with q1 as
(
  select 
      s.customer_id
      , s.order_date
      , mn.product_name
      , mn.price
      , case when s.order_date > m.join_date then 'Y' else 'N' end as member

  from 
      dannys_diner.sales s 
  left outer join 
      dannys_diner.members m 
   on s.customer_id = m.customer_id
  left outer join 
      dannys_diner.menu mn 
   on s.product_id = mn.product_id 
)
select  
  *
    , case when member = 'N' then Null else dense_rank() over(partition by customer_id, member order by order_date asc) end as ranking

from q1

