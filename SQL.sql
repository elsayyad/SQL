==================================
##### SubQueries / TMP Table #####
==================================

1- Use the test environment below to find the number of events that occure for each day for each channel

SELECT DATE_TRUNC('day',occurred_at) AS day, channel, COUNT(*) as event_count
FROM web_events
GROUP BY 1,2
ORDER BY 3 DESC

day	channel	event_count
2017-01-01T00:00:00.000Z	direct	21
2016-12-21T00:00:00.000Z	direct	21
2016-12-31T00:00:00.000Z	direct	19
------------------------------------------------------------------------------
2- Getting AVG via SUBQuery
SELECT channel, AVG(event_count) as avg_event_count
FROM(SELECT DATE_TRUNC('day',occurred_at) AS day,
     channel, COUNT(*) as event_count
     FROM web_events
     GROUP BY 1,2) sub
GROUP by 1
ORDER by 2 DESC;

channel	avg_event_count
direct	4.8964879852125693
organic	1.6672504378283713
facebook	1.5983471074380165
adwords	1.5701906412478336
twitter	1.3166666666666667
banner	1.2899728997289973
---------------------------------------------------------------
1- AVG Quantity for Each Type of Paper Order on specific Month (Dec 13)
SELECT AVG(standard_qty) AS std, AVG(poster_qty) AS poster, AVG(gloss_qty) AS gloss
FROM orders
WHERE DATE_TRUNC('month',occurred_at)=
(SELECT MIN(DATE_TRUNC('month',occurred_at))
     FROM orders)
std	                  poster	              gloss
268.2222222222222222	111.8181818181818182	208.9494949494949495
------------------------------------------------------------------------------
2- Total Ammount of Orders occured on specific Month (Dec 13)
SELECT SUM(total_amt_usd)
FROM orders
WHERE DATE_TRUNC('month', occurred_at) =
      (SELECT DATE_TRUNC('month', MIN(occurred_at)) FROM orders);

sum
377331.00

------------------------------------------------------------------------------

1- Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales.

SELECT s.name rep, r.name region, SUM(o.total_amt_usd) total_amt
        FROM accounts a
        JOIN orders o
        ON o.account_id=a.id
        JOIN sales_reps s
        ON s.id=a.sales_rep_id
        JOIN region r
        on r.id=s.region_id
        GROUP BY 1,2
        ORDER BY 3 DESC

rep	                region	  total_amt
Earlie Schleusner	  Southeast	1098137.72
Tia Amato	          Northeast	1010690.60
Vernita Plump	      Southeast	934212.93
Georgianna Chisholm	West	    886244.12
Arica Stoltzfus	    West	    810353.34
Dorotha Seawell	    Southeast	766935.04
Nelle Meaux	        Southeast	749076.16

SELECT  region, MAX(total_amt) total_amt
FROM
(SELECT s.name rep, r.name region, SUM(o.total_amt_usd) total_amt
        FROM accounts a
        JOIN orders o
        ON o.account_id=a.id
        JOIN sales_reps s
        ON s.id=a.sales_rep_id
        JOIN region r
        on r.id=s.region_id
        GROUP BY 1,2) tab2
GROUP BY 1
ORDER BY 2 DESC

region	  total_amt
Southeast	1098137.72
Northeast	1010690.60
West	    886244.12
Midwest	  675637.19

## JOINING BOTH TABLES ##

SELECT t1.rep, t3.region, t3.total_amt
FROM
(SELECT s.name rep, r.name region, SUM(o.total_amt_usd) total_amt
        FROM accounts a
        JOIN orders o
        ON o.account_id=a.id
        JOIN sales_reps s
        ON s.id=a.sales_rep_id
        JOIN region r
        on r.id=s.region_id
        GROUP BY 1,2
        ORDER BY 3 DESC) t1

JOIN

(SELECT  region, MAX(total_amt) total_amt
FROM
          (SELECT s.name rep, r.name region, SUM(o.total_amt_usd) total_amt
                  FROM accounts a
                  JOIN orders o
                  ON o.account_id=a.id
                  JOIN sales_reps s
                  ON s.id=a.sales_rep_id
                  JOIN region r
                  on r.id=s.region_id
                  GROUP BY 1,2) t2
GROUP BY 1
ORDER BY 2 DESC) t3

rep	                region	total_amt
Earlie Schleusner	  Southeast	1098137.72
Tia Amato	          Northeast	1010690.60
Georgianna Chisholm	West	886244.12
Charles Bidwell	    Midwest	675637.19

ON t3.region=t1.region AND t3.total_amt=t1.total_amt

2- For the region with the largest sales total_amt_usd, how many total orders were placed?
SELECT r.name, SUM(o.total) tota_orders
FROM sales_reps s
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
JOIN region r
ON r.id = s.region_id
GROUP BY 1
HAVING SUM(o.total_amt_usd)=( SELECT MAX(total_amt)
                              FROM( SELECT r.name, SUM(o.total_amt_usd) `total_amt`
                                    FROM sales_reps s
                                    JOIN accounts a
                                    ON a.sales_rep_id = s.id
                                    JOIN orders o
                                    ON o.account_id = a.id
                                    JOIN region r
                                    ON r.id = s.region_id
                                    GROUP BY 1)sub_max
                            );
name	    tota_orders
Northeast	1230378

3- For the name of the account that purchased the most (in total over their lifetime as a customer) standard_qty paper, how many accounts still had more in total purchases?
SELECT COUNT (*)
FROM
(SELECT a.name account
FROM accounts a
JOIN orders o
ON o.account_id=a.id
GROUP BY 1
HAVING SUM(o.total)>( SELECT  t1.total_purchases
                      FROM (SELECT a.name account, SUM(o.total) total_purchases, MAX(o.standard_qty) std_max
                      FROM accounts a
                      JOIN orders o
                      ON o.account_id=a.id
                      GROUP BY account
                      ORDER BY std_max DESC LIMIT 1)t1))count;

count
3

4- For the customer that spent the most (in total over their lifetime as a customer) total_amt_usd, how many web_events did they have for each channel?

SELECT w.account_id site_id, a.name account, w.channel channels, count(*) count
FROM web_events w
JOIN accounts a
ON w.account_id=a.id
GROUP BY 1,2,3
HAVING w.account_id=( SELECT cust_id
                      FROM( SELECT a.id cust_id, SUM(o.total_amt_usd) total_amt_usd
                            FROM accounts a
                            JOIN orders o
                            ON o.account_id=a.id
                            GROUP BY cust_id
                          ORDER BY 2 DESC LIMIT 1)top_cust_total
                    )
ORDER BY 4 DESC

site_id	 account	      channels	count
4211	   EOG Resources	direct	  44
4211	   EOG Resources	organic	  13
4211	   EOG Resources	adwords	  12
4211	   EOG Resources	facebook	11
4211	   EOG Resources	twitter	  5
4211	   EOG Resources	banner	  4

5- What is the lifetime average amount spent in terms of total_amt_usd for the top 10 total spending accounts?

SELECT AVG(total_amt_usd) total_avg
FROM( SELECT a.id, a.name account, SUM(o.total_amt_usd) total_amt_usd
      FROM orders o
      JOIN accounts a
      ON a.id=o.account_id
      GROUP BY 1,2
      ORDER BY 3 DESC
      LIMIT 10)top_ten_id

total_avg
304846.969000000000

6- What is the lifetime average amount spent in terms of total_amt_usd for only the companies that spent more than the average of all orders.

SELECT a.name account, AVG(o.total_amt_usd)
FROM orders o
JOIN accounts a
ON a.id=o.account_id
GROUP BY 1
HAVING AVG(o.total_amt_usd) > (SELECT AVG(total_amt_usd) total_avg_amt
                               FROM orders)
ORDER BY 2 DESC

account	avg
Pacific Life	19639.936923076923
Fidelity National Financial	13753.411250000000
Kohls	12872.165714285714
State Farm Insurance Cos.	12423.394444444444
AmerisourceBergen	9685.4525000000000000
CBS	8648.0700000000000000
Berkshire Hathaway	7474.3200000000000000


SELECT AVG(total_avg_amt) Total_Average
FROM( SELECT a.name account, AVG(o.total_amt_usd) total_avg_amt
      FROM orders o
      JOIN accounts a
      ON a.id=o.account_id
      GROUP BY 1
      HAVING AVG(o.total_amt_usd) > (SELECT AVG(total_amt_usd) total_avg_amt
                                     FROM orders)
      ORDER BY 2 DESC
    )sub
total_average
4721.1397439971747168

================================================================================
================================================================================

=============================
##### Windows Functions #####
=============================

SELECT standard_qty,
       DATE_TRUNC('month', occurred_at) AS month,
       SUM(standard_qty) OVER (PARTITION BY DATE_TRUNC('month', occurred_at) ORDER BY  occurred_at) AS running_total
FROM   orders

standard_qty	month	                    running_total
0	            2013-12-01T00:00:00.000Z	0
490	          2013-12-01T00:00:00.000Z	490
528	          2013-12-01T00:00:00.000Z	1018
0	            2013-12-01T00:00:00.000Z	1018
492	          2013-12-01T00:00:00.000Z	1510
502	          2013-12-01T00:00:00.000Z	2012
53	          2013-12-01T00:00:00.000Z	2065
308	          2013-12-01T00:00:00.000Z	2373
75	          2013-12-01T00:00:00.000Z	2448

1- create a running total of standard_amt_usd (in the orders table) over order time with no date truncation. Your final table should have two columns: one with the amount being added for each new row, and a second with the running total.

SELECT standard_amt_usd,
       SUM(standard_amt_usd) OVER (ORDER BY occurred_at) as running_total
FROM orders


standard_amt_usd	running_total
0.00	            0.00
2445.10	          2445.10
2634.72	          5079.82
0.00	            5079.82
2455.08	          7534.90
2504.98	          10039.88
264.47	          10304.35
1536.92	          11841.27

2- Modify your query from the previous quiz to include partitions. Still create a running total of standard_amt_usd (in the orders table) over order time, but this time, date truncate occurred_at by year and partition by that same year-truncated occurred_at variable.
Your final table should have three columns: One with the amount being added for each row, one for the truncated date, and a final columns with the running total within each year.



SELECT standard_amt_usd,
       DATE_TRUNC('year', occurred_at) as year,
       SUM(standard_amt_usd) OVER (PARTITION BY DATE_TRUNC('year', occurred_at) ORDER BY occurred_at) as running_total
FROM orders

standard_amt_usd	year						          running_total
0.00	        	  2013-01-01T00:00:00.000Z	0.00
2445.10	          2013-01-01T00:00:00.000Z	2445.10
2634.72				    2013-01-01T00:00:00.000Z	5079.82
0.00				      2013-01-01T00:00:00.000Z	5079.82
2455.08				    2013-01-01T00:00:00.000Z	7534.90
2504.98				    2013-01-01T00:00:00.000Z	10039.88
264.47				    2013-01-01T00:00:00.000Z	10304.35
1536.92				    2013-01-01T00:00:00.000Z	11841.27
374.25				    2013-01-01T00:00:00.000Z	12215.52
1402.19				    2013-01-01T00:00:00.000Z	13617.71
59.88				      2013-01-01T00:00:00.000Z	13677.59
2300.39				    2013-01-01T00:00:00.000Z	15977.98
2445.10				    2013-01-01T00:00:00.000Z	18423.08

3- Select the id, account_id, and total variable from the orders table, then create a column called total_rank that ranks this total amount of paper ordered (from highest to lowest) for each account using a partition.
 Your final table should have these four columns.

SELECT id, account_id, total,
       RANK() OVER (PARTITION BY account_id ORDER BY total DESC) AS total_rank
FROM orders

id	  account_id	total	total_rank
4308	1001	      1410	1
4309	1001	      1405	2
4316	1001	      1384	3
4317	1001	      1347	4
4314	1001	      1343	5
4307	1001	      1321	6
4311	1001	      1307	7
4310	1001	      1280	8


SELECT id,
       account_id,
       standard_qty,
       DATE_TRUNC('month', occurred_at) AS month,
       DENSE_RANK() OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS dense_rank,
       SUM(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS sum_std_qty,
       COUNT(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS count_std_qty,
       AVG(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS avg_std_qty,
       MIN(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS min_std_qty,
       MAX(standard_qty) OVER (PARTITION BY account_id ORDER BY DATE_TRUNC('month',occurred_at)) AS max_std_qty
FROM orders


id	  account_id standard_qty	            month	      dense_rank	sum_std_qty	          count_std_qty	avg_std_qty	min_std_qty	max_std_qty
1	    1001	     123	 2015-10-01T00:00:00.000Z	1	    123	  1	          123.0000000000000000	123	123
4307  1001	     506	 2015-11-01T00:00:00.000Z	2	    819	  3	          273.0000000000000000	123	506
2	    1001	     190	 2015-11-01T00:00:00.000Z	2	    819	  3	          273.0000000000000000	123	506
3	    1001	     85	   2015-12-01T00:00:00.000Z	3	    1430	5	          286.0000000000000000	85	526
4308	1001	     526	 2015-12-01T00:00:00.000Z	3	    1430	5	          286.0000000000000000	85	526
4309	1001	     566	 2016-01-01T00:00:00.000Z	4	    2140	7	          305.7142857142857143	85	566
4	    1001	     144	 2016-01-01T00:00:00.000Z	4	    2140	7	          305.7142857142857143	85	566
4310	1001	     473	 2016-02-01T00:00:00.000Z	5	    2721	9	          302.3333333333333333	85	566
5	    1001	     108	 2016-02-01T00:00:00.000Z	5	    2721	9	          302.3333333333333333	85	566
6	    1001	     103	 2016-03-01T00:00:00.000Z	6	    3322	11	        302.0000000000000000	85	566
4311	1001	     498	 2016-03-01T00:00:00.000Z	6	    3322	11	        302.0000000000000000	85	566
4312	1001	     497	 2016-04-01T00:00:00.000Z	7	    3920	13	        301.5384615384615385	85	566
7	    1001	     101	 2016-04-01T00:00:00.000Z	7	    3920	13	        301.5384615384615385	85	566
4313	1001	     483	 2016-05-01T00:00:00.000Z	8	    5120	17	        301.1764705882352941	85	566
8	    1001	     95	   2016-05-01T00:00:00.000Z	8	    5120	17	        301.1764705882352941	85	566
9	    1001	     91	   2016-05-01T00:00:00.000Z	8	    5120	17	        301.1764705882352941	85	566
4314	1001	     531	 2016-05-01T00:00:00.000Z	8	    5120	17	        301.1764705882352941	85	566
10	  1001	      94	 2016-06-01T00:00:00.000Z	9	    5214	18	        289.6666666666666667	85	566


SELECT id,
       account_id,
       standard_qty,
       DATE_TRUNC('month', occurred_at) AS month,
       DENSE_RANK() OVER (PARTITION BY account_id) AS dense_rank,
       SUM(standard_qty) OVER (PARTITION BY account_id) AS sum_std_qty,
       COUNT(standard_qty) OVER (PARTITION BY account_id) AS count_std_qty,
       AVG(standard_qty) OVER (PARTITION BY account_id) AS avg_std_qty,
       MIN(standard_qty) OVER (PARTITION BY account_id) AS min_std_qty,
       MAX(standard_qty) OVER (PARTITION BY account_id) AS max_std_qty
FROM orders


id	account_id	standard_qty	month	dense_rank	sum_std_qty	count_std_qty	avg_std_qty	min_std_qty	max_std_qty
14	  1001	97	2016-10-01T00:00:00.000Z	1	7896	28	282.0000000000000000	85	566
4318	1001	485	2016-11-01T00:00:00.000Z	1	7896	28	282.0000000000000000	85	566
4317	1001	507	2016-09-01T00:00:00.000Z	1	7896	28	282.0000000000000000	85	566
4316	1001	557	2016-08-01T00:00:00.000Z	1	7896	28	282.0000000000000000	85	566
4315	1001	457	2016-07-01T00:00:00.000Z	1	7896	28	282.0000000000000000	85	566
4314	1001	531	2016-05-01T00:00:00.000Z	1	7896	28	282.0000000000000000	85	566
4313	1001	483	2016-05-01T00:00:00.000Z	1	7896	28	282.0000000000000000	85	566
4312	1001	497	2016-04-01T00:00:00.000Z	1	7896	28	282.0000000000000000	85	566
4311	1001	498	2016-03-01T00:00:00.000Z	1	7896	28	282.0000000000000000	85	566
4310	1001	473	2016-02-01T00:00:00.000Z	1	7896	28	282.0000000000000000	85	566
4309	1001	566	2016-01-01T00:00:00.000Z	1	7896	28	282.0000000000000000	85	566

================================================================================
================================================================================

=============================
##### SQL DATA CLEANING #####
=============================

1- In the accounts table, there is a column holding the website for each company. The last three digits specify what type of web address they are using. A list of extensions (and pricing) is provided here. Pull these extensions and provide how many of each website type exist in the accounts table.

SELECT  RIGHT(website,3), COUNT(*)
FROM accounts
GROUP BY 1
right	count
net	  1
org	  1
com	  349

2- There is much debate about how much the name (or even the first letter of a company name) matters. Use the accounts table to pull the first letter of each company name to see the distribution of company names that begin with each letter (or number).

SELECT  LEFT(name,1), COUNT(*) FROM accounts
GROUP BY 1
ORDER BY 2 DESC

eft	count
C	37
A	37
P	27
M	22
S	17
T	17
D	17
B	16
L	16
E	15
N	15
H	15
G	14
U	13
W	12
F	12
R	8
J	7
K	7
O	7
I	7
V	7
X	2
3	1
Y	1
e	1
Q	1

3- Use the accounts table and a CASE statement to create two groups: one group of company names that start with a number and a second group of those company names that start with a letter. What proportion of company names start with a letter?

SELECT SUM(num) nums, SUM(letter) letters
FROM (SELECT name, CASE WHEN LEFT(UPPER(name), 1) IN ('0','1','2','3','4','5','6','7','8','9')
                       THEN 1 ELSE 0 END AS num,
         CASE WHEN LEFT(UPPER(name), 1) IN ('0','1','2','3','4','5','6','7','8','9')
                       THEN 0 ELSE 1 END AS letter
      FROM accounts) t1;
nums	letters
1	350

4- Consider vowels as a, e, i, o, and u. What proportion of company names start with a vowel, and what percent start with anything else?

SELECT SUM(vowel) vowels, SUM(others) others
FROM
(SELECT name, CASE WHEN LEFT(UPPER(name),1) IN ('A','E','I','O','U')
                  THEN 1 ELSE 0 END AS vowel,
             CASE WHEN LEFT(UPPER(name),1) IN ('A','E','I','O','U')
                  THEN 0 ELSE 1 END AS others
FROM accounts)t1

vowels	others
80	    271

================================================================================
================================================================================

============
## CONCAT ##
============
1- Each company in the accounts table wants to create an email address for each primary_poc. The email address should be the first name of the primary_poc . last name primary_poc @ company name .com.
2- You may have noticed that in the previous solution some of the company names include spaces, which will certainly not work in an email address. See if you can create an email address that will work by removing all of the spaces in the account name, but otherwise your solution should be just as in question 1. Some helpful documentation is here.

WITH full_name AS(SELECT name,LEFT(primary_poc, POSITION(' ' IN primary_poc)-1) AS first_name,
                         RIGHT(primary_poc, LENGTH(primary_poc) - POSITION(' ' IN primary_poc) ) AS last_name
                         FROM accounts)
SELECT CONCAT(first_name,'.',last_name,'@',replace(name,' ',''),'.com') AS "E-Mail"
FROM full_name

E-Mail
Tamara.Tuma@Walmart.com
Sung.Shields@ExxonMobil.com
Jodee.Lupo@Apple.com
Serafina.Banda@BerkshireHathaway.com
Angeles.Crusoe@McKesson.com
Savanna.Gayman@UnitedHealthGroup.com
Anabel.Haskell@CVSHealth.com
Barrie.Omeara@GeneralMotors.com
Kym.Hagerman@FordMotor.com
Jamel.Mosqueda@AT&T.com
Parker.Hoggan@GeneralElectric.com
Tuan.Trainer@AmerisourceBergen.com
Chantell.Drescher@Verizon.com
Paige.Bartos@Chevron.com
Dominique.Favela@Costco.com

3- We would also like to create an initial password, which they will change after their first log in.
The first password will be the first letter of the primary_poc first name (lowercase),
then the last letter of their first name (lowercase),
the first letter of their last name (lowercase),
the last letter of their last name (lowercase),
the number of letters in their first name,
the number of letters in their last name,
and then the name of the company they are working with, all capitalized with no spaces.



WITH full_name AS(SELECT name,primary_poc,LEFT(primary_poc, POSITION(' ' IN primary_poc)-1) AS first_name,
                         RIGHT(primary_poc, LENGTH(primary_poc) - POSITION(' ' IN primary_poc) ) AS last_name
                         FROM accounts)
SELECT primary_poc as "POC Full_Name",
CONCAT(
LEFT(LOWER(first_name),1),
RIGHT(LOWER(first_name),1),
LEFT(LOWER(last_name),1),
RIGHT(LOWER(last_name),1),
LENGTH(first_name),
LENGTH(last_name),
UPPER(replace(name,' ',''))
) AS Password
FROM full_name


POC Full_Name	password
Tamara Tuma	tata64WALMART
Sung Shields	sgss47EXXONMOBIL
Jodee Lupo	jelo54APPLE
Serafina Banda	saba85BERKSHIREHATHAWAY
Angeles Crusoe	asce76MCKESSON
Savanna Gayman	sagn76UNITEDHEALTHGROUP
Anabel Haskell	alhl67CVSHEALTH
Barrie Omeara	beoa66GENERALMOTORS
Kym Hagerman	kmhn38FORDMOTOR
Jamel Mosqueda	jlma58AT&T
Parker Hoggan	prhn66GENERALELECTRIC
Tuan Trainer	tntr47AMERISOURCEBERGEN
Chantell Drescher	cldr88VERIZON
Paige Bartos	pebs56CHEVRON
