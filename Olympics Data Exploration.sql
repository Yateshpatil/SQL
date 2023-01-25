
/*
I have practised SQL queries  on a real dataset. I downloaded  the 120 years of Olympics History dataset from Kaggle from the user rgriffin.
It is a historical dataset on the modern Olympic Games, including all the Games from Athens 1896 to Rio 2016. 
The dataset consists of 2 .csv files named athlete-events.csv and noc_regions.csv
The file athlete_events.csv contains 271116 rows and 15 columns. Each row corresponds to an individual athlete competing in an individual Olympic event (athlete-events).

I then created the database using PostgreSQL and created the 2 tables which can contain the 2 downloaded .csv file data. 
The data was then imported in PostgreSQL into those 2 created tables which were then used to solve some of the below queries.
*/

-- 1.nations who participated in all olympics
-- First I found out how many times olympics was played in the given data.
-- Then I found how many times each country has participated in olympics
-- Then I compared results of 1 and 2 and found out list of nations who particpated in olympics till date in the given data


WITH CTE1 AS(	
	select COUNT(DISTINCT(games)) as no_of_olympics
	from olympics_history oh
	join olympics_history_noc_regions nr on nr.noc = oh.noc),
CTE2 AS
(
	select region,COUNT(DISTINCT(region,games)) as no_of_times_country_particpated
	from olympics_history oh
	join olympics_history_noc_regions nr on nr.noc = oh.noc
	group by region
	order by COUNT(DISTINCT(region,games)) desc)


select region,CTE2.no_of_times_country_particpated from CTE2
join CTE1 
ON no_of_times_country_particpated=no_of_olympics;


-- 2.Identify the sport which was played in all summer olympics.

-- First I found out how many times olympics was played ins Summer in the given data.
-- Then I found how many times each country has participated in summer olympics
-- Then I compared results of 1 and 2 and found out list of nations who particpated in summer olympics till date in the given data


WITH CTE1 AS(
select count(distinct(games)) as no_of_summer_olympics
	from olympics_history oh
where season ilike '%summer%'),
CTE2 AS(
select sport,COUNT(distinct(games,sport)) as no_of_times
	from olympics_history oh
	where season ilike '%summer%' 
GROUP BY sport	
ORDER BY COUNT(distinct(games,sport)) DESC)

SELECT sport,no_of_times from CTE2 
JOIN CTE1 
on no_of_times=no_of_summer_olympics;


--  3.Find the Ratio of male and female athletes participated in all olympic games.
-- we need to consider same athelete even he/she has partcipated in more than 1 olympics as we want 
-- ratio for ally olympics
-- FIRST we get count of no of male participants and then female particpants
-- then we use cast to get decimal values and then round it of to 2 places

WITH m as(
		select COUNT((name)) as male_count from olympics_history
		where sex='M'),
 f as(
		select COUNT((name))as female_count from olympics_history
		where sex='F')


select ROUND(cast(male_count as decimal)/cast(female_count as decimal),2) 
from m,f;


-- 4. Fetch oldest athletes to win a gold medal
-- we can use this below approcah but it is bit hard coded as we have used LIMIT to get answer

select * from olympics_history
where medal='Gold' and age not in ('NA')
ORDER BY age DESC
LIMIT 2;

-- use of windows function is better as dont need to hardcode
-- we then extract the result using CTE

WITH CTE as(
			select *,
			DENSE_RANK() OVER(partition by medal order by age desc) as d_rnk
			from olympics_history
			WHERE medal='Gold'and age not in ('NA')
          )	
	SELECT * FROM CTE
	WHERE d_rnk=1;


-- 5.Fetch the top 5 athletes who have won the most gold medals.

-- First I found name of the athletes who won Gold
-- Then found out how many golds were won by each athlete
-- used dense_rank windows function to find top 5 atheletes as there are more than 1 athletes who have
-- won equal no of medals 

with t1 as(
	select name,medal from olympics_history
	where medal='Gold'),
t2 as(
	SELECT name,count(medal) as no_of_gold_medals,
	dense_rank() OVER(order by count(medal) DESC) as d_rnk
	from t1
	group by name
	order by no_of_gold_medals DESC)

select * from t2
where d_rnk <=5;


-- 6.Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

-- First I joined the history data with region to have nations name
-- Then filtered the data to find region and  medal in gold,silver,bronze category
-- Then found the no of medals won by each region (nations)
-- used dense_rank function to find 5 most successful countries in olympics.


WITH t1 AS (
		SELECT region,medal FROM olympics_history oh 
		JOIN olympics_history_noc_regions nr 
		ON nr.noc = oh.noc
		WHERE medal in ('Gold','Silver','Bronze')
	),
	t2 AS(
		SELECT region,COUNT(medal) as total_medals_won FROM t1
		GROUP BY region
		ORDER BY total_medals_won DESC
		),
	t3 AS(	
		SELECT region,total_medals_won,
		DENSE_RANK() OVER(ORDER BY total_medals_won DESC) as d_rnk
		FROM t2
		)
SELECT * FROM t3
where d_rnk<=5;


-- 7.List down total gold, silver and bronze medals won by each country.

-- Firstly I used join to connect history with region to have nations name
-- Then extracted region(nations) and medals having gold,silver,bronze status

WITH t1 As (
		SELECT region,medal FROM olympics_history oh 
		JOIN olympics_history_noc_regions nr 
		ON nr.noc = oh.noc
		WHERE medal in ('Gold','Silver','Bronze')
	),

-- Then found out how many medals are won by nation for each category
	t2 AS (
		SELECT region,medal,COUNT(medal) as total_medals FROM t1 
		GROUP BY region,medal 
		ORDER BY region, total_medals DESC
		),
		
-- I wanted to pivot the data so that i can have seperate gold,silver,bronze columns
-- For this I used CASE conditions, 
-- SUM was used as some categories may have only 1 value and rest as null so to avoid that null value

	t3 AS(	
SELECT region,
	   SUM(CASE WHEN medal='Gold' THEN total_medals END) AS Gold,
	   SUM(CASE WHEN medal='Silver' THEN total_medals END) AS Silver,
	   SUM(CASE WHEN medal='Bronze' THEN total_medals END) AS Bronze
	   from t2	
	   GROUP BY region
	   ORDER BY GOLD DESC		
	)
-- I found out that some of the nations have won in one or 2 categories and not compulsoraly in all 3 categories
-- to replace those null values i used Coalesce function which basically is repetative function and is used to replace that null with 0
-- Finally ordered the medals 
SELECT region,
	COALESCE(gold,0) as gold,
	COALESCE(silver,0) as silver,
	COALESCE(bronze,0) as bronze
FROM t3
ORDER BY gold DESC,silver desc,bronze desc;

-- 8.Fetch the total no of sports played in each olympic games.

select games,COUNT(DISTINCT sport) as no_of_games_played
from olympics_history
GROUP By games
order by no_of_games_played DESC;


-- 9.List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

-- Firstly I used join to connect history with region to have nations name
-- Then extracted  medals won by nations in every olympics having gold,silver,bronze status

WITH t1 AS(
		select games,region,medal from olympics_history oh
		join olympics_history_noc_regions nr 
		on nr.noc = oh.noc
		WHERE medal not in ('NA')
	),
-- Then found out how many (count) medals are won by nation in each olympics for each category

	t2 AS(
		SELECT games,region,medal,count(medal) as medals_won
		from t1
		GROUP BY games,region,medal
		ORDER BY games
		),
		
-- I wanted to pivot the data so that i can have seperate gold,silver,bronze columns
-- For this I used CASE conditions, 
-- SUM was used as some categories may have only 1 value and rest as null so to avoid that null value 		
	
	t3 AS(	
		SELECT games,region,
			SUM(CASE WHEN medal='Gold' THEN medals_won END) AS Gold,
			SUM(CASE WHEN medal='Silver' THEN medals_won END) AS Silver,
			SUM(CASE WHEN medal='Bronze' THEN medals_won END) AS Bronze
		from t2
		GROUP BY games,region
		)

-- I found out that some of the nations have won in one or 2 categories and not compulsoraly in all 3 categories
-- to replace those null values i used Coalesce function which basically is repetative function and is used to replace that null with 0

SELECT games,region,
	COALESCE(Gold,0) As Gold,
	COALESCE(Silver,0) As Silver,
	COALESCE(Bronze,0) As bronze
FROM t3;


--  10.Which countries have never won gold medal but have won silver/bronze medals?

-- Firstly, I found out how many different types of medals are won by each country including NA as if we neglect NA only gold,silver,bronze will remain which dosent make sense for this problem

WITH t1 AS(
	SELECT region,medal,COUNT(medal) as medals_won FROM olympics_history oh 
	join olympics_history_noc_regions nr on nr.noc = oh.noc
	GROUP BY region,medal
	),

-- I then wanted to do pivot to have gold,silver,bronze in columns
-- This also gave me null values in gold as some countries did not won any gold
	t2 AS(
	SELECT region,	
		SUM(CASE WHEN medal='Gold' THEN medals_won END) AS GOLD,
		SUM(CASE WHEN medal='Bronze' THEN medals_won END) AS Bronze,
		SUM(CASE WHEN medal='Silver' THEN medals_won END) AS Silver
	FROM t1	
	GROUP BY region
		),
-- The  coalesce function is used to replace those null values with 0		
		
	t3 AS(
	SELECT region,
		COALESCE(gold,0) as gold,
		COALESCE(bronze,0) as bronze,
		COALESCE(silver,0) as silver
	FROM t2	
		)
-- lastly filter is applied on the above table t3 to obtain the nations who never won and gold but have won atleast either of silver or bronze		
	
	SELECT region
	FROM t3 
	WHERE gold=0 and (bronze>0 or silver>0);
   
	

-- 11.In which Sport/event, India has won highest medals.

-- I first found out sports played by India medals won by them for those sports for entire data

WITH t1 AS(
	SELECT sport,medal FROM olympics_history oh 
	join olympics_history_noc_regions nr on nr.noc = oh.noc
	WHERE region='India' and medal!='NA'
	)
-- Then found out which sport won how many medals, used order by desc and found out the sport in which India won the most no of medals

	SELECT sport,COUNT(medal) as medals_won from t1
	group by sport
	ORDER BY medals_won DESC
	LIMIT 1;


-- 12. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

-- i found out the seasons in which India won medal in hockey 

WITH t1 AS(
	SELECT games,region,sport FROM olympics_history oh 
	join olympics_history_noc_regions nr on nr.noc = oh.noc
	WHERE region='India' AND sport='Hockey' AND medal !='NA'
	) 
-- Then just count the medals won in each season

	SELECT games,COUNT(sport) as medals_won from t1
	GROUP BY games
	ORDER BY medals_won DESC;
	

	




