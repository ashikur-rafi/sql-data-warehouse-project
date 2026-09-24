# Data Dictionary for Gold Layer

## Overview

The **Gold Layer** contains business-ready data models designed for analytics and reporting. It transforms and integrates the cleaned data from the Silver Layer into dimensional and fact views that can be directly used for business intelligence, dashboards, reporting, and analytical queries.

This Gold Layer follows a **Star Schema** design consisting of:

* **`gold.dim_customers`** — Customer dimension containing customer demographic and geographic information.
* **`gold.dim_products`** — Product dimension containing product, category, and pricing-related information.
* **` gold.fact_sales`** — Sales fact table containing transactional sales measures and relationships to customers and products.

The dimension views provide descriptive information, while the fact view stores measurable business events that can be analyzed using the dimension keys.

---

# 1. `gold.dim_customers`

## Purpose

The `gold.dim_customers` view provides a consolidated and business-ready customer dimension by combining customer information from the CRM system with additional demographic and location information from the ERP system.

It creates a unique **customer key** that can be used to connect customers with the `gold.fact_sales` view.

The view also applies business logic to determine the customer's gender, giving priority to the CRM source and using ERP data as a fallback when the CRM value is unavailable.

## Columns

| Column Name       | Data Type           | Description                                                                                                   |
| ----------------- | ------------------- | ------------------------------------------------------------------------------------------------------------- |
| `Customer_key`    | `BIGINT`            | Surrogate key generated using `ROW_NUMBER()` to uniquely identify each customer within the Gold Layer.        |
| `Customer_id`     | `INT`               | Original customer identifier from the CRM customer master data.                                               |
| `Customer_number` | `VARCHAR`           | Business/customer reference number from the CRM system.                                                       |
| `First_name`      | `VARCHAR`           | Customer's first name.                                                                                        |
| `Last_name`       | `VARCHAR`           | Customer's last name.                                                                                         |
| `Birthdate`       | `DATE`              | Customer's date of birth obtained from the ERP customer demographic data.                                     |
| `Gender`          | `VARCHAR`           | Customer's gender. CRM is treated as the master source; ERP gender is used when the CRM value is unavailable. |
| `Country`         | `VARCHAR`           | Customer's country obtained from the ERP location data.                                                       |
| `Marital_status`  | `VARCHAR`           | Customer's marital status from the CRM system.                                                                |
| `Create_time`     | `DATE` / `DATETIME` | Date/time when the customer record was originally created in the CRM system.                                  |

---

# 2. `gold.dim_products`

## Purpose

The `gold.dim_products` view provides a business-ready product dimension by combining product information from the CRM system with product category and maintenance information from the ERP system.

The view contains only the **currently active product records** by filtering out historical product records where `prd_end_dt` is populated.

A unique **product key** is generated to connect products with the `gold.fact_sales` view.

## Columns

| Column Name      | Data Type | Description                                                                                           |
| ---------------- | --------- | ----------------------------------------------------------------------------------------------------- |
| `product_key`    | `BIGINT`  | Surrogate key generated using `ROW_NUMBER()` to uniquely identify each product within the Gold Layer. |
| `product_id`     | `INT`     | Original product identifier from the CRM product master data.                                         |
| `product_number` | `VARCHAR` | Business/product reference number used to identify the product.                                       |
| `product_name`   | `VARCHAR` | Name of the product.                                                                                  |
| `category_id`    | `VARCHAR` | Identifier of the product category.                                                                   |
| `category`       | `VARCHAR` | Main category to which the product belongs.                                                           |
| `subcategory`    | `VARCHAR` | Subcategory classification of the product.                                                            |
| `maintenance`    | `VARCHAR` | Maintenance-related classification or information associated with the product category.               |
| `cost`           | `DECIMAL` | Cost of the product.                                                                                  |
| `product_line`   | `VARCHAR` | Product line or product type classification.                                                          |
| `start_date`     | `DATE`    | Date from which the product record became active.                                                     |

---

# 3. `gold.fact_sales`

## Purpose

The `gold.fact_sales` view represents the central **sales transaction fact** in the Gold Layer.

It contains sales transactions along with measures such as sales amount, quantity, and price. The fact view connects each transaction to the corresponding customer and product dimensions using the generated surrogate keys from `gold.dim_customers` and `gold.dim_products`.

This view is designed to support analytical queries such as sales performance, product analysis, customer analysis, revenue analysis, and time-based sales reporting.

## Columns

| Column Name     | Data Type | Description                                                                   |
| --------------- | --------- | ----------------------------------------------------------------------------- |
| `order_number`  | `VARCHAR` | Unique or business reference number identifying the sales order.              |
| `product_key`   | `BIGINT`  | Surrogate key referencing the corresponding product in `gold.dim_products`.   |
| `customer_key`  | `BIGINT`  | Surrogate key referencing the corresponding customer in `gold.dim_customers`. |
| `order_date`    | `DATE`    | Date on which the sales order was placed.                                     |
| `shipping_date` | `DATE`    | Date on which the order was shipped.                                          |
| `due_date`      | `DATE`    | Expected or due date associated with the sales order.                         |
| `sales_amount`  | `DECIMAL` | Total sales amount associated with the sales transaction.                     |
| `quantity`      | `INT`     | Number of units sold in the transaction.                                      |
| `price`         | `DECIMAL` | Unit selling price of the product.                                            |

---

## Gold Layer Data Model

The Gold Layer follows a **Star Schema** where `gold.fact_sales` acts as the central fact view and the customer and product dimensions provide descriptive context.

### Relationships

```text
                    ┌─────────────────────┐
                    │  gold.dim_customers │
                    │─────────────────────│
                    │ Customer_key        │
                    │ Customer_id         │
                    │ First_name          │
                    │ Last_name           │
                    │ Country             │
                    │ Gender              │
                    └──────────┬──────────┘
                               │
                               │ customer_key
                               │
                               ▼
                    ┌─────────────────────┐
                    │   gold.fact_sales   │
                    │─────────────────────│
                    │ order_number        │
                    │ customer_key        │
                    │ product_key         │
                    │ order_date          │
                    │ shipping_date       │
                    │ due_date            │
                    │ sales_amount        │
                    │ quantity            │
                    │ price               │
                    └──────────┬──────────┘
                               │
                               │ product_key
                               │
                               ▼
                    ┌─────────────────────┐
                    │  gold.dim_products  │
                    │─────────────────────│
                    │ product_key        │
                    │ product_id         │
                    │ product_number     │
                    │ product_name       │
                    │ category           │
                    │ subcategory        │
                    │ cost               │
                    │ product_line       │
                    └─────────────────────┘
```

### Summary

| Gold View            | Type      | Main Purpose                                                               |
| -------------------- | --------- | -------------------------------------------------------------------------- |
| `gold.dim_customers` | Dimension | Provides customer demographic, geographic, and master-data information.    |
| `gold.dim_products`  | Dimension | Provides active product, category, and product classification information. |
| `gold.fact_sales`    | Fact      | Stores sales transactions and measurable sales information for analytics.  |
