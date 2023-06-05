-- Use sales database
use sales;

-- 1)Checking the no. of records in each table:

SELECT	COUNT(*)
FROM	customers;
-- result: 38 records

SELECT	COUNT(*)
FROM	date;
-- result: 1126 records

SELECT	COUNT(*)
FROM	markets;
-- result: 17 records

SELECT	COUNT(*)
FROM	products;
-- result: 279 records

SELECT	COUNT(*)
FROM	transactions;
-- result: 150283 records

-- 2)Checking the transactions table:

SELECT	*
FROM	transactions;

-- looks like there are some records with sales amount -1 and currency as 'USD'.

-- 3)Records which have sales less than 0:

SELECT	*
FROM	transactions
WHERE	sales_amount <= 0;

-- 4)Number of records which are having sales amount less than 0:

SELECT	COUNT(*)
FROM	transactions
WHERE	sales_amount <= 0;

-- result: 1611 records

-- 5)Checking all the unique currency:

SELECT	DISTINCT(currency)
FROM	transactions;

-- there seems to be two unique value with their duplicates.

-- 6)Checking all the records with 'USD' currency:

SELECT	*
FROM	transactions
WHERE	currency in ('USD','USD\r');

-- records seems to be the duplicate records.

-- 7)Checking the customers table:

SELECT	*
FROM	customers;

-- 8)Checking the markets table:

SELECT	* 
FROM	markets;

-- there seems to be two markets namely 'New York' & 'Paris' which are based out of india.

-- 9)Checking if there are any transaction from these markets:

SELECT	*
FROM	transactions
WHERE	market_code in ('Mark097','Mark999');

-- there are no such records.

-- 10)Top 3 market according to the sales amount:

WITH marketwise_sales_ranking
as(
	SELECT	market_code, 
			markets_name, 
			round(SUM(sales_amount)/1000000,2) as total_sales_in_millions,
			RANK() OVER(ORDER BY SUM(sales_amount)/1000000 desc) as sales_rank
	FROM	transactions t
			INNER JOIN
			markets m
			on t.market_code = m.markets_code
	GROUP BY market_code
    )
SELECT	*
FROM	marketwise_sales_ranking
WHERE	sales_rank<=3;

-- result: Delhi NCR, Mumbai, Ahmedabad.

-- 11)Top 3 customer according to the sales amount:

WITH customerwise_sales_ranking
as(
	SELECT	t.customer_code, 
			c.custmer_name, 
			round(SUM(t.sales_amount)/1000000,2) as total_sales_in_millions,
			RANK() OVER(ORDER BY SUM(t.sales_amount)/1000000 desc) as sales_rank
	FROM	transactions t
			INNER JOIN
			customers c
			on t.customer_code = c.customer_code
	GROUP BY t.customer_code
    )
SELECT	*
FROM	customerwise_sales_ranking
WHERE	sales_rank<=3;

-- result: Electricalsara stores, Electricalslytical, Excel stores.

-- 12)Top 3 products sold according to the sales amount:

WITH productwise_sales_ranking
as(
	SELECT	t.product_code, 
			(CASE 
				WHEN p.product_type is null THEN 'Unavailable' 
                ELSE p.product_type 
			END) as product_type, 
			round(SUM(t.sales_amount)/1000000,2) as total_sales_in_millions,
			RANK() OVER(ORDER BY SUM(t.sales_amount)/1000000 desc) as sales_rank
	FROM	transactions t
			LEFT JOIN
			products p
			on t.product_code = p.product_code
	GROUP BY t.product_code
    )
SELECT	*
FROM	productwise_sales_ranking
WHERE	sales_rank<=3;

-- result: Prod318, Prod316, Prod324.


-- 13)Top 3 customer according to the sales amount in Delhi NCR market(Mark004), Mumbai(Mark002) and Ahmedabad(Mark003):

with marketwise_customer_ranking 
as(
	SELECT	t.market_code,
			m.markets_name,
			t.customer_code,
			c.custmer_name,
			round(SUM(t.sales_amount)/1000000,2) as total_sales_in_millions,
			RANK() OVER( PARTITION BY t.market_code ORDER BY SUM(t.sales_amount)/1000000 DESC) as sales_ranking
	FROM	transactions t
			LEFT JOIN
			markets m
			on t.market_code = m.markets_code
			LEFT JOIN
			customers c
			on t.customer_code = c.customer_code
	GROUP BY t.market_code, t.customer_code
	ORDER BY t.market_code
    )
SELECT	*
FROM	marketwise_customer_ranking
WHERE	market_code in ('Mark002','Mark003','Mark004') and sales_ranking<=3;

-- 14)Top 3 product according to the sales amount in Delhi NCR market(Mark004), Mumbai(Mark002) and Ahmedabad(Mark003):

with marketwise_product_ranking 
as(
	SELECT	t.market_code,
			m.markets_name,
			t.product_code,
			CASE WHEN p.product_type is null THEN "Unavailable" ELSE p.product_type END as product_type,
			round(SUM(t.sales_amount)/1000000,2) as total_sales_in_millions,
			RANK() OVER( PARTITION BY t.market_code ORDER BY SUM(t.sales_amount)/1000000 DESC) as sales_ranking
	FROM	transactions t
			LEFT JOIN
			markets m
			on t.market_code = m.markets_code
			LEFT JOIN
			products p
			on t.product_code = p.product_code
	GROUP BY t.market_code,t.product_code
	ORDER BY t.market_code
    )
SELECT	*
FROM	marketwise_product_ranking
WHERE	market_code in ('Mark002','Mark003','Mark004') and sales_ranking<=3;

-- 15) Top seasonal top 3 products:

WITH seasonal_product_ranking 
as(
	SELECT	seasons,
			t.product_code,
			(CASE
				WHEN p.product_type is null THEN "Unavailable"
				ELSE p.product_type
			END) as product_type,
			round(SUM(sales_amount)/1000000,2) as total_sales_in_millions,
			RANK() OVER(PARTITION BY seasons ORDER BY sum(sales_amount)/1000000 DESC) as sales_ranking
	FROM	transactions t
			LEFT JOIN
			products p
			on t.product_code = p.product_code
			LEFT JOIN
			(
			SELECT (CASE 
						WHEN month_name in ("December","January","February")	THEN "Winter"
						WHEN month_name in ("March","April","May") 				THEN "Spring"
						WHEN month_name in ("June","July","August")				THEN "Summer"
						WHEN month_name in ("September","October","November")	THEN "Fall"
						ELSE month_name
					END) as seasons,
					date
			FROM	date
			) as d
			on t.order_date = d.date
	GROUP BY t.product_code, seasons
)
SELECT *
FROM seasonal_product_ranking
WHERE sales_ranking <=3;

-- 16) Customer type wise top 3 products:

WITH customer_typewise_product_ranking
as(
	SELECT	c.customer_type,
			t.product_code,
			(CASE 
					WHEN p.product_type is null THEN 'Unavailable' 
					ELSE p.product_type 
			END) as product_type,
			round(sum(t.sales_amount)/1000000,2) as total_sales_in_millions,   
			RANK() OVER(PARTITION BY c.customer_type ORDER BY sum(t.sales_amount)/1000000 DESC) as sales_ranking
	 FROM	transactions t
			LEFT JOIN 
			customers c
			on t.customer_code = c.customer_code
			LEFT JOIN
			products p
			on t.product_code = p.product_code
	GROUP BY c.customer_type,t.product_code
    )
SELECT	*
FROM	customer_typewise_product_ranking
WHERE	sales_ranking <=3;

-- 17) Top 3 Most frequent customers (with highest no of orders):

SELECT	customer_code,
		count(customer_code) as num_of_orders,
        RANK() OVER(ORDER BY count(customer_code) DESC) as customer_ranking
FROM	transactions
GROUP BY customer_code
LIMIT 3;

