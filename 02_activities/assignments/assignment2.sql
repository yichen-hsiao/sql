/*
###########################################
# UofT-DSI | SQL - Assignment 2
# Yi-Chen Hsiao
###########################################
*/


/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT 
product_name || ', ' || coalesce(product_size, '')|| ' (' || coalesce(product_qty_type,'unit') || ')'
FROM product;

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

--Select all rows with dense_rank()
--4221 rows

SELECT 

market_date, customer_id,
dense_rank() OVER(PARTITION BY customer_id ORDER BY market_date) as visit_number

FROM customer_purchases;

/* YCH: Method 2: only list unique 'market_date, customer_id combinations' with row_number()
--2018 rows

SELECT market_date, customer_id,
row_number() OVER(PARTITION BY customer_id ORDER BY market_date) as visit_number

FROM customer_purchases
GROUP BY market_date, customer_id;

*/

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

--outer QUERY

SELECT customer_id, market_date as recent_visit_date

FROM (
	--inner QUERY
	SELECT market_date, customer_id,
	row_number() OVER(PARTITION BY customer_id ORDER BY market_date DESC) as visit_number

	FROM customer_purchases
	GROUP BY market_date, customer_id
	) v
WHERE visit_number = 1;

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

-- Using a COUNT() window function: 4221 rows
SELECT *,
count() OVER(PARTITION BY customer_id, product_id) as purchase_count
FROM customer_purchases;

/* YCH: the other way, but result only havs 200 rows due to grouping

SELECT customer_id, product_id,
count(*) as purchase_count
FROM customer_purchases
GROUP BY customer_id, product_id;

*/



-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT product_name,
trim(substr(product_name, nullif(instr(product_name, '-'),0)), '- ') as description
FROM product;


/* YCH: steps breakdown

1. instr(product_name, '-') 
   --> purpose: return the index of '-' in string
   Note: if there's no '-' in string, the returned index value would be 0
2. nullif(instr(product_name, '-'),0)
   --> purpose: replace 0 with NULL
   Note: subtr(product_name, 0) will return full product_name --> not what we want here
         subtr(product_name, NULL) will return NULL
3. substr(product_name, nullif(instr(product_name, '-'),0))
   --> purpose: extract characters from the '-' to the end of string
4. trim(substr(product_name, nullif(instr(product_name, '-'),0)), '- ')
   --> purpose: remove '-' and ' ' from the extracted substring
   
*/


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT *,
trim(substr(product_name, nullif(instr(product_name, '-'),0)), '- ') as description
FROM product
WHERE product_size REGEXP '[0-9]';

/*YCH: another way
WHERE product_size REGEXP '\d';
*/

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

SELECT market_date, total_sales, 
CASE WHEN best_rank = 1 THEN 'Best day'
	 WHEN worst_rank = 1 THEN 'Worst day'
	 END as remark

FROM
	--renk total daily sales from highest to lowest
	(SELECT market_date, sum(quantity*cost_to_customer_per_qty) as total_sales,
	dense_rank() OVER (ORDER BY sum(quantity*cost_to_customer_per_qty) DESC) as best_rank,
	Null as worst_rank  --additional column for union purpose
	FROM customer_purchases
	GROUP BY market_date

	UNION
	
	--renk total daily sales from lowest to highest
	SELECT market_date, sum(quantity*cost_to_customer_per_qty) as total_sales,
	Null as best_rank,  --additional column for union purpose
	dense_rank() OVER (ORDER BY sum(quantity*cost_to_customer_per_qty)) as worst_rank
	FROM customer_purchases
	GROUP BY market_date)

WHERE best_rank = 1 or worst_rank =1;

/*YCH: Another way

DROP TABLE IF EXISTS temp.daily_sales_rank;

CREATE TABLE temp.daily_sales_rank AS
	SELECT
	market_date, 
	sum(quantity*cost_to_customer_per_qty) as total_sales,
	dense_rank() OVER(ORDER by sum(quantity*cost_to_customer_per_qty) DESC) as best_day_rank,
	dense_rank() OVER(ORDER by sum(quantity*cost_to_customer_per_qty)) as worst_day_rank
	FROM customer_purchases
	GROUP by market_date;

SELECT market_date, total_sales,
CASE WHEN best_day_rank = 1 THEN 'Best_day'
	 WHEN worst_day_rank = 1 THEN 'Worst_day'
	 END as remark
FROM daily_sales_rank
WHERE best_day_rank = 1 or worst_day_rank = 1;

 */

/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

SELECT vendor_name, product_name, sum(original_price * purchase_quantity) as total_sale_amount

FROM (
	(SELECT DISTINCT vendor_name, product_name, original_price
	FROM vendor_inventory as vi
	LEFT JOIN product as p
		ON vi.product_id = p.product_id
	LEFT JOIN vendor as v
		ON vi.vendor_id = v.vendor_id) x

	CROSS JOIN
		
	(SELECT distinct customer_id, 5 as purchase_quantity
	FROM customer) y
	)

Group BY vendor_name, product_name;


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS product_units;

CREATE TABLE product_units AS

SELECT *, datetime('now','localtime') as snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units
VALUES(24, 'Potato', 'large', 1, 'unit', datetime('now','localtime'));

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

--delete by timestamp, to delete the record I just inserted, delete the record with the newest timestamp
DELETE FROM product_units
WHERE snapshot_timestamp = (SELECT max(snapshot_timestamp) FROM product_units);

/* YCH: before deleting a record: 
(1) add the WHERE clause
(2) use SELECT to make sure the WHERE clause is written correctly

option 2- delete by product_id
	DELETE FROM product_units
	WHERE product_id = 24;
*/


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */


ALTER TABLE product_units
ADD current_quantity INT;



/* YCH: upon checking, one product only sold by one vendor, 
			SELECT distinct vendor_id, product_id
			FROM vendor_inventory;
        so, only need to partition rank of quantity by product_id, market_date
        no need to partition by vendor_id
*/

UPDATE product_units As pu
SET current_quantity = coalesce((SELECT quantity
FROM(
		SELECT product_id, quantity FROM 
		(
		 SELECT market_date,product_id,quantity,
		 dense_rank() OVER(PARTITION by product_id ORDER by market_date DESC) as latest_qty_rank
		 FROM vendor_inventory
		) 
		WHERE latest_qty_rank = 1
	) AS qty
	WHERE pu.product_id = qty.product_id),0); 
	
	/* 'WHERE pu.product_id = qty.product_id' should be inside of the coalesce () function, 
	   so when there's no match of product_id, it will retrun Nulls 
	   and then the coalesce function will convert Nulls to 0 */

	
	
/* YCH: Another way: use temp table
	
-- Create a temp table to hold the latest inventory qty values by product_id	
DROP TABLE if EXISTS temp.latest_inv_qty;

CREATE TABLE temp.latest_inv_qty AS

	SELECT product_id, quantity FROM 
		(
		 SELECT market_date,product_id,quantity,
		 dense_rank() OVER(PARTITION by product_id ORDER by market_date DESC) as latest_qty_rank
		 FROM vendor_inventory
		) 
		WHERE latest_qty_rank = 1;

-- update the current_quantity based on the quantity values from the temp table
UPDATE product_units As pu
SET current_quantity = coalesce((SELECT quantity FROM temp.latest_inv_qty as qty
WHERE pu.product_id = qty.product_id),0);

*/

