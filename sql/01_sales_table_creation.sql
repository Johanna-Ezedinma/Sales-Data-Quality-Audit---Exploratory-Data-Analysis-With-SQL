-- ============================================================
-- Setup: load raw sales CSV('sales_data_sample'), 
-- Normalize into a relational schema
-- (Run once to prepare the database)
-- ============================================================

DROP TABLE IF EXISTS sales_data;

CREATE TABLE sales_data (
    order_number INT,
    quantity_ordered INT,
    price_each NUMERIC(10, 2),
    order_line_number INT,
    sales NUMERIC(12, 2),
    order_date TIMESTAMP,
    status VARCHAR(50),
    qtr_id INT,
    month_id INT,
    year_id INT,
    product_line VARCHAR(100),
    msrp INT,
    product_code VARCHAR(50),
    customer_name VARCHAR(150),
    phone VARCHAR(50),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(50),
    country VARCHAR(100),
    territory VARCHAR(50),
    contact_last_name VARCHAR(100),
    contact_first_name VARCHAR(100),
    deal_size VARCHAR(50)
);