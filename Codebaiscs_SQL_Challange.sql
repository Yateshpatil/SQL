-- 1.Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

-- Query:

SELECT DISTINCT market 
FROM dim_customer
WHERE customer='Atliq Exclusive' AND region='APAC';

-- Output: Following is the list of markets where Atliq operates its business in APAC region.

------------|
market      |
------------|
India       |
------------|
Indonesia   |
------------| 
Japan       |
------------|
Philiphines |
------------|
South Korea |
------------|
Australia   |
------------|
Newzealand  |
------------|
Bangladesh  |
------------|

--------------------------------------------------------------------------------------------------------------------------
-- 2.What is the percentage of unique product increase in 2021 vs. 2020? 
-- The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg

-- Approach:

-- First I found out distinct products for the fiscal year 2020 and made that query as CTE (t1)
-- Similary, I found out distinct products for the fiscal year 2021 and made that query also as CTE (t2)
-- then just extracted the required fields from the two tables and got the final output.

-- Query:

WITH t1 AS (
		SELECT COUNT(DISTINCT dp.product_code) AS unique_products_2020
		FROM dim_product dp
		JOIN fact_sales_monthly sm
		on dp.product_code=sm.product_code
		WHERE fiscal_year=2020
        ),
      t2 AS (  
		SELECT COUNT(DISTINCT dp.product_code) AS unique_products_2021
		FROM dim_product dp
		JOIN fact_sales_monthly sm
		on dp.product_code=sm.product_code
		WHERE fiscal_year=2021
        )
 SELECT  unique_products_2020,unique_products_2021,
 ROUND((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) AS percentage_chg
 FROM t1,t2
 
-- Output: so the no of unique products in 2021 has increased by 36.33% in comparision to last year.
 
|------------------------------------------------------------------------------------
| 	unique_product_count_2020 |	unique_product_count_2021 | percentage_chg  |	
|-----------------------------+-----------------------------------------------------|
|       245		          |	     334	          |    36.33	    |
-----------------------------------------------+------------------------------------|

-----------------------------------------------------------------------------------------------------------------------------

-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
-- The final output contains 2 fields segment and product_count

Query:

SELECT segment,COUNT(DISTINCT product_code) as product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

Output: Notebook segament has most number of unqiue products while networking has least.

------------------------------|
segment	         |product_count|
----------------------------- |
Notebook	 | 129        |
Accessories	 | 116        |
Peripherals	 | 84         |
Desktop	         | 32         |
Storage	         | 27         |
Networking	 | 9          |
------------------------------|
------------------------------------------------------------------------------------------------------------------------------------

-- 4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields segment,product_count_2020,product_count_2021,difference


-- Approach:

-- First I found out unique products for the fiscal year 2020 and made that query as CTE(t1)
-- Then found out unique products for the fiscal year 2021 and made that query as CTE(t2)
-- The took out the fields from two tables and also did subtraction between product_count_2021 and product_count_2020 and finally sorted the query by difference.

-- Query:

WITH t1 AS(
		SELECT segment,COUNT(DISTINCT dp.product_code) as product_count_2020
		FROM dim_product dp
		JOIN fact_sales_monthly sm
		ON dp.product_code=sm.product_code
		WHERE fiscal_year=2020
		GROUP BY segment
		ORDER BY segment
        ),
        t2 AS(
		SELECT segment,COUNT(DISTINCT dp.product_code) as product_count_2021
		FROM dim_product dp
		JOIN fact_sales_monthly sm
		ON dp.product_code=sm.product_code
		WHERE fiscal_year=2021
		GROUP BY segment
		ORDER BY segment
        )
 SELECT *, (product_count_2021-product_count_2020) as difference
 FROM t1 JOIN t2
 USING (segment)
 ORDER BY difference DESC
 
-- Output:  Accessories segment has the most increase in unqiue products as 34 new unique products were added to this segment which is most among all the segments.
 
---------------------------------------------------------------------------| 
  segment     | product_count_2020 |	product_count_2021 |	difference |
--------------|--------------------|-----------------------|---------------|  
Accessories   |          69	   |    103	           |   34          |
--------------|--------------------|-----------------------|---------------|
Notebook      |          92	   |    108	           |   16          |
--------------|--------------------|-----------------------|---------------|
Peripherals   |          59	   |     75	           |   16          |
--------------|--------------------|-----------------------|---------------|
Desktop	      |           7	   |     22	           |   15          |
--------------|--------------------|-----------------------|---------------|
Storage	      |          12	   |     17	           |    5          |
--------------|--------------------|-----------------------|---------------|
Networking    |           6	   |      9	           |   3           |
--------------|--------------------|-----------------------|---------------|

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 5.Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields product_code,product, manufacturing_cost

-- Approach:

-- First I joined the product and manufacturing cost tables
-- then used order by desc on manufacturing cost field to find product with highest cost
-- Similary found product with highest cost by using ORDER BY ASC
-- Then finally just made union of the two queries

-- Query:

(SELECT dp.product_code,product, manufacturing_cost
FROM dim_product dp
JOIN fact_manufacturing_cost mc
ON dp.product_code=mc.product_code
ORDER BY manufacturing_cost DESC
LIMIT 1)
UNION 
(SELECT dp.product_code,product, manufacturing_cost
FROM dim_product dp
JOIN fact_manufacturing_cost mc
ON dp.product_code=mc.product_code
ORDER BY manufacturing_cost 
LIMIT 1);

-- Output:  Product AQ HOME Allin1 Gen 2 has the higest manufacturing cost whereas AQ Master wired x1 Ms has the least.

-------------------------------------------|---------------------------|
product_code  |	       product	           |     manufacturing_cost    |
--------------|----------------------------|---------------------------|
A6120110206   |   AQ HOME Allin1 Gen 2	   |        240.5364           |
A2118150101   |   AQ Master wired x1 Ms	   |          0.8920           |
--------------|----------------------------|---------------------------|

-------------------------------------------------------------------------------------------------------------------------------------------

-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the
--    Indian market. The final output contains these fields customer_code,customer,average_discount_percentage.

-- Approach:

-- Firstly I found out avg of pre_invoice_discunt_pct from fact_pre_invoice_deductions to use this query later as subquery
-- Then joined 2 tables cutomer and pre_invoice_dedcutions
-- applied requried conditions in the where clause and also used earlier found query as subquery to find customers who have recevied more than avg pre invoice dedcutions
-- lastly used order by desc and limit 5 to find such top 5 customers

-- Query:

SELECT dc.customer_code,customer,pre_invoice_discount_pct as average_discount_percentage
FROM dim_customer dc
JOIN fact_pre_invoice_deductions id
USING (customer_code)
WHERE fiscal_year=2021 and market='India'
AND pre_invoice_discount_pct > (SELECT AVG(pre_invoice_discount_pct) 
								FROM fact_pre_invoice_deductions)
ORDER BY pre_invoice_discount_pct DESC
LIMIT 5;

-- Output: Below are the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 in Indian market

---------------------------------------------------------------|
customer_code |	 customer	|  average_discount_percentage |
---------------------------------------------------------------|
90002009      |   Flipkart	|     0.3083                   |
90002006      |   Viveks	|     0.3038                   |
90002003      |   Ezone	        |     0.3028                   |
90002002      |   Croma	        |     0.3025                   |
90002016      |   Amazon 	|     0.2933                   | 
--------------|-----------------|------------------------------|

--------------------------------------------------------------------------------------------------------------------------------------------------
-- 7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and
high-performing months and take strategic decisions. Tne final report should contain these columns Month,year,Gross sales amount

Apporach:

--  First I joined customer and sales monthly table using customer code
-- Then this table was joined to gross price table using two columns product_code,fiscal_year as same product has different price for different fiscal year
-- Applied the filter condition dor Atliq Exclusive
-- Found out sales amount as product of  sold_quantity and gross_price
-- treated this entire query as CTE(t1)

WITH t1 AS(
	SELECT date,fiscal_year,sold_quantity,gross_price,
	(sold_quantity*gross_price) as sales_amount
	FROM dim_customer dc
	JOIN fact_sales_monthly sm
	USING (customer_code)
	JOIN fact_gross_price gp
	USING (product_code,fiscal_year)
	WHERE customer like '%Atliq Exclusive%'
    ),
  
 --  then extracted month from fiscal year and treated this query as CTE(t2)
  
  t2 AS(  
		SELECT 
		MONTH(date) as month,fiscal_year,sales_amount
		FROM t1   
       )
 -- lastly used required columns month and fiscal year to find sum of sales amount using group by clause
 -- used round to limit decimal places
 
 SELECT month,fiscal_year,SUM(sales_amount) as gross_sales_amount
 FROM t2
 GROUP BY month,fiscal_year
 ORDER BY gross_sales_amount DESC,fiscal_year 
 
 -- Output: Gross sales amount for Atliq Exclusive was highest in November 2021 and was lowest in March 2020.
 
----------|-----------------|-----------------------|
month     |  fiscal_year    |   gross_sales_amount  |
------    |-------------    |-----------------------|
11	  |  2021	    |     20464999.10       |
10	  |  2021	    |     13218636.20       |
12	  |  2021	    |     12944659.65       |
1	  |  2021	    |     12399392.98       |
9	  |  2021	    |     12353509.79       |
5	  |  2021	    |     12150225.01       |
3	  |  2021	    |     12144061.25       |
7	  |  2021	    |     12092346.32       |
2	  |  2021	    |     10129735.57       |
6	  |  2021	    |      9824521.01       |
11	  |  2020	    |      7522892.56       |
4	  |  2021	    |      7311999.95       |
8	  |  2021	    |      7178707.59       |
10	  |  2020	    |      5135902.35       |
12	  |  2020	    |      4830404.73       |
1	  |  2020	    |      4740600.16       |
9	  |  2020	    |      4496259.67       |
2	  |  2020	    |      3996227.77       |
8	  |  2020	    |      2786648.26       |
7	  |  2020	    |      2551159.16       |
6	  |  2020	    |      1695216.60       |
5	  |  2020	    |       783813.42       |
4	  |  2020	    |       395035.35       |
3	  |  2020	    |       378770.97       |
----------------------------------------------------|
 
------------------------------------------------------------------------------------------------------------------------------------------------------------
8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains Quarter, total_sold_quantity sorted by the total_sold_quantity 

-- Approach:

-- Since there is date column directly I needed to use CASE to differentiate quarters as per month
-- applied where condition for the fiscal_year 2020
-- finally used aggregate function sum and group by to get final output

WITH t1 AS(
	SELECT date ,sold_quantity,fiscal_year,
	CASE 
		WHEN month(date) IN (9,10,11) Then 'Q1'
		WHEN month(date) IN (12,1,2) Then 'Q2'
		WHEN month(date) IN (3,4,5) Then 'Q3'
		WHEN month(date) IN (6,7,8) Then 'Q4'
	END AS Quarter
	FROM fact_sales_monthly
    WHERE fiscal_year=2020
    )
 SELECT Quarter,SUM(sold_quantity) AS total_sold_quantity
 FROM t1
 GROUP BY Quarter
 ORDER BY total_sold_quantity DESC

-- Output: Quarter 1 had the higest sold quantity for the fiscal_year 2020
---------------------------------|
Quarter	 |  total_sold_quantity  |
---------|-----------------------|
Q1	 |     7005619           |
Q2	 |     6649642           |
Q4	 |     5042541           |
Q3	 |     2075087           |
---------|-----------------------|
-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields channel,gross_sales_mln,percentage

-- Approach:
/*
-- Firstly I joined gross_sales and customer tables using customer code
-- the joined above obtained table to gross price using product code and fiscal year as product price is different for different fiscal year
-- applied the filter condtion for the fiscal year 2021
-- treated product of sold_quantity and gross_price as gross_sales
-- just extracted channel and gross sales column from here and treated this entire query as CTE(t1)
*/

WITH t1 AS(
		SELECT channel,
		(sold_quantity*gross_price) as gross_sales
		FROM dim_customer dc
		JOIN fact_sales_monthly sm
		USING (customer_code)
		JOIN fact_gross_price gp
		USING (product_code,fiscal_year)
		WHERE fiscal_year=2021
        ),
 /*       
 -- used aggregate fucntion sum on gross sales and used group by to find total sales that belong to each category
 -- to convert to million, I divided SUM(gross_sales) by 1000000
 -- Rounded it to 2 decimal places 
 -- treated this query as CTE(t2)
 */
 
        t2 AS
		(SELECT channel,ROUND(SUM(gross_sales)/1000000,2) as gross_sales_mln 
		FROM t1
		GROUP BY channel)

-- to find the contribution of each channel used subquery sum(gross_sales_mln)  to divide gross sales for each channel by total gross sales of all channels
-- treated that column as percentage

SELECT *, 
ROUND((gross_sales_mln)*100/(SELECT SUM(gross_sales_mln) from t2),2) as precentage 
FROM t2         

-- Output: Retailer channel has the higest contribution followed by Direct for the fiscal year 2021. Distributor had the least contribution for that fiscal year.

------------|------------------|-----------------|
channel	    | gross_sales_mln  |    precentage   |
------------|------------------|-----------------|
Direct	    |     257.53       |     15.47       |
------------|------------------|-----------------|
Retailer    |    1219.08       |     73.23       |
------------|------------------|-----------------|
Distributor |    188.03	       |    11.30        |
------------|------------------|-----------------|
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields division,product_code,product,
--     total_qty_sold,rank_order

-- Approach:

-- First joined 2 tables product and sales montly using product code
-- filtered to fiscal year 2021
-- found sum of sold_quantity using agg function and group by

WITH t1 AS(
	SELECT dp.division as division,
    dp.product_code,dp.product,SUM(sold_quantity) as total_qty_sold 
	FROM dim_product dp
	JOIN fact_sales_monthly sp
	ON dp.product_code=sp.product_code
	WHERE sp.fiscal_year=2021
    GROUP BY dp.division,dp.product_code,dp.product
    ),
 -- used windows function dense_rank to make partition of ranks based on total_sold_quantity desc
 
    t2 AS(
		SELECT *,
		DENSE_RANK() OVER(partition BY division ORDER BY total_qty_sold DESC) rank_order
		 FROM t1
         )
 
 -- applied filter to find top 3 ranks in each divison
 
  SELECT * FROM t2
  WHERE rank_order <4;
  
-- Output: Top 3 products in each division are as shown below

---------|------------------|---------------------------|-----------------------|-------------|
division | 	product_code|	   product	        |      total_qty_sold	|  rank_order |
---------|----------------- |---------------------------|-----------------------|-------------|
N & S	 |   A6720160103    |    AQ Pen Drive 2 IN 1	|          701373	|      1      |
N & S	 |   A6818160202    |	 AQ Pen Drive DRC	|          688003	|      2      |
N & S	 |   A6819160203    |	 AQ Pen Drive DRC	|          676245	|      3      |
---------|------------------|---------------------------|-----------------------|-------------|
P & A	 |   A2319150302    |    AQ Gamers Ms	        |          428498	|      1      |
P & A	 |   A2520150501    |    AQ Maxima Ms	        |          419865	|      2      |
P & A	 |   A2520150504    |    AQ Maxima Ms	        |          419471	|      3      |
---------|------------------|---------------------------|-----------------------|-------------|
PC	 |   A4218110202    |    AQ Digit	        |          17434	|      1      |
PC	 |   A4319110306    |    AQ Velocity	        |          17280	|      2      |
PC	 |   A4218110208    |    AQ Digit	        |          17275	|      3      |
---------|------------------|---------------------------|-----------------------|-------------|
----------------------------------------------------------------------------------------------------------------------------------------------------------------  
		






































