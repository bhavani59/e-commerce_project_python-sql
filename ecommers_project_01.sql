create database ecommers;
use ecommers;

# BASIC QUESTION :

#1.List all unique cities where customers are located:
SELECT DISTINCT customer_city AS "Unique City" FROM customers_1;

#2.Count the number of orders placed in 2017.
SELECT COUNT(*) AS orders_2017
FROM orders_1
WHERE YEAR(order_purchase_timestamp) = 2017;

#3.Find the total sales per category: 
SELECT products.product_category AS category_name, SUM(payments_1.payment_value) AS total_sales
FROM payments_1
JOIN orders_1 ON payments_1.order_id = orders_1.order_id
JOIN order_items_1 ON orders_1.order_id = order_items_1.order_id
JOIN products ON order_items_1.product_id = products.product_id
GROUP BY products.product_category;

#4. Calculate the percentage of orders paid in installments.

SELECT 
    COUNT(DISTINCT CASE
            WHEN payment_installments > 1 THEN order_id
        END) * 100.0 / COUNT(DISTINCT order_id) AS installment_percentage
FROM
    payments_1;

#5.Count the number of customers from each state.
SELECT 
    customers_1.customer_state, 
    COUNT(*) AS customer_count
FROM 
    customers_1
GROUP BY 
    customers_1.customer_state;

#Intermediate Problems

# 1.Calculate the number of orders per month in 2018.

SELECT 
    MONTH(orders_1.order_purchase_timestamp) AS month, 
    COUNT(*) AS order_count
FROM 
    orders_1
WHERE 
    YEAR(orders_1.order_purchase_timestamp) = 2018
GROUP BY 
    MONTH(orders_1.order_purchase_timestamp);
    
# 2.Find the average number of products per order, grouped by customer city.

SELECT 
    customers_1.customer_city, 
    ROUND(AVG(order_items_1.order_item_id), 2) AS avg_products
FROM 
    order_items_1
JOIN 
    orders_1 
    ON order_items_1.order_id = orders_1.order_id
JOIN 
    customers_1 
    ON orders_1.customer_id = customers_1.customer_id
GROUP BY 
    customers_1.customer_city;

#3. Calculate the percentage of total revenue contributed by each product category.
SELECT 
    products.product_category, 
    ROUND((SUM(order_items_1.price) * 100.0) / (SELECT SUM(price) FROM order_items_1), 2) AS revenue_percentage
FROM 
    order_items_1
JOIN 
    products 
    ON order_items_1.product_id = products.product_id
GROUP BY 
    products.product_category;
    
#4.Identify the correlation between product price and the number of times a product has been purchased.

SELECT 
    products.product_category, 
    AVG(order_items_1.price) AS price,  
    COUNT(order_items_1.product_id) AS order_count
FROM 
    order_items_1
JOIN 
    products ON order_items_1.product_id = products.product_id
GROUP BY 
    products.product_category
ORDER BY 
    order_count DESC;

#5. Calculate the total revenue generated by each seller and rank them by revenue.

SELECT 
    order_items_1.seller_id,
    SUM(payments_1.payment_value) AS total_revenue,
    RANK() OVER (ORDER BY SUM(payments_1.payment_value) DESC) AS seller_rank
FROM 
    order_items_1
JOIN 
    payments_1 ON order_items_1.order_id = payments_1.order_id
GROUP BY 
    order_items_1.seller_id
ORDER BY 
    total_revenue DESC;
    
# ADVANCED PROBLEMS .  

#1. Calculate the moving average of order values for each customer over their order history.

SELECT 
    customer_orders.customer_id, 
    customer_orders.order_id, 
    AVG(customer_orders.order_value) OVER (PARTITION BY customer_orders.customer_id ORDER BY customer_orders.order_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_order_value
FROM (
    SELECT 
        orders_1.customer_id, 
        orders_1.order_id, 
        SUM(order_items_1.price) AS order_value, 
        orders_1.order_purchase_timestamp AS order_date
    FROM orders_1
    JOIN order_items_1 
        ON orders_1.order_id = order_items_1.order_id
    GROUP BY 
        orders_1.customer_id, 
        orders_1.order_id, 
        orders_1.order_purchase_timestamp
) customer_orders;
  
  #2. Calculate the cumulative sales per month for each year.
  SELECT 
    YEAR(orders_1.order_purchase_timestamp) AS year,
    MONTH(orders_1.order_purchase_timestamp) AS month,
    SUM(payments_1.payment_value) AS total_sales,
    SUM(SUM(payments_1.payment_value)) OVER (PARTITION BY YEAR(orders_1.order_purchase_timestamp) ORDER BY MONTH(orders_1.order_purchase_timestamp)) AS cumulative_sales
FROM 
    orders_1
JOIN 
    payments_1 ON orders_1.order_id = payments_1.order_id
GROUP BY 
    YEAR(orders_1.order_purchase_timestamp), MONTH(orders_1.order_purchase_timestamp)
ORDER BY 
    year, month;
  
 # 3. Calculate the year-over-year growth rate of total sales.
 SELECT 
    YEAR(orders_1.order_purchase_timestamp) AS year, 
    SUM(order_items_1.price) AS total_sales, 
    LAG(SUM(order_items_1.price)) OVER (ORDER BY YEAR(orders_1.order_purchase_timestamp)) AS previous_year_sales, 
    ((SUM(order_items_1.price) - LAG(SUM(order_items_1.price)) OVER (ORDER BY YEAR(orders_1.order_purchase_timestamp))) / LAG(SUM(order_items_1.price)) OVER (ORDER BY YEAR(orders_1.order_purchase_timestamp)) * 100) AS yoy_growth_rate
FROM 
    orders_1
JOIN 
    order_items_1 ON orders_1.order_id = order_items_1.order_id
GROUP BY 
    YEAR(orders_1.order_purchase_timestamp);
    
#4.. Calculate the retention rate of customers, defined as the percentage of customers who make another purchase within 6 months of their first purchase.    

SELECT 
    COUNT(DISTINCT retained.customer_id) AS retained_customers,
    COUNT(DISTINCT first_purchase.customer_id) AS total_first_time_customers,
    (COUNT(DISTINCT retained.customer_id) / COUNT(DISTINCT first_purchase.customer_id)) * 100 AS retention_rate
FROM 
    (SELECT 
        customer_id, 
        MIN(order_purchase_timestamp) AS first_purchase_date
    FROM orders_1
    GROUP BY customer_id) AS first_purchase
LEFT JOIN orders_1 AS retained 
    ON first_purchase.customer_id = retained.customer_id 
    AND retained.order_purchase_timestamp > first_purchase.first_purchase_date
    AND DATEDIFF(retained.order_purchase_timestamp, first_purchase.first_purchase_date) <= 180;
 
 #5. Identify the top 3 customers who spent the most money in each year.
 
 SELECT 
    yearly_customer_spending.year, 
    yearly_customer_spending.customer_id, 
    yearly_customer_spending.total_spent
FROM (
    SELECT 
        YEAR(orders_1.order_purchase_timestamp) AS year, 
        orders_1.customer_id, 
        SUM(order_items_1.price) AS total_spent, 
        RANK() OVER (PARTITION BY YEAR(orders_1.order_purchase_timestamp) ORDER BY SUM(order_items_1.price) DESC) AS `rank`
    FROM orders_1
    JOIN order_items_1 
        ON orders_1.order_id = order_items_1.order_id
    GROUP BY YEAR(orders_1.order_purchase_timestamp), orders_1.customer_id
) yearly_customer_spending
WHERE yearly_customer_spending.`rank` <= 3;












