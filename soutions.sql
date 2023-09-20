
SELECT * from dim_customer;
SELECT * from dim_product;
SELECT * from fact_gross_price;
SELECT * from fact_manufacturing_cost;
SELECT * from fact_pre_invoice_deductions;
SELECT * from fact_sales_monthly;


/*1) Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/

SELECT DISTINCT
    market
FROM
    gdb023.dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC';

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */

SELECT 
    f1.unique_products AS unique_products_2020,
    f2.unique_products AS unique_products_2021,
    ((f2.unique_products - f1.unique_products) / f1.unique_products) * 100 AS percentage_chg
FROM
    (SELECT 
        COUNT(DISTINCT product_code) AS unique_products, fiscal_year
    FROM
        fact_gross_price
    GROUP BY fiscal_year) AS f1,
    (SELECT 
        COUNT(DISTINCT product_code) AS unique_products, fiscal_year
    FROM
        fact_gross_price
    GROUP BY fiscal_year) AS f2
WHERE
    f1.fiscal_year < f2.fiscal_year;


/*3 Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_coun*/

SELECT 
    segment, COUNT(DISTINCT product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;

/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference*/

SELECT 
    s1.segment,
    s1.unique_prodcut AS unique_prodcuts_2020,
    s2.unique_prodcut AS unique_prodcuts_2021,
    s2.unique_prodcut - s1.unique_prodcut AS difference
FROM
    (SELECT 
        d.segment,
            COUNT(DISTINCT d.product_code) AS unique_prodcut,
            f.fiscal_year
    FROM
        dim_product d
    INNER JOIN fact_gross_price f ON d.product_code = f.product_code
    GROUP BY d.segment , f.fiscal_year) s1,
    (SELECT 
        d.segment,
            COUNT(DISTINCT d.product_code) AS unique_prodcut,
            f.fiscal_year
    FROM
        dim_product d
    INNER JOIN fact_gross_price f ON d.product_code = f.product_code
    GROUP BY d.segment , f.fiscal_year) s2
WHERE
    s1.fiscal_year < s2.fiscal_year
        AND s1.segment = s2.segment
ORDER BY difference DESC
LIMIT 1;

/* 5 Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost*/

SELECT 
    d.product_code, d.product, f.manufacturing_cost
FROM
    dim_product d
        JOIN
    fact_manufacturing_cost f ON d.product_code = f.product_code
WHERE
    f.manufacturing_cost = (SELECT 
            MAX(manufacturing_cost) AS maxmimum
        FROM
            fact_manufacturing_cost)
        || f.manufacturing_cost = (SELECT 
            MIN(manufacturing_cost) AS mimium
        FROM
            fact_manufacturing_cost);

/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage*/


SELECT 
    d.customer_code,
    d.customer,
    ROUND((AVG(f.pre_invoice_discount_pct) * 100),
            2) AS average_discount_percentage
FROM
    dim_customer d
        INNER JOIN
    fact_pre_invoice_deductions f ON d.customer_code = f.customer_code
WHERE
    f.fiscal_year = 2021
        AND d.market = 'India'
GROUP BY d.customer_code , d.customer
ORDER BY AVG(f.pre_invoice_discount_pct) DESC
LIMIT 5;

/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount*/

SELECT 
    MONTHNAME(date) AS 'MonthDate',
    YEAR(date) AS 'YearDAte',
    SUM(sold_quantity * gross_price) AS 'Gross sales Amount'
FROM
    fact_sales_monthly fs
        INNER JOIN
    fact_gross_price fg ON fs.product_code = fg.product_code
        INNER JOIN
    dim_customer d ON fs.customer_code = d.customer_code
WHERE
    d.customer = 'Atliq Exclusive'
GROUP BY MonthDate , YearDate;


/*8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantit*/

SELECT 
    CASE
        WHEN SUBSTRING(MONTHNAME(date), 1, 3) IN ('Jan' , 'Feb', 'Mar') THEN 'Q1 of 2020'
        WHEN SUBSTRING(MONTHNAME(date), 1, 3) IN ('Apr' , 'May', 'Jun') THEN 'Q2 of 2020'
        WHEN SUBSTRING(MONTHNAME(date), 1, 3) IN ('Jul' , 'Aug', 'Sep') THEN 'Q3 of 2020'
        WHEN SUBSTRING(MONTHNAME(date), 1, 3) IN ('Oct' , 'Nov', 'Dec') THEN 'Q4 of 2020'
    END AS Quarter1,
    SUM(sold_quantity) AS maxmimum_total
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020
GROUP BY Quarter1
ORDER BY maxmimum_total DESC
LIMIT 1;

/*9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage*/

select d.channel as channel1, sum(fg.gross_price*fs.sold_quantity) as total_gross from fact_sales_monthly fs inner join fact_gross_price fg on fs.product_code=fg.product_code inner join dim_customer d on fs.customer_code=d.customer_code where fs.fiscal_year=2021 group by d.channel;


/*select @total :=0;
select @total := sum(fg.gross_price*fs.sold_quantity) from fact_sales_monthly fs inner join fact_gross_price fg on fs.product_code = fg.product_code where fs.fiscal_year=2021; */

SELECT 
    dc.channel,
    SUM(fg.gross_price * fs.sold_quantity) AS total_sales,
    (SUM(fg.gross_price * fs.sold_quantity) / @total) * 100 AS per
FROM
    dim_customer dc
        INNER JOIN
    fact_sales_monthly fs ON dc.customer_code = fs.customer_code
        INNER JOIN
    fact_gross_price fg ON fg.product_code = fs.product_code
WHERE
    fs.fiscal_year = 2021
GROUP BY dc.channel
ORDER BY per DESC
LIMIT 1;

/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order*/


select * from 
(select t.division,t.product_code,t.product, t.total_sales, row_number () over (partition by t.division order by t.total_sales desc) as rankk from 
(SELECT 
    d.division,
    d.product_code,
    d.product,
    SUM(sold_quantity) AS total_sales
FROM
    dim_product d
        INNER JOIN
    fact_sales_monthly fs ON d.product_code = fs.product_code
WHERE
    fiscal_year = 2021
GROUP BY d.division , d.product_code , d.product)t ) t1
 where rankk <=3;
 

    









