use ecommerce;
/*1) The Head of Sales wants a high-level overview of the company's overall sales performance.
 Calculate the total number of orders, total units sold, total revenue, and average order value.
*/
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.qty) AS total_units_sold,
    SUM(oi.qty * oi.price) AS total_revenue,
    ROUND(
        SUM(oi.qty * oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id;
/*2)The Sales Director wants to understand how the company's sales are performing month by month. 
Calculate the monthly number of orders, total units sold, total revenue, and average order value.
*/
SELECT 
    MONTH(o.order_date) AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.qty) AS total_quantity,
    SUM(oi.qty * oi.price) AS total_revenue,
    ROUND(
        SUM(oi.qty * oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS avg_order_value
FROM orders o
INNER JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY MONTH(o.order_date)
ORDER BY month;

/*The Product Manager wants to identify the company's best-selling products based on the number of units sold.*/
SELECT 
    p.product_id,
    SUM(oi.qty) AS total_quantity_sold
FROM products p
INNER JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_id
ORDER BY total_quantity_sold DESC
LIMIT 10;

/*4)The Customer Analytics Manager wants to understand where the company's revenue
 is coming from and which customers are generating the most value.
Find the top 20 customers by total revenue, along with their city,
 number of orders, total units purchased, and total revenue.*/
 SELECT 
    c.customer_id,
    c.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.qty) AS total_units,
    SUM(oi.qty * oi.price) AS total_revenue
FROM customers c
INNER JOIN orders o 
    ON c.customer_id = o.customer_id
INNER JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.city
ORDER BY total_revenue DESC
LIMIT 20;

/*5)The Product Manager wants to know which product categories are driving the company's sales.
For each product category, calculate the number of products, total units sold, 
and total revenue. Then identify the top 10 categories by revenue.*/
SELECT
    c.category_id,
    c.category_name,
    COUNT(DISTINCT p.product_id) AS total_products,
    SUM(oi.qty) AS total_units_sold,
    SUM(oi.qty * oi.price) AS total_revenue
FROM categories c
INNER JOIN products p
    ON c.category_id = p.category_id
INNER JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    c.category_id,
    c.category_name
ORDER BY total_revenue DESC
LIMIT 10;
/*The Product Manager wants to identify the best-performing products within each category,
 rather than comparing every product across the entire company.
For each category, calculate the total revenue for every product and
 assign a revenue rank to each product within its category.*/
 WITH product_revenue AS (
    SELECT
        c.category_name,
        p.product_id,
        SUM(oi.qty * oi.price) AS total_revenue
    FROM categories c
    INNER JOIN products p
        ON c.category_id = p.category_id
    INNER JOIN order_items oi
        ON p.product_id = oi.product_id
    GROUP BY
        c.category_name,
        p.product_id
)
SELECT
    category_name,
    product_id,
    total_revenue,
    RANK() OVER (
        PARTITION BY category_name
        ORDER BY total_revenue DESC
    ) AS revenue_rank
FROM product_revenue
ORDER BY category_name, revenue_rank;

/*The CRM Manager wants a standardized customer location label for reporting.
Using the customers table, create a new column that combines the customer ID and city in the following format:
Customer-10025 | Chennai
Expected Output
customer_id	city	customer_location
10025	Chennai	Customer-10025 | Chennai
10026	Mumbai	Customer-10026 | Mumbai*/

SELECT
    customer_id,
    city,
    CONCAT('Customer-', customer_id, ' | ', city) AS customer_location
FROM customers;

/*The Product Manager wants to identify products that are performing better than the average product in terms of revenue.
Find all products whose total revenue is greater than the average total revenue of all products.*/
SELECT
    product_id,
    SUM(qty * price) AS total_revenue
FROM order_items
GROUP BY product_id
HAVING SUM(qty * price) > (
    SELECT AVG(product_revenue)
    FROM (
        SELECT
            product_id,
            SUM(qty * price) AS product_revenue
        FROM order_items
        GROUP BY product_id
    ) AS revenue_data
)
ORDER BY total_revenue DESC
limit 10;

/*The Sales Manager wants to compare monthly performance and identify which months generated the highest revenue.
Calculate the total revenue for each month and assign a rank to every month based on revenue, 
with the highest-revenue month receiving rank 1.*/
WITH monthly_revenue AS (
    SELECT
        MONTH(o.order_date) AS month,
        SUM(oi.qty * oi.price) AS total_revenue
    FROM orders o
    INNER JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY MONTH(o.order_date)
)
SELECT
    month,
    total_revenue,
    RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS revenue_rank
FROM monthly_revenue
ORDER BY revenue_rank;

/*The Regional Sales Manager wants to identify the highest-value customers within each city.
Calculate each customer's total revenue and rank customers within their city based on revenue.
 The highest-spending customer in each city should have rank 1.*/
 WITH customer_revenue AS (
    SELECT
        c.city,
        c.customer_id,
        SUM(oi.qty * oi.price) AS total_revenue
    FROM customers c
    INNER JOIN orders o
        ON c.customer_id = o.customer_id
    INNER JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        c.city,
        c.customer_id
)
SELECT
    city,
    customer_id,
    total_revenue,
    RANK() OVER (
        PARTITION BY city
        ORDER BY total_revenue DESC
    ) AS city_rank
FROM customer_revenue
ORDER BY city, city_rank;

/*The Procurement Manager wants to understand which suppliers are contributing the most to product sales.
For each supplier, find the supplier's country, number of products supplied, total units sold,
 and total revenue generated by those products. Return the top 10 suppliers based on total revenue.*/
 SELECT
    s.supplier_id,
    s.country,
    COUNT(DISTINCT p.product_id) AS total_products,
    SUM(oi.qty) AS total_units_sold,
    SUM(oi.qty * oi.price) AS total_revenue
FROM suppliers s
INNER JOIN products p
    ON s.supplier_id = p.supplier_id
INNER JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    s.supplier_id,
    s.country
ORDER BY total_revenue DESC
LIMIT 10;

/*The Marketing Manager wants to divide customers into spending segments for a targeted marketing campaign.
Calculate each customer's total spending and classify them into a customer segment based on their total revenue.
Business Rules
Total Revenue	Segment
≥ 50,000	High Value
20,000–49,999	Medium Value
< 20,000	Low Value*/
SELECT
    c.customer_id,
    SUM(oi.qty * oi.price) AS total_revenue,
    CASE
        WHEN SUM(oi.qty * oi.price) >= 50000 THEN 'High Value'
        WHEN SUM(oi.qty * oi.price) >= 20000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customers c
INNER JOIN orders o
    ON c.customer_id = o.customer_id
INNER JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_id
ORDER BY total_revenue DESC;

/*The Operations Manager wants to identify which stores are experiencing shipment problems.
For each store, calculate the total number of orders, the number of shipped orders, 
and the number of delayed orders. Then show the stores with the highest number of delayed orders.*/
SELECT
    s.store_id,
    s.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(CASE 
        WHEN sh.status = 'Shipped' THEN 1 
        ELSE 0 
    END) AS shipped_orders,
    SUM(CASE 
        WHEN sh.status = 'Delayed' THEN 1 
        ELSE 0 
    END) AS delayed_orders
FROM stores s
INNER JOIN orders o
    ON s.store_id = o.store_id
INNER JOIN shipments sh
    ON o.order_id = sh.order_id
GROUP BY
    s.store_id,
    s.city
ORDER BY delayed_orders DESC;

/*The Marketing Manager wants to understand which stores generate the most revenue from promotional orders.
For each store, calculate the number of promotional orders and the total revenue generated from those orders.
 Show the top 10 stores based on promotional revenue.*/
 SELECT
    s.store_id,
    s.city,
    COUNT(DISTINCT o.order_id) AS promotional_orders,
    SUM(oi.qty * oi.price) AS promotional_revenue
FROM stores s
INNER JOIN orders o
    ON s.store_id = o.store_id
INNER JOIN order_items oi
    ON o.order_id = oi.order_id
INNER JOIN promotions p
    ON o.promotion_id = p.promotion_id
GROUP BY
    s.store_id,
    s.city
ORDER BY promotional_revenue DESC
LIMIT 10;

/*The HR and Operations Manager wants to understand the employee cost associated with each store.
For each store, calculate the number of employees, total employee salary, average employee salary,
 and the store's total sales revenue. Then display the stores with the highest total revenue.*/
 WITH employee_data AS (
    SELECT
        store_id,
        COUNT(employee_id) AS employee_count,
        SUM(salary) AS total_salary,
        AVG(salary) AS avg_salary
    FROM employees
    GROUP BY store_id
),
store_sales AS (
    SELECT
        o.store_id,
        SUM(oi.qty * oi.price) AS total_revenue
    FROM orders o
    INNER JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.store_id
)
SELECT
    s.store_id,
    s.city,
    e.employee_count,
    e.total_salary,
    e.avg_salary,
    ss.total_revenue
FROM stores s
INNER JOIN employee_data e
    ON s.store_id = e.store_id
INNER JOIN store_sales ss
    ON s.store_id = ss.store_id
ORDER BY ss.total_revenue DESC;