# Sales-Trend-Analysis-Using-Aggregations
# Sales Analytics — Monthly Trends (MySQL)

This repository documents the **Sales Analytics** task: creating a MySQL database, loading a transactions dataset, and producing monthly trend analyses (revenue, order volume, AOV), plus breakdowns by **region**, **product category**, and **payment method**. It includes the exact SQL used and screenshots of the results.

> **What you’ll find here**
>
> - `sql/Sales Analytics.sql` — full script to create the database/table, load the CSV, and run analysis queries.
> - `screenshots/Sales_Results_Screenshots.pdf` — captured outputs for each query block.
> - `README.md` — this file with setup, how to run, and interpretation notes.

---

## 1) Repository Structure 

```
sales-analytics/
├─ sql/
│  └─ Sales Analytics.sql
├─ screenshots/
│  └─ Sales_Results_Screenshots.pdf
└─ README.md
```
---

## 2) Prerequisites

- **MySQL 8.0+** (tested with MySQL 8)
- Permission to use `LOAD DATA LOCAL INFILE` (or use MySQL Workbench’s Import Wizard)
- A CSV file with columns:
  - Transaction ID, Date (YYYY-MM-DD), Product Category, Product Name,
    Units Sold, Unit Price, Total Revenue, Region, Payment Method

---

## 3) How to Run

1. **Open a MySQL client** (CLI or Workbench).
2. **Enable local infile** if using CLI:

   ```sql
   -- Requires server and client permissions
   SET GLOBAL local_infile = 1;
   ```

   And connect from CLI with:
   ```bash
   mysql --local-infile=1 -u <user> -p
   ```

3. **Execute the SQL script** from `sql/Sales Analytics.sql`:

   - Creates database: `sales_analytics`
   - Creates table: `online_sales`
   - Loads the CSV into `online_sales`
   - Runs multiple analysis queries and creates a reusable view

4. **Adjust the CSV path** in the `LOAD DATA LOCAL INFILE` command in section **(C)** to match your environment (Windows paths usually need escaped backslashes). Example:

   ```sql
   LOAD DATA LOCAL INFILE 'D:\Data Analyst Internship\Task_6\Online Sales Data.csv'
   INTO TABLE online_sales
   FIELDS TERMINATED BY ',' ENCLOSED BY '"'
   LINES TERMINATED BY '
'
   IGNORE 1 LINES
   ...
   ;
   ```

5. **Sanity checks** (row counts and date ranges) are included.

6. **Run the analysis queries** (sections **D**, **E**, **F**, and the numbered queries 1–18).

---

## 4) What the SQL Does (high level)

### A. Database & table
- Creates a clean database `sales_analytics` and table `online_sales` with indexes on `order_date` for faster time-based aggregation.

### B. Load
- Loads CSV using `LOAD DATA LOCAL INFILE` with `STR_TO_DATE` for `YYYY-MM-DD` parsing and `NULLIF` handling for numeric fields.

### C. Monthly trends & KPIs
Key blocks you can run independently:

- **(D) Core monthly trend:** year, month, total revenue, order volume.
- **(E) Period filter example:** restrict to `2024-01` through `2024-06`.
- **(F) View `monthly_sales_trend`:** reusable base for additional analytics.

The extended analysis (numbered 1–18) includes:
- **1)** Full monthly trend **+ AOV** and units
- **3)** Current year only
- **4)** Last 6 months (relative) sorted oldest → newest
- **5)** **Top 3 months by revenue**
- **6)** Months above a revenue threshold
- **7)** Year/Month totals **WITH ROLLUP** (includes subtotals & grand total)
- **8)** Month × Region split
- **9)** Month × Product Category split
- **10)** **Top category per month** using window functions
- **11)** Month × Payment Method split
- **12–18)** Re-using the view for AOV, Top/Bottom months, **YTD running totals**, **3‑month moving average**, time-window filters, and **most recent 6 months**

Refer to `screenshots/Sales_Results_Screenshots.pdf` for labeled outputs (Qxx labels).

---

## 5) Example Insights (from the included screenshots)

These figures illustrate how the queries summarize performance over **Jan–Aug 2024** in the sample data:

- **Top 3 months by revenue**: January (14,548.32), March (12,849.24), April (12,451.69).  
- **YTD totals (ROLLUP)** through August: revenue **80,567.85** across **240** orders.  
- **AOV samples**: January ≈ **469.30**, April ≈ **415.06**.  
- **Most frequent top category** per month in this sample is **Electronics** (e.g., Jan, Apr, May, Jun, Jul, Aug).

> See the PDF for exact tables and additional breakdowns (Region, Category, Payment Method), plus moving averages and running totals.

---

## 6) Interpreting the Outputs

- **Monthly trend** is the baseline: it answers “How are we doing by month?” in terms of **revenue** and **order volume**.
- **AOV (Average Order Value)** = revenue ÷ orders; helps see ticket-size changes even when volume/revenue diverge.
- **Top months** identify spikes; pair with **category/region** splits to find the drivers.
- **ROLLUP** exposes **subtotals** (per year) and a **grand total** in the same result set—useful for quick dashboards.
- **Moving average (MA3)** smooths month-to-month noise to show trajectory.
- **Running totals (YTD)** are useful for progress against plan.

---
Author
Kadimella Sahana
