-- ===========================================================
-- NORMALIZATION & SCHEMA CREATION 
--------------------------------------------------------------
-- Normalizing into customers, products, orders, order_items
-- ============================================================

DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;


-- ============================================================
-- Customers Table
-- ============================================================
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(150) UNIQUE NOT NULL, 
    contact_first_name VARCHAR(100),
    contact_last_name VARCHAR(100),
    phone VARCHAR(50),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(50),
    country VARCHAR(100),
    territory VARCHAR(50)
);

-- ============================================================
-- Products Table
-- ============================================================
CREATE TABLE products (
    product_code VARCHAR(50) PRIMARY KEY, 
    product_line VARCHAR(100),
    msrp INT
);

-- ============================================================
-- Orders Table
-- ============================================================
CREATE TABLE orders (
    order_number INT PRIMARY KEY, 
    customer_id INT REFERENCES customers(customer_id),
    order_date TIMESTAMP, 
    status VARCHAR(50),
    qtr_id INT,
    month_id INT,
    year_id INT,
    deal_size VARCHAR(50)
);

-- ============================================================
-- Order Items Table 
-- ============================================================
CREATE TABLE order_items (
    order_number INT REFERENCES orders(order_number),
    order_line_number INT,
    product_code VARCHAR(50) REFERENCES products(product_code),
    quantity_ordered INT,
    price_each NUMERIC(10, 2), 
    sales NUMERIC(12, 2),      
    PRIMARY KEY (order_number, order_line_number)
);

-- ======================================================================
-- POPULATING
-- ======================================================================
-- Customers (Using DISTINCT so each company appears once)

INSERT INTO customers (customer_name, contact_first_name, contact_last_name, phone,
                      address_line1, address_line2, city, state, postal_code, country, territory)
SELECT DISTINCT 
    customer_name, contact_first_name, contact_last_name, phone,
    address_line1, address_line2, city, state, postal_code, country, territory
FROM sales_data;

----------------------------------------------------------------------------------

-- Products (Each product code is listed once)
INSERT INTO products (product_code, product_line, msrp)
SELECT DISTINCT product_code, product_line, msrp
FROM sales_data;

----------------------------------------------------------------------------------------

-- (Linking each order back to its unique customer_id via a JOIN)
-- using DISTINCT ON forces one row per order number
INSERT INTO orders (order_number, customer_id, order_date, status, qtr_id, month_id, year_id, deal_size)
SELECT DISTINCT ON 
  (s.order_number)
    s.order_number, 
    c.customer_id, 
    s.order_date, 
    s.status, 
    s.qtr_id, 
    s.month_id, 
    s.year_id, 
    s.deal_size
FROM sales_data s
JOIN customers c ON c.customer_name = s.customer_name
ORDER BY s.order_number;

--------------------------------------------------------------------------------

-- Order Items (The line-by-line transaction details)
INSERT INTO order_items (order_number, order_line_number, product_code, quantity_ordered, price_each, sales)
SELECT order_number, order_line_number, product_code, quantity_ordered, price_each, sales
FROM sales_data;

-- ==================================================================================



-- ============================================================================
-- SCHEMA VALIDATION
-- ========================================================
SELECT 'original_flat_table' AS table_name, COUNT(*) FROM sales_data
UNION ALL 
SELECT 'normalized_order_items', COUNT(*) FROM order_items;


-- ============================================================================
-- Sanity check
-- =============================================================================
SELECT 'customers' AS table_name, COUNT(*) FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;
