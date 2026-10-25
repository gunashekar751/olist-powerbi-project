CREATE DATABASE olist;
USE olist;

CREATE TABLE customers (
  customer_id VARCHAR(50) PRIMARY KEY,
  customer_unique_id VARCHAR(50),
  customer_zip_code_prefix VARCHAR(10),
  customer_city VARCHAR(100),
  customer_state CHAR(2)
);

CREATE TABLE sellers (
  seller_id VARCHAR(50) PRIMARY KEY,
  seller_zip_code_prefix VARCHAR(10),
  seller_city VARCHAR(100),
  seller_state CHAR(2)
);

CREATE TABLE products (
  product_id VARCHAR(50) PRIMARY KEY,
  product_category_name VARCHAR(100),
  product_name_length INT,
  product_description_length INT,
  product_photos_qty INT,
  product_weight_g INT,
  product_length_cm INT,
  product_height_cm INT,
  product_width_cm INT
);

CREATE TABLE category_translation (
  product_category_name VARCHAR(100) PRIMARY KEY,
  product_category_name_english VARCHAR(100)
);

CREATE TABLE orders (
  order_id VARCHAR(50) PRIMARY KEY,
  customer_id VARCHAR(50),
  order_status VARCHAR(20),
  order_purchase_timestamp DATETIME,
  order_approved_at DATETIME,
  order_delivered_carrier_date DATETIME,
  order_delivered_customer_date DATETIME,
  order_estimated_delivery_date DATETIME
);

CREATE TABLE order_items (
  order_id VARCHAR(50),
  order_item_id INT,
  product_id VARCHAR(50),
  seller_id VARCHAR(50),
  shipping_limit_date DATETIME,
  price DECIMAL(10,2),
  freight_value DECIMAL(10,2),
  PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE payments (
  order_id VARCHAR(50),
  payment_sequential INT,
  payment_type VARCHAR(30),
  payment_installments INT,
  payment_value DECIMAL(10,2)
);

CREATE TABLE reviews (
  review_id VARCHAR(50),
  order_id VARCHAR(50),
  review_score INT,
  review_comment_title TEXT,
  review_comment_message TEXT,
  review_creation_date DATETIME,
  review_answer_timestamp DATETIME
);

SHOW TABLES;

USE olist;
SELECT COUNT(*) FROM customers;

TRUNCATE TABLE customers;

SET GLOBAL local_infile = 1;

SET GLOBAL local_infile = 1;
USE olist;
TRUNCATE TABLE customers;

LOAD DATA LOCAL INFILE 'C:/Users/91984/Desktop/olist-powerbi-project/data/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM customers;

LOAD DATA LOCAL INFILE 'C:/Users/91984/Desktop/olist-powerbi-project/data/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM sellers;

LOAD DATA LOCAL INFILE 'C:/Users/91984/Desktop/olist-powerbi-project/data/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM category_translation;

LOAD DATA LOCAL INFILE 'C:/Users/91984/Desktop/olist-powerbi-project/data/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_category_name, @name_len, @desc_len, @photos, @weight, @length, @height, @width)
SET product_name_length = NULLIF(@name_len, ''),
    product_description_length = NULLIF(@desc_len, ''),
    product_photos_qty = NULLIF(@photos, ''),
    product_weight_g = NULLIF(@weight, ''),
    product_length_cm = NULLIF(@length, ''),
    product_height_cm = NULLIF(@height, ''),
    product_width_cm = NULLIF(@width, '');

SELECT COUNT(*) FROM products;

LOAD DATA LOCAL INFILE 'C:/Users/91984/Desktop/olist-powerbi-project/data/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, @purchase, @approved, @carrier, @delivered, @estimated)
SET order_purchase_timestamp = NULLIF(@purchase, ''),
    order_approved_at = NULLIF(@approved, ''),
    order_delivered_carrier_date = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@delivered, ''),
    order_estimated_delivery_date = NULLIF(@estimated, '');

SELECT COUNT(*) FROM orders;

LOAD DATA LOCAL INFILE 'C:/Users/91984/Desktop/olist-powerbi-project/data/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM order_items;

LOAD DATA LOCAL INFILE 'C:/Users/91984/Desktop/olist-powerbi-project/data/olist_order_payments_dataset.csv'
INTO TABLE payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM payments;

LOAD DATA LOCAL INFILE 'C:/Users/91984/Desktop/olist-powerbi-project/data/olist_order_reviews_dataset.csv'
INTO TABLE reviews
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(review_id, order_id, review_score, review_comment_title, review_comment_message, @created, @answered)
SET review_creation_date = NULLIF(@created, ''),
    review_answer_timestamp = NULLIF(@answered, '');

SELECT COUNT(*) FROM reviews;

SHOW WARNINGS;

SELECT review_score, COUNT(*) AS n
FROM reviews
GROUP BY review_score
ORDER BY review_score;

SELECT COUNT(*) AS missing_dates
FROM reviews
WHERE review_creation_date IS NULL;

SELECT COUNT(*) AS orphan_reviews
FROM reviews r
LEFT JOIN orders o ON o.order_id = r.order_id
WHERE o.order_id IS NULL;

SELECT order_status, COUNT(*) AS n
FROM orders
GROUP BY order_status
ORDER BY n DESC;

SELECT order_status, COUNT(*) AS missing_delivery
FROM orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status;

SELECT COUNT(*) AS bad_dates
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

SELECT COUNT(*) AS no_category
FROM products
WHERE product_category_name IS NULL OR product_category_name = '';

SELECT COUNT(*) AS multi_review_orders FROM (
  SELECT order_id FROM reviews GROUP BY order_id HAVING COUNT(*) > 1
) x;

WITH latest_review AS (
  SELECT order_id, review_score
  FROM (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_creation_date DESC) AS rn
    FROM reviews
  ) t
  WHERE rn = 1
),
delivered AS (
  SELECT
    o.order_id,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS delivery_days,
    CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
         THEN 'Late' ELSE 'On Time' END AS delivery_status
  FROM orders o
  WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
  d.delivery_status,
  COUNT(*) AS orders,
  ROUND(AVG(d.delivery_days), 1) AS avg_delivery_days,
  ROUND(AVG(lr.review_score), 2) AS avg_review_score
FROM delivered d
JOIN latest_review lr ON lr.order_id = d.order_id
GROUP BY d.delivery_status;