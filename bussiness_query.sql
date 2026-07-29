select * from analytics_df;

SELECT SUM(price) AS total_revenue
FROM analytics_df;

SELECT COUNT(DISTINCT order_id) AS total_orders
FROM analytics_df;

SELECT COUNT(DISTINCT customer_unique_id) AS total_customers
FROM analytics_df;

SELECT COUNT(DISTINCT seller_id) AS total_sellers
FROM analytics_df;

SELECT
    ROUND(SUM(price)::NUMERIC / COUNT(DISTINCT order_id), 2) AS average_order_value
FROM analytics_df;

--Monthly revenue trend
SELECT
    purchase_year,
    purchase_month,
    SUM(price) AS monthly_revenue
FROM analytics_df
GROUP BY purchase_year, purchase_month
ORDER BY purchase_year, purchase_month;


--Repeat vs One-Time Customers
--Insight: Understand customer loyalty
select customer_unique_id,
    CASE
        WHEN COUNT(DISTINCT order_id) = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,
    COUNT(*) AS total_customers
FROM analytics_df
GROUP BY customer_unique_id
order by total_customers desc;

--Monthly order trend
SELECT
    purchase_year,
    purchase_month,
    COUNT(DISTINCT order_id) AS total_orders
FROM analytics_df
GROUP BY purchase_year, purchase_month
ORDER BY purchase_year, purchase_month;


--Revenue by State
SELECT
    customer_state,
    SUM(price) AS total_revenue
FROM analytics_df
GROUP BY customer_state
ORDER BY total_revenue DESC;


--Top Product Categories by Revenue
SELECT
    product_category_name,
    SUM(price) AS total_revenue
FROM analytics_df
GROUP BY product_category_name
ORDER BY total_revenue DESC
LIMIT 10;


--Top Product Categories by Items Sold
SELECT
    product_category_name,
    COUNT(order_item_id) AS items_sold
FROM analytics_df
GROUP BY product_category_name
ORDER BY items_sold DESC
LIMIT 10;

--Top 10 seller by revenue
SELECT
    seller_id,
    ROUND(SUM(price)::numeric,2) AS revenue
FROM analytics_df
GROUP BY seller_id
ORDER BY revenue DESC
LIMIT 10;


--Top 10 seller by no. of orders
SELECT
    seller_id,
    COUNT(DISTINCT order_id) AS total_orders
FROM analytics_df
GROUP BY seller_id
ORDER BY total_orders DESC
LIMIT 10;

--States with Lowest Customer Ratings
SELECT
    customer_state,
    ROUND(AVG(review_score)::numeric,2) AS avg_rating
FROM analytics_df
GROUP BY customer_state
ORDER BY avg_rating ASC;


--Seller ranks by revenue
SELECT
    seller_id,
    ROUND(SUM(price)::numeric,2) AS total_revenue,
    RANK() OVER(ORDER BY SUM(price) DESC) AS seller_rank
FROM analytics_df
GROUP BY seller_id
ORDER BY seller_rank;

WITH customer_revenue AS (
    SELECT
        customer_state,
        customer_unique_id,
        SUM(price) AS total_spent
    FROM analytics_df
    GROUP BY customer_state, customer_unique_id
)


--Top 5 Customers in Every State
WITH customer_revenue AS (
    SELECT
        customer_state,
        customer_unique_id,
        SUM(price) AS total_spent
    FROM analytics_df
    GROUP BY customer_state, customer_unique_id
)

SELECT *
FROM (
    SELECT
        customer_state,
        customer_unique_id,
        ROUND(total_spent::numeric,2) AS total_spent,
        ROW_NUMBER() OVER(
            PARTITION BY customer_state
            ORDER BY total_spent DESC
        ) AS rn
    FROM customer_revenue
) t
WHERE rn <= 5;


--Monthly Revenue Growth
WITH monthly_revenue AS (
    SELECT
        purchase_year,
        purchase_month,
        SUM(price) AS revenue
    FROM analytics_df
    GROUP BY purchase_year, purchase_month
)

SELECT
    purchase_year,
    purchase_month,
    ROUND(revenue::numeric,2) AS revenue,
    ROUND(
        LAG(revenue) OVER(
            ORDER BY purchase_year, purchase_month
        )::numeric,
        2
    ) AS previous_month,
    (
        (revenue - LAG(revenue) OVER(ORDER BY purchase_year,purchase_month))
        /
        LAG(revenue) OVER(ORDER BY purchase_year,purchase_month)
        *100
    ) AS growth_percentage
FROM monthly_revenue;

--Running Revenue (Cumulative Sales)
WITH monthly_revenue AS (
    SELECT
        purchase_year,
        purchase_month,
        SUM(price) AS revenue
    FROM analytics_df
    GROUP BY purchase_year,purchase_month
)

SELECT
    purchase_year,
    purchase_month,
    ROUND(revenue::numeric,2) AS revenue,
    ROUND(
        SUM(revenue) OVER(
            ORDER BY purchase_year,purchase_month
        )::numeric,
        2
    ) AS cumulative_revenue
FROM monthly_revenue;


--Late Delivery Percentage
SELECT
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN delivery_delay_days > 0 THEN 1
            ELSE 0
        END
    ) AS late_orders,
    ROUND(
        (
            SUM(
                CASE
                    WHEN delivery_delay_days > 0 THEN 1
                    ELSE 0
                END
            ) * 100.0 / COUNT(*)
        )::NUMERIC,
        2
    ) AS late_delivery_percentage
FROM analytics_df;
