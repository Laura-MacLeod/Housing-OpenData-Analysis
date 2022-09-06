/*
Author: Laura MacLeod
Date Uploaded: 06/09/2022

Aims:
1) Find the average houes prices for all boroughs in May 2018
2) Find the most expensive borough in May 2018 and May 1998
3) Find the most expensive month averaged over all locations
4) Which London borough has the highest population
5) Create a view showing the average house price over time monthly in Hammersmith and Fulham
6) Create a join connecting London boroughs' house prices and mean salaries in (May) 2018
7) Create view joining the house prices, salaries and populations from the separate monthly and yearly datasets
8) Create a procedure which displays the cheapest house price below a certain population density on a particular date
9) When and where in London were the most houses sold in a month
10) Find the average number of crimes per month grouped by borough
*/

CREATE DATABASE housing;
USE housing;

SELECT * FROM housing.monthly;
SELECT * FROM housing.yearly;


-- SELECT y.date, y.mean_salary, y.population_size FROM yearly y WHERE y.area='hammersmith and fulham';



-- 1) Find the average houes prices for all boroughs in May 2018

SELECT m.area, m.average_price
FROM monthly m 
WHERE m.date = '2018-06-01'
AND m.borough_flag = 1;


-- 2) Find the most expensive borough in May 2018 and May 1998

SELECT m.area, m.average_price
FROM monthly m 
WHERE m.date = '2018-06-01'
AND m.borough_flag = 1
AND m.average_price = (
	SELECT MAX(m.average_price) 
    FROM monthly m 
    WHERE m.date = '2018-06-01'
	AND m.borough_flag = 1
);

SELECT m.area, m.average_price
FROM monthly m 
WHERE m.date = '1998-06-01'
AND m.borough_flag = 1
AND m.average_price = (
	SELECT MAX(m.average_price) 
    FROM monthly m 
    WHERE m.date = '1998-06-01'
	AND m.borough_flag = 1
);


-- 3) Find the most expensive month averaged over all locations (see graph 2)

SELECT m.date, AVG(m.average_price)
FROM monthly m
GROUP BY m.date;


-- 4) Which London borough has the highest population

SELECT y.area, y.date, y.population_size
FROM yearly y
WHERE y.population_size = (
	SELECT MAX(y.population_size)
	FROM yearly y
    WHERE borough_flag = 1
    );


-- 5) Create a view showing the average house price over time monthly in Hammersmith and Fulham

CREATE OR REPLACE VIEW hamm_ful_housing AS
SELECT m.date, m.average_price
FROM monthly m
WHERE m.area = 'hammersmith and fulham';

SELECT * FROM hamm_ful_housing;



-- 6) Create a join connecting London boroughs' house prices and mean salaries in 2018

SELECT m.area, m.average_price, y.mean_salary
FROM monthly m
INNER JOIN yearly y
ON m.area = y.area
WHERE m.date = '2018-12-01'
AND m.borough_flag = 1
AND y.date = '2018-12-01'
AND y.borough_flag = 1;


-- 7) Create view joining the house prices, salaries and populations from the separate monthly and yearly datasets

-- Create a view displaying the relevant columns of the monthly table for London but only for the December of each year

CREATE OR REPLACE VIEW step1 AS
SELECT m.date, m.area, m.average_price
FROM monthly m
WHERE m.date LIKE '%-12-%'
AND borough_flag = 1
ORDER BY m.average_price;

SELECT * FROM step1;


-- Create a view displaying the relevant columns of the yearly table for London but only for the December of each year

CREATE OR REPLACE VIEW step2 AS
SELECT y.date, y.area, y.mean_salary, y.population_size, y.area_size
FROM yearly y
WHERE borough_flag = 1;

SELECT * FROM step2;


-- Create view joining the previous views on their dates so the house prices, salaries and populations can be seen together
-- Enumerate the joined view and order by ascending house price so rows can be iterated through according to index number
-- Rows are not included where there is incomplete data

CREATE OR REPLACE VIEW joined AS
SELECT ROW_NUMBER() OVER (ORDER BY average_price) 
		row_num, o.date, o.area, o.average_price, t.mean_salary, t.population_size, t.area_size
FROM step1 o
INNER JOIN step2 t
ON o.date=t.date
AND o.area=t.area
WHERE t.population_size != 0
AND t.area_size != 0;

SELECT * FROM joined;



-- 8) Create a procedure which displays the cheapest house price below a certain population density on a particular date

-- Procedure which gives a table of different boroughs at a certain date, with their population densities.
-- A column compares pop density with desired maximum density provided in inputs.
-- A select result displays the cheapest house price, so long as the population density is below the input value.

DELIMITER //
CREATE PROCEDURE cheapest(
	year VARCHAR(10),
    density INTEGER
    )
    
BEGIN

	SELECT 
		j.date, 
		j.area, 
        j.average_price, 
        j.population_size / j.area_size AS 'population density',
        (
			CASE WHEN (j.population_size / j.area_size) < density 
			THEN 'Population density lower than input value' 
			ELSE 'Population density higher than input value'
            END
		) AS 'higher or lower'
        	FROM joined j
	WHERE j.date = year;
	
    SELECT 
		j.date, 
		j.area,
        j.average_price, 
        j.population_size / j.area_size AS 'population density',
        (
			CASE WHEN (j.population_size / j.area_size) < density 
			THEN 'Population density lower than input value' 
			ELSE 'Population density higher than input value'
            END
		) AS 'higher or lower'
        	FROM joined j
	WHERE j.date = year
    AND j.average_price = (
			SELECT MIN(j.average_price) 
            FROM joined j 
            WHERE (j.population_size / j.area_size) < density 
            AND j.date = year
            );

END //
DELIMITER ;

DROP PROCEDURE cheapest;

CALL cheapest('2018-12-01', 40);




-- 9) When and where in London were the most houses sold in a month

SELECT m.date, m.area, m.houses_sold
FROM monthly m
WHERE m.houses_sold = (SELECT MAX(m.houses_sold) FROM monthly m WHERE m.borough_flag = 1)
AND m.borough_flag = 1;


-- 10) Find the average number of crimes per month grouped by borough

SELECT m.area, AVG(m.no_of_crimes)
FROM monthly m
GROUP BY m.area
HAVING AVG(m.borough_flag) = 1;


        
	
    
   

