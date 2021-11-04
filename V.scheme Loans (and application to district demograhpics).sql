--This query returns the V scheme rankings based on the relative weighting of loan status
WITH cte AS (
SELECT loan_id, sumrate, PERCENT_RANK () OVER ( ORDER BY sumrate) AS p
FROM
(
SELECT loan_id, SUM(statusrate + durationrate + amtrank) AS  sumrate
FROM
(SELECT *, CASE						
WHEN [status] = 'A' THEN CAST ('12' AS INT)
WHEN [status] = 'B' THEN CAST ('0' AS INT)
WHEN [status] = 'C' THEN CAST ('8' AS INT)
WHEN [status] = 'D' THEN CAST ('4' AS INT)
ELSE 'unknown' 
END AS statusrate,
CASE 
WHEN duration = '12' THEN CAST ('0' AS INT)
WHEN duration = '24' THEN CAST ('3' AS INT)
WHEN duration = '36' THEN CAST ('6' AS INT)
WHEN duration = '48' THEN CAST ('9' AS INT)
WHEN duration = '60' THEN CAST ('12' AS INT)
END AS durationrate, 
CASE 
WHEN amount BETWEEN 0 AND 50000 THEN CAST ('0' AS INT)
WHEN amount BETWEEN 50000 AND 100000 THEN CAST ('2' AS INT)
WHEN amount BETWEEN 100000 AND 150000 THEN CAST ('4' AS INT)
WHEN amount BETWEEN 150000 AND 200000 THEN CAST ('6' AS INT)
WHEN amount BETWEEN 200000 AND 250000 THEN CAST ('8' AS INT)
WHEN amount BETWEEN 250000 AND 300000 THEN CAST ('10' AS INT)
WHEN amount BETWEEN 300000 AND 350000 THEN CAST ('12' AS INT)
WHEN amount > 350000 THEN CAST ('14' AS INT)
ELSE CAST ('0' AS INT)
END AS amtrank
FROM project.loan) AS t 
GROUP BY loan_id) AS t2
GROUP BY loan_id, sumrate
) 
SELECT loan_id, sumrate, CAST (p AS decimal(2,2)) AS [percentage], 
CASE 
WHEN CAST (p AS decimal(2,2)) <= 0.2 THEN CAST ('E' AS CHAR(1))
WHEN CAST (p AS decimal(2,2)) <= 0.4 THEN CAST ('D' AS CHAR(1))
WHEN CAST (p AS decimal(2,2)) <= 0.6 THEN CAST ('C' AS CHAR(1))
WHEN CAST (p AS decimal(2,2)) <= 0.8 THEN CAST ('B' AS CHAR(1))
WHEN CAST (p AS decimal(2,2)) <= 1 THEN CAST ('A' AS CHAR(1))
ELSE 'UNKNOWN'
END AS final_loanrate
FROM cte 
ORDER BY sumrate DESC



--We used this query to amalgamate the seperate V.scheme codes into one table
--However, this code requires each seperate query that gets the individual V.Scheme codes to be put into their own tables
SELECT DISTINCT spw.account_id, CONCAT (spw.grade, asr.[rank], COALESCE (lr.final_loanrate, '-')) AS customerrating
FROM project.spending_habits_work AS spw 
JOIN project.account_size_rank AS asr ON asr.account_id = spw.account_id
LEFT JOIN project.loanrate AS lr ON lr.account_id = spw.account_id
ORDER BY customerrating 


--This query creates a procedure that counts  v.scheme code distribution between different districts

CREATE PROCEDURE districtrate
(@district_name VARCHAR(50))
AS

SELECT TOP 10 tbl.district_name, tbl.habits_size_loan, tbl.[rank]
FROM
(SELECT t.district_name, t.habits_size_loan, DENSE_RANK() OVER (PARTITION BY t.district_name ORDER BY t.bigcnt DESC) AS [rank], t.cnt
FROM
(
SELECT A.district_name, A.habits_size_loan, (A.cnt*B.no_inhabitants) AS bigcnt, a.cnt
FROM
(SELECT d.district_name, v.habits_size_loan, COUNT(*) AS cnt
FROM project.account AS a
JOIN project.district AS d ON a.district_id = d.district_id
JOIN project.verityscheme AS v ON a.account_id = v.account_id
GROUP BY d.district_name, v.habits_size_loan) AS a
JOIN
(SELECT district_name, no_inhabitants from PROJECT.DISTRICT) AS b ON a.district_name = b.district_name) AS t) AS tbl
WHERE tbl.district_name = @district_name
GO 

--this executes the above query
EXEC districtrate @district_name = 'vsetin'

--this query gets the unemployment change for each district and ranks them
SELECT district_name, (unemployment_rate_96-unemployment_rate_95) as unemploymentgrowth, 
DENSE_RANK() OVER ( ORDER BY (unemployment_rate_96-unemployment_rate_95) DESC ) AS unemploymentchange_rnk
FROM project.district

--these queries use the same basic code to do the same as the above but in regards to salary, urban inhabitants and number of entrepeneurs respectively. 
SELECT district_name, average_salary, DENSE_RANK() OVER ( ORDER BY average_salary DESC ) AS salary_rnk
FROM project.district

SELECT district_name, ratio_urban_inhabitants, DENSE_RANK() OVER (ORDER BY ratio_urban_inhabitants DESC) AS urban_rnk FROM project.district

SELECT district_name, no_entrepeneurs_per_1000, DENSE_RANK () OVER (ORDER BY no_entrepeneurs_per_1000 DESC) AS entrepeneur_rnk FROM project.district
