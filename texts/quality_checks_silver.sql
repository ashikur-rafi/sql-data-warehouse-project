/*
====================================================================
Quality Checks
====================================================================

Script Purpose:
    This script performs various quality checks for data consistency,
    accuracy, and standardization across the 'silver' schemas. It
    includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.

====================================================================
*/


-- ====================================================================
-- Checking 'silver.crm_cust_info'
-- ====================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
cst_id,
COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id is NULL
---------------------------------------------------
SELECT * 
FROM silver.crm_cust_info
WHERE cst_id = 29433
---------------------------------------------------
--Check for unwanted spaces
--Expectation: No Result
SELECT 
cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

SELECT 
cst_lastname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_lastname)

--Data Standardization & consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info

-- ====================================================================
-- Checking 'silver.crm_prd_info'
-- ====================================================================

--Check for unwanted spaces
--Expectation: No Result
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

--Check for NULLS and Negative Numbers
--Expectation: No Results
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- DATA Standardization & Consistency
SELECT DISTINCT prd_line 
FROM silver.crm_prd_info

-- Check for invalid Data Orders
SELECT * 
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

-- ====================================================================
-- Checking 'silver.crm_sales_details'
-- ====================================================================

-- Check for Invalid Dates
SELECT
    NULLIF(sls_due_dt, '1900-01-01') AS sls_due_dt
FROM silver.crm_sales_details
WHERE sls_due_dt > '2050-01-01'
   OR sls_due_dt < '1900-01-01';
-- Check for Invalid Data orders
SELECT
*
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt 

-- Check data consistency: Between sales, quantity, and price
-->> Sales = Quantity * Price
-->> Values must not be NULL, zero, or negative.
SELECT DISTINCT
sls_sales AS old_sls_sales,
sls_quantity,
sls_price AS old_sls_price,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,

CASE WHEN sls_price IS NULL OR sls_price <= 0
	THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price
END AS sls_price

FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

-- ====================================================================
-- Checking 'silver.erp_cust_az12'
-- ====================================================================

-- Identify out-of-range dates
SELECT DISTINCT
bdate
FROM silver.erp_cust_az12
WHERE bdate > GETDATE()

-- Data Standardization & Consistency
SELECT DISTINCT 
gen,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
     WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
     ELSE 'n/a'
END AS gen
FROM silver.erp_cust_az12

--====================================================================
-- Checking 'silver.erp_loc_a101'
-- ===================================================================

-- Data Standardization & Consistency
SELECT DISTINCT
  cntry
FROM silver.erp_loc_a101
ORDER BY cntry

--====================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ===================================================================

-- Check for unwanted spaces
-- Expectations: No Results

SELECT
    *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
   OR subcat != TRIM(subcat)
   OR maintenance != TRIM(maintenance);

-- Data standardization & consistency
SELECT DISTINCT
 maintenance
FROM silver.erp_px_cat_g1v2
