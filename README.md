# Sales Data Quality Audit & Exploratory Data Analysis (EDA)

**Author:** Johanna Ezedinma  
**Date:** July 2026

<p align="left">
  <a href="https://www.linkedin.com/in/johanna-ezedinma/?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=ios_app"><img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white"></a>
  <a href= "https://medium.com/@johannaezedinma"><img src="https://img.shields.io/badge/Medium-12100E?style=for-the-badge&logo=medium&logoColor=white"></a>
</p>

---

### Project Overview & Business Problem Solved

This project audits, cleans, normalizes, and analyzes a transactional retail sales dataset (sourced from Kaggle) using SQL within a Jupyter Notebook environment.

**Business Problem:**
Before building downstream business intelligence dashboards (e.g., Power BI) and performing deep statistical modeling, raw transactional datasets often contain silent data corruption, structural gaps, or missing mappings. Analyzing unverified data can severely bias revenue metrics, skew regional performance tracking, and distort inventory forecasting.

This project solves this problem in three stages: validating data schema integrity and rectifying pipeline extraction errors, restructuring the flat source data into a proper relational schema, and quantifying key business performance metrics, from top customers and product lines down to at-risk revenue by order status.

---

### Technical Approach & Methodology

- **Schema Integrity & Baseline Auditing:** Inspected column data types, character limits, table row counts, and structural constraints using relational metadata queries (`information_schema.columns`).

- **Duplicate & Null Diagnostics:** Checked the composite primary key (`order_number`, `order_line_number`) for duplication, and identified missing values across critical dimension columns.

- **Data Hygiene & Boundary Checks:** Evaluated string field cleanliness (detecting leading/trailing whitespace using length comparison) and audited numeric boundaries (`MIN`/`MAX` checks) to confirm no negative prices or zero quantities existed.

- **Calculated Field & Mathematical Reconciliation:** Reconciled recorded sales figures against unit prices and quantities ordered to detect formula anomalies and data truncation issues.

- **Data Remediation:** Executed targeted SQL updates to patch operational gaps (missing territory mappings).

- **Schema Normalization:** The raw dataset arrives as a single flat table (`sales_data`), with customer, product, and order details repeated across every row. To support meaningful joins, subqueries, and window functions (rather than everything already sitting in one row), the flat table was split into a proper relational schema: `customers`, `products`, `orders`, and `order_items`, linked with primary and foreign keys, mirroring how a real transactional system would be structured.

- **Exploratory & Business Analysis:** Quantified product line performance, territory contributions, deal size distribution, customer lifetime value, year-over-year product line rank shifts, and at-risk/lost revenue by order status.

---

### Data Quality Diagnostics: Missing & Duplicate Handling

**1. Duplicate Handling**

Checked the raw table's composite key for exact repeats:

```sql
SELECT order_number, order_line_number, COUNT(*)
FROM sales_data
GROUP BY order_number, order_line_number
HAVING COUNT(*) > 1;
```

**Result:** 0 duplicates detected. Baseline composite key integrity confirmed.

Once the data was normalized, the same check was repeated across every table in the new schema, since a flat-file duplicate check doesn't guarantee a normalized customer, product, or order table is free of repeats:

```sql
-- customers: confirm no customer name is duplicated under a different customer_id
SELECT customer_name, COUNT(*)
FROM customers
GROUP BY customer_name
HAVING COUNT(*) > 1;

-- products: confirm no product_code is duplicated
SELECT product_code, COUNT(*)
FROM products
GROUP BY product_code
HAVING COUNT(*) > 1;

-- orders: confirm no order_number is duplicated
SELECT order_number, COUNT(*)
FROM orders
GROUP BY order_number
HAVING COUNT(*) > 1;

-- order_items: confirm the same product doesn't appear twice as a
-- separate line item on the same order
SELECT order_number, product_code, COUNT(*)
FROM order_items
GROUP BY order_number, product_code
HAVING COUNT(*) > 1;
```

**Result:** 0 rows returned for all four tables. No duplicates anywhere in the normalized schema.

**2. Missing Values & Remediation**

- **Territory column:** Initial checks flagged 1,074 missing/`'NA'` records. A breakdown by country revealed that 100% of these unmapped records originated from North America (USA: 1,004 records; Canada: 70 records).

  ```sql
  UPDATE sales_data
  SET territory = 'AMER'
  WHERE country IN ('USA', 'Canada')
    AND (territory IS NULL OR territory = 'NA');
  ```

  Note: an initial `NULL`-only check (`COUNT(*) - COUNT(territory)`) reported 0 missing values, since the real gap was stored as the literal text `'NA'`, not a SQL `NULL`. This only surfaced once every distinct `territory` value was scanned directly, a reminder that a null check alone doesn't catch sentinel placeholder values.

- **Postal Codes:** Identified 76 missing postal codes. Verified as structurally acceptable standard omissions for international shipping destinations, not a data pipeline error.

---

### Key SQL Concepts Used

- **Aggregation & Grouping:** `COUNT()`, `COUNT(DISTINCT)`, `SUM()`, `MIN()`, `MAX()`, `AVG()`, `GROUP BY`, `HAVING`

- **Data Manipulation & Logic:** `UPDATE ... SET`, `WHERE ... IN`, `IS NULL`, `ABS()`

- **Schema & Metadata Introspection:** querying `information_schema.columns`

- **Set Operations & String Functions:** `UNION ALL`, `LENGTH()`, `TRIM()`

- **Mathematical Operations:** difference checks between actual and calculated transactional fields (`sales - (quantity_ordered * price_each)`)

- **Joins:** `INNER JOIN` across `customers`, `products`, `orders`, and `order_items` to reconstruct full transaction details from the normalized schema

- **Subqueries:** comparing each customer's lifetime spend against a dynamically calculated global average

- **Common Table Expressions (`WITH`):** used throughout the business analysis notebook to stage intermediate aggregates (annual sales, monthly sales, customer order history, risky orders) before a final query builds on top of them

- **Window functions:** `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `LAG()`, all with `PARTITION BY`/`ORDER BY`, used for year-over-year product line rank changes, running revenue totals, customer re-purchase gaps, and per-line-item revenue ranking

---

### Key Metrics & KPIs Tracked

- **Total Revenue by Product Line:** Classic Cars generates the highest revenue at $3,919,615.66, down to Trains at $226,243.47.

- **Top Customer by Lifetime Spend:** Euro Shopping Channel ($912,294.11 across 26 orders), well ahead of Mini Gifts Distributors Ltd. ($654,858.06)
  .
- **Order Status Breakdown:** tracking operational throughput across distinct statuses (Shipped, In Process, Cancelled, Resolved, On Hold, Disputed).

- **Deal Size Distribution:** Large deals average $4,615.50 per line vs. $3,379.68 for Small, segmented across Small, Medium, and Large.

- **Peak Revenue Month:** November 2004 ($1,089,048.01), the strongest month in the dataset, consistent with a recurring November seasonal spike (November 2003 also peaked, at $1,029,837.66).

- **At-Risk / Lost Revenue:** $152,718.98 in USA orders currently On Hold, the single largest at-risk exposure by country and status.

- **Regional & Territory Revenue:** cardinality tracked across 19 countries, 73 cities, 16 states, and 4 territories (AMER, EMEA, APAC, Japan); Classic Cars is the top revenue-generating product line in every territory.

- **Transactional Limits:** order quantity ranges (6 to 97 units per line) and unit pricing bounds ($26.88 to $100.00).

---

### Challenges Faced & Root Cause Findings

**1. Hardcoded Unit Price Ceiling (`price_each = 100.00`)**

- **Challenge:** When validating line-item math (`Calculated Sales = quantity_ordered × price_each`), several records showed significant variances where recorded sales exceeded the calculated amount.

- **Root Cause Analysis:** Diagnostic queries revealed that in every anomalous row, `price_each` was capped at exactly 100.00, whereas actual product MSRP and recorded sales implied higher unit prices.

- **Business Resolution:** Identified a likely system export constraint capping unit prices at $100.00 in the transactional view. Recommended coordinating with the Database Administrator to update the column precision, or split bundled fees (shipping, handling, regional taxes) into dedicated columns.

**2. Missing Region Mapping Pipeline Defect**

- **Challenge:** Unmapped territory values would cause North American sales to be completely omitted from global territory visual filters in downstream dashboards.

- **Business Resolution:** Patched the immediate database tables for analysis and raised a systemic recommendation for the ETL data engineering team to enforce territory assignment rules upon ingestion.

**3. A Query Answering the Wrong Question**

- **Challenge:** A query intended to find the single highest-revenue **month** was written grouping by year, month, _and day_, which meant it was actually returning the single highest-revenue **day** (Nov 24, 2004 at $137,644.72) rather than the month.

- **Root Cause Analysis:** The `GROUP BY` included one column too many. Removing the day-level grouping and re-aggregating by year and month alone surfaced the real answer, November 2004 at $1,089,048.01, which was independently confirmed against a separate monthly revenue trend query elsewhere in the analysis.

- **Business Resolution:** A reminder that a query returning _a_ plausible-looking result isn't proof it's answering the _right_ question; cross-checking a finding against a second, independently-built query (in this case, the monthly trend table) is what actually caught the discrepancy.

---

## Tools

PostgreSQL, SQL (via `jupysql`/`ipython-sql` in Jupyter)

---

## Repository Structure

```
sales_data_audit_and_EDA/
│
├── data/
│   ├── raw/
│   └── processed/
│
├── documentation/
│   └── data_quality_audit.md
│
├── notebooks/
│   ├── 01_sales_data_profiling.ipynb
│   ├── 02_sales_data_preparation.ipynb
│   └── 03_sales_business_analysis.ipynb
│
├── sql/
│   ├── 01_database_creation.sql
│   └── 02_normalization.sql
│
├── README.md
└── requirements.txt
```

---

## Pipeline Order

The two folders are numbered independently, but this project runs in one
continuous sequence across both:

1. `sql/01_database_creation.sql` — create the database and load the raw table
2. `notebooks/01_sales_data_profiling.ipynb` — audit schema, missing values, duplicates
3. `notebooks/02_sales_data_preparation.ipynb` — apply and verify targeted fixes
4. `sql/02_normalization.sql` — restructure the flat table into a relational schema
5. `notebooks/03_sales_business_analysis.ipynb` — business questions, KPIs, insights

---

## 👤 Author

**Johanna Ezedinma**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/johanna-ezedinma/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Johanna-Ezedinma)
[![Medium](https://img.shields.io/badge/Medium-12100E?style=for-the-badge&logo=medium&logoColor=white)](https://medium.com/@johannaezedinma)
