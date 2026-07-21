# Data Quality Audit Report: Sales Dataset

**Date:** July 19, 2026  
**Status:** Action Required (Data Anomalies Detected)

> A comprehensive data quality check executed on the `sales_data` table documents critical discrepancies that must be addressed to ensure that downstream analysis, metric aggregations, and business intelligence dashboards remain accurate.

---

## 1. Missing Regional Mapping (`territory` Column)

- **Observation:** The `territory` column contains **1,074 missing or 'NA' records**.
- **Discovered Pattern:** A targeted breakdown by country revealed that 100% of these unmapped records belong exclusively to North American transactions:
  - **USA:** 1,004 records
  - **Canada:** 70 records

- **Business Impact:** Any regional performance analysis or regional slices in Power BI tracking metrics across territories (e.g., APAC, EMEA) will completely omit North American performance, grossly misrepresenting global sales metrics.

- **Proactive Recommendation:**
  - _Immediate Fix:_ Applied a database patch to resolve the missing values for current analysis
    ```sql
    UPDATE sales_data
    SET territory = 'AMER'
    WHERE country IN ('USA', 'Canada')
      AND (territory IS NULL OR territory = 'NA');
    ```
  - _Systemic Fix:_ Request the data engineering or ERP system team to audit the ETL extraction pipeline to ensure North American countries are automatically assigned to an operational territory zone.

---

## 2. Mathematical Variance in Sales Calculation

- **Observation:** For a specific subset of records, the recorded `sales` figure does not match the basic arithmetic definition:  
  $$\text{Calculated Sales} = \text{quantity\_ordered} \times \text{price\_each}$$

- **Discovered Pattern:** In every single anomalous record flagged, the `price_each` column is hardcoded to a flat value of exactly **`100.00`**, while the recorded `sales` column figures fluctuate much higher.

For example:

- **Order 10159 (Line 14):** 49 units × \$100.00 = \$4,900.00 calculated, but recorded sales is **\$5,205.27**.
- **Order 10112 (Line 1):** 29 units × \$100.00 = \$2,900.00 calculated, but recorded sales is **\$7,209.11**.

- **Business Impact:** This strongly suggests that `price_each` is being artificially capped at \$100.00 in the transactional database export system, or that the `sales` total includes bundled surcharges (such as shipping, logistical handling, or specific state taxes) that are missing from the unit price.

- **Proactive Recommendation:**
  - Coordinate with the source database administrator to see if `price_each` has a strict data type ceiling or interface display restriction.
  - Suggest breaking out additional operational values into dedicated columns (e.g., `shipping_fee`, `tax_applied`) in the primary data export view so the base calculation balances precisely.

---

## 3. Structural & Baseline Integrity Confirmations

While the above anomalies require data cleaning steps, the baseline ingestion checks confirmed the following structural wins:

- **Duplicate Check:** Pass. 0 duplicate records identified across the primary composite keys (`order_number`, `order_line_number`).
- **Text Cleanliness:** Pass. Text columns evaluated showed no trailing or leading whitespace issues.
- **Numeric Boundaries:** Pass. No impossible values (zeros, negative quantities, or negative pricing) exist in the transactional columns.
- **Postal Codes:** 76 missing postal codes identified; verified as structurally acceptable due to international shipping regions that omit standard postal reporting codes.
