# E-commerce Profitability & Revenue Leakage Analysis

Professional Data Analyst portfolio project analyzing revenue, estimated profitability, freight burden, delivery delays, cancellation loss, payment behavior, and seller performance using the Olist Brazilian E-commerce dataset.

## Business Problem

E-commerce businesses can grow sales while losing margin through high freight costs, weak seller performance, delivery delays, and canceled orders. This project identifies where revenue leakage occurs and which categories, states, and sellers need operational attention.

The final output is a 5-page Power BI dashboard supported by MySQL data cleaning, SQL analysis, and DAX measures.

## Dataset

Dataset: [Brazilian E-Commerce Public Dataset by Olist on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The dataset contains 100,000+ marketplace orders from Brazil between 2016 and 2018, including orders, order items, payments, reviews, products, sellers, customers, and product category translations.

## Important Assumption

The public Olist dataset does not include actual product cost. Estimated cost is assumed as 60% of item price.

```text
estimated_cost = price * 0.60
estimated_profit = price - estimated_cost - freight_value
```

This is not actual profit data. It is a transparent analytical assumption used for portfolio-level profitability analysis.

## Key Business Questions

- Which product categories generate the highest revenue?
- Which categories have weak estimated profit margins?
- Where is revenue leakage happening?
- Which categories are freight traps due to high freight cost and low estimated margin?
- Which states have delivery delay issues?
- Which sellers are Good, Average, Poor, or At Risk?
- How do payment methods and order statuses affect business operations?

## Tools & Technologies

![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![SQL](https://img.shields.io/badge/SQL-336791?style=for-the-badge)
![DAX](https://img.shields.io/badge/DAX-F2C811?style=for-the-badge)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-150458?style=for-the-badge)

## Project Structure

```text
ecommerce-profitability-analysis/
|-- data/
|   |-- raw/
|   |-- cleaned/
|-- sql/
|   |-- 01_database_setup.sql
|   |-- 02_data_cleaning.sql
|   |-- 03_revenue_and_profit_analysis.sql
|   |-- 04_revenue_leakage_analysis.sql
|   |-- 05_freight_trap_analysis.sql
|   |-- 06_delivery_delay_analysis.sql
|   |-- 07_seller_performance_scorecard.sql
|-- python/
|   |-- ecommerce_analysis.ipynb
|-- powerbi/
|   |-- ecommerce_dashboard.pbix
|   |-- dax_measures.md
|   |-- powerbi_dashboard_blueprint.md
|-- screenshots/
|-- report/
|   |-- business_recommendations.md
|-- README.md
```

## SQL Workflow

1. Created MySQL database: `ecommerce_analysis`.
2. Created staging tables for raw Olist CSV files:
   - `stg_customers`
   - `stg_orders`
   - `stg_order_items`
   - `stg_order_payments`
   - `stg_order_reviews`
   - `stg_products`
   - `stg_sellers`
   - `stg_product_category_translation`
3. Imported raw CSV files using `LOAD DATA LOCAL INFILE`.
4. Created analytical view: `vw_order_item_analysis`.
5. Created cleaned analysis tables:
   - `delivered_orders`
   - `canceled_orders`
   - `freight_trap`
   - `seller_scorecard`
6. Handled imported zero-date values such as `0000-00-00 00:00:00` by using permissive session SQL mode and filtering invalid dates where needed.
7. Exported cleaned SQL outputs as CSV files for Power BI.

## Power BI Tables

The dashboard uses these tables:

```text
delivered_orders
canceled_orders
stg_orders
stg_order_payments
freight_trap
seller_scorecard
```

## Main DAX Measures

```DAX
Total Revenue =
SUM(delivered_orders[price])
```

```DAX
Total Orders =
DISTINCTCOUNT(delivered_orders[order_id])
```

```DAX
Avg Order Value =
DIVIDE([Total Revenue], [Total Orders])
```

```DAX
Profit Margin % =
DIVIDE(
    SUM(delivered_orders[estimated_profit]),
    SUM(delivered_orders[price])
) * 100
```

```DAX
Total Cancellation Loss =
SUM(canceled_orders[price])
```

```DAX
Total Freight Burden =
SUM(delivered_orders[freight_value])
```

```DAX
Cancellation Rate % =
DIVIDE(
    COUNTROWS(canceled_orders),
    COUNTROWS(delivered_orders) + COUNTROWS(canceled_orders)
) * 100
```

```DAX
delay_days =
DATEDIFF(
    delivered_orders[order_estimated_delivery_date],
    delivered_orders[order_delivered_customer_date],
    DAY
)
```

```DAX
Seller Count =
DISTINCTCOUNT(seller_scorecard[seller_id])
```

## Dashboard Pages

### Page 1: Executive Overview

Purpose: high-level business performance summary.

KPIs:
- Total Revenue
- Total Orders
- Avg Order Value
- Profit Margin %
- Cancellation Rate %

Visuals:
- Monthly Revenue Trend
- Order Status Breakdown
- Payment Method Distribution

### Page 2: Revenue & Profitability

Purpose: analyze revenue and estimated margin by product category.

Visuals:
- Top 10 Product Categories by Revenue
- Estimated Profit Margin by Category
- Revenue vs Profit Margin Scatter Plot
- Product Category Slicer

### Page 3: Revenue Leakage

Purpose: identify business leakage from cancellations, freight burden, and low-margin categories.

KPIs:
- Cancellation Loss
- Total Freight Burden
- Total Revenue Leakage
- Leakage as % of Revenue

Visuals:
- Revenue Leakage by Category
- Freight % vs Profit Margin
- Freight Trap Categories Table

### Page 4: Delivery Performance

Purpose: analyze delivery delay patterns by state and delivery status.

KPIs:
- Avg Delay Days
- % Orders Delayed
- % Orders Early
- Worst Performing State

Visuals:
- Average Delivery Delay by State
- On Time vs Delayed vs Early Orders
- Delivery Delay Distribution

### Page 5: Seller Scorecard

Purpose: classify seller performance and identify at-risk sellers.

KPIs:
- Total Sellers
- Good Sellers
- Poor Sellers
- At Risk Sellers

Visuals:
- Seller Performance Tier Distribution
- Seller Risk Map: Cancellation Rate vs Review Score
- At Risk Sellers Table

Seller classification logic:

```text
Poor Seller:
cancellation_rate_pct > 20
OR avg_review_score < 3
OR avg_delay_days > 7

Good Seller:
cancellation_rate_pct < 10
AND avg_review_score > 4
AND avg_delay_days <= 3

Otherwise:
Average Seller
```

At Risk sellers are sellers in the bottom 10% by revenue.

Final seller counts:

```text
Average Sellers: 957
Good Sellers:    1752
Poor Sellers:    386
At Risk Sellers: 310
```

## Dashboard Screenshots

![Dashboard Page 1](screenshots/Screenshot%202026-06-05%20230808.png)

![Dashboard Page 2](screenshots/Screenshot%202026-06-05%20230833.png)

![Dashboard Page 3](screenshots/Screenshot%202026-06-05%20230857.png)

![Dashboard Page 4](screenshots/Screenshot%202026-06-05%20230917.png)

![Dashboard Page 5](screenshots/Screenshot%202026-06-05%20230936.png)

## Key Outputs

- Built a complete 5-page Power BI dashboard.
- Created cleaned SQL tables for delivered orders, canceled orders, freight trap analysis, and seller scorecard.
- Estimated profitability using a clear cost assumption.
- Identified seller performance tiers and at-risk sellers.
- Visualized revenue, leakage, delivery, payment, and seller-risk insights.

## Issues Solved During Build

- MySQL Workbench CSV import was slow, so `LOAD DATA LOCAL INFILE` was used.
- Some date fields imported as `0000-00-00 00:00:00`; SQL logic was updated to avoid date calculation errors.
- Power BI initially created an old `Errors in seller_scorecard` query; it was removed after loading the clean seller scorecard CSV.
- Seller scorecard was validated so `Average`, `Good`, and `Poor` tiers displayed correctly in Power BI.

## How to Run

1. Download the Olist dataset from Kaggle.
2. Place raw CSV files in `data/raw/`.
3. Open MySQL Workbench.
4. Run SQL scripts in order from the `sql/` folder.
5. Export cleaned SQL tables to `data/cleaned/`.
6. Open `powerbi/ecommerce_dashboard.pbix`.
7. Refresh the Power BI data sources if needed.
8. Review the five dashboard pages.

## Author

Amandeep Singh  
Data Analyst portfolio project focused on SQL, Power BI, DAX, data cleaning, and business storytelling.
