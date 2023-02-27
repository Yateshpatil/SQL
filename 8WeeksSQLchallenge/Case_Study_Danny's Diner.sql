-- 1.What is the total amount each customer spent at the restaurant?

Solution:

select customer_id,sum(price) as total_spent from sales s
join menu m on s.product_id=m.product_id
group by customer_id;

Output:
--------------------------|
customer_id | total_spent |
--------------------------|
  A	    |    76       |
  B	    |    74       |
  C	    |    36       |
------------|-------------|

------------------------------------------------------------------------------------------------

-- 2.	How many days has each customer visited the restaurant?

Solution:

select customer_id , count(distinct customer_id,order_date) as no_of_times_visited
from sales
group by customer_id

Output:

---------------------------------------|
customer_id	|  no_of_times_visited |
----------------|----------------------|
   A	        |           4          |
   B	        |           6          |
   C	        |           2          |
----------------|----------------------|
-------------------------------------------------------------------------------------------------

-- 3.	What was the first item from the menu purchased by each customer?

Solution:

with cte as(
select customer_id,product_name,
dense_rank() over(partition by customer_id order by order_date) as d_rnk
 from sales s 
join menu m on s.product_id=m.product_id
)

select distinct customer_id,product_name from cte
where d_rnk=1

Output:

-------------------------------
customer_id	| product_name |
----------------|--------------|
	A	|   sushi      |
	A	|   curry      |
	B	|   curry      |
	C	|   ramen      |
-------------------------------|
-------------------------------------------------------------------------------------------------

-- 4.	What is the most purchased item on the menu and how many times was it purchased by all customers?

Solution:

select product_name as most_purchased_item,count(1) as no_of_times_purchased
from sales s 
join menu m on s.product_id=m.product_id
group by product_name
order by no_of_times_purchased DESC
limit 1;

Output:

---------------------|------------------------|
most_purchased_item  |	no_of_times_purchased |
---------------------|------------------------|
	ramen	     |		   8          |
---------------------|------------------------|

-------------------------------------------------------------------------------------------------------

-- 5.	Which item was the most popular for each customer?
with cte as(
	select customer_id,product_name,count(*) as no_of_times_bought
	from sales s 
	join menu m on s.product_id=m.product_id
	group by customer_id,product_name
),
cte2 as(
	select *,
	dense_rank() over(partition by customer_id order by no_of_times_bought desc) as rn
	 from cte
 )
 
  select customer_id,product_name,no_of_times_bought
  from cte2
 where rn=1;

------------------------------------------------------------|
customer_id	|  product_name     |	no_of_times_bought  |
----------------|-------------------|-----------------------|
	A	|    ramen	    |		 3          |
	B	|    curry	    |	         2          |
	B	|    sushi	    |		 2          |
	B	|    ramen	    |		 2          |
	C	|    ramen	    |		 3          |
----------------|-------------------|-----------------------|
------------------------------------------------------------------------------------------------

-- 6.Which item was purchased first by the customer after they became a member?

Solution:

WITH cte as(
	select s.customer_id,s.order_date,m.product_name,join_date,
	dense_rank() over(partition by customer_id order by order_date) as rn
	from sales s
	join menu m on s.product_id=m.product_id
	join members mb on s.customer_id=mb.customer_id
	where order_date>=join_date
	order by s.customer_id
)

select customer_id,product_name 
from cte
where rn=1;

---------------------------------
customer_id	| product_name  |
----------------|---------------|
	A	|	curry   |
	B	|	sushi   |
----------------|---------------|
-------------------------------------------------------------------------------------------------

-- 7.Which item was purchased just before the customer became a member?

Solution:

with cte as(
	select s.customer_id,s.order_date,m.product_name,join_date,
    dense_rank() over(partition by customer_id order by order_date desc) as rn
	from sales s
	join menu m on s.product_id=m.product_id
	join members mb on s.customer_id=mb.customer_id
      where order_date<join_date
	order by s.customer_id
 )
 
 select customer_id,product_name
 from cte
 where rn=1

Output:

----------------------------|
customer_id |  product_name |
------------|---------------|
	A   |    sushi      |
	A   |    curry      |
	B   |    sushi      |
------------|---------------|

-----------------------------------------------------------------------------------------------
-- 8.	What is the total items and amount spent for each member before they became a member?

Solution:

with before_member as(
	select s.customer_id,s.order_date,m.product_name,join_date,price
	from sales s
	join menu m on s.product_id=m.product_id
	join members mb on s.customer_id=mb.customer_id
      where order_date<join_date
	order by s.customer_id
 )
 
 select customer_id,count(distinct product_name) as total_items,sum(price) as total_amount
 from before_member
 group by customer_id
 ORDER BY customer_id;

Output:

----------------------------------------------|
customer_id	|  total_items | total_amount |
----------------|--------------|--------------|
	A	|	2      |	 25   |
	B	|	2      |	 40   |
----------------|--------------|--------------|
------------------------------------------------------------------------------------------------------------------------------------------
-- 9.	If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

Solution:
	
with points_count as(
	select customer_id,s.product_id,price,
	case when product_name='sushi' then (20*price) else (10*price)
	end as points
	from sales s 
	join menu m on s.product_id=m.product_id
)

select customer_id,sum(points)
from points_count
group by customer_id
order by customer_id;

Output:

------------------------------|
customer_id	|  sum(points)|
----------------|-------------|
	A	|     860     |
	B	|     940     |
	C	|     360     |
----------------|-------------|
-------------------------------------------------------------------------------------------------------------------------------------------------

-- 10.	In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?

solution:

with cte as(
select s.customer_id,join_date,s.order_date,product_name,price,
date_add(join_date, Interval 7 day) as valid_date
from sales s
join menu m on s.product_id=m.product_id
join members mb on s.customer_id=mb.customer_id
where (order_date>=join_date)  and order_date <= '2021-01-31'
order by s.customer_id
),
cte2 as (
	select *,
	case when order_date between join_date and valid_date then 20*price
		 when order_date not between (join_date and valid_date) and product_name ='sushi' then 20*price
		 when order_date not between (join_date and valid_date) and product_name !='sushi' then 10*price
		 end as points
	 from cte
)

select customer_id,sum(points) as total_points from cte2
group by customer_id
order by customer_id;

Output:

----------------|--------------|
customer_id	| total_points |
----------------|--------------|
	A	|     1020     |
	B	|     440      |
----------------|--------------|
---------------------------------------------------------------------------------------------------------------------------------------------

Bonus Questions:

1. Join all the things - Recreate the following table output using the available data:

Solution:

with t1 as(
	select s.customer_id,order_date,product_name,price,join_date from sales s
	join menu m using(product_id)
	left join members mb on s.customer_id=mb.customer_id	
)

select customer_id,order_date,product_name,price,
case when order_date>=join_date then 'Y' else 'N' end as member
from t1;

----------------------------------------------------------------------------------------------------------------------------------------------------------

2. Ranking all the things: 

Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases 
so he expects null ranking values for the records when customers are not yet part of the loyalty program.

Solution:

with t1 as(
	select s.customer_id,order_date,product_name,price,join_date from sales s
	join menu m using(product_id)
	left join members mb on s.customer_id=mb.customer_id	
),
t2 as (
	select customer_id,order_date,join_date,product_name,price,
	case when order_date>=join_date then 'Y' else 'N' end as member
	from t1
	),
 t3 as(   
	 select *,
	 dense_rank() over(partition by customer_id order by order_date) as ranking
	 from t2   
	 where order_date>=join_date
	 order by customer_id
    )
    
 select t2.customer_id,t2.order_date,t2.join_date,t2.product_name,t2.price,ranking
 from t2
 left join t3 using (customer_id,order_date,join_date);
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
