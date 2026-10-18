# 📊 Global Tech Layoffs — Exploratory Data Analysis (SQL)

## 📌 Project Overview
Following the data cleaning phase, this project performs an **Exploratory Data Analysis (EDA)** in **MySQL** on the standardized global layoffs dataset (`layoffs_staging2`). The objective is to identify macroeconomic layoff trends, pinpoint the hardest-hit industries and geographies, calculate month-over-month cumulative impact, and rank top companies by workforce reductions per year.

* 🔗 **[View Full SQL Script (`exploratory_data_analysis.sql`)](./exploratory_data_analysis.sql)**
* 🧹 **[Part 1: SQL Data Cleaning Pipeline Repository](https://github.com/AlisherMakhanov/sql-world-layoffs-data-cleaning)**

---

## 🛠️ SQL Skills & Techniques Demonstrated
* **Database:** MySQL 8.0 (MySQL Workbench)
* **Analytical Capabilities:**
  * Complex Aggregations (`SUM`, `MAX`, `MIN`, `AVG`, `GROUP BY`)
  * Date Extraction & String Slicing (`YEAR()`, `SUBSTRING()`)
  * Time-Series Cumulative Metrics (`SUM() OVER(ORDER BY ...)` Rolling Totals)
  * Chained Common Table Expressions (Multiple `WITH` clauses)
  * Partitioned Ranking Functions (`DENSE_RANK() OVER(PARTITION BY ... ORDER BY ...)`)

---

## 🔍 Key Analytical Questions & SQL Solutions

### 1. Extreme Cases & Startup Failures
Examined companies that laid off **100% of their workforce** (`percentage_laid_off = 1`) and ordered them by `funds_raised_millions` to see which heavily funded startups went completely under.

```sql
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
```

### 2. Dimensional Breakdown (Company, Industry, Country, Stage)
Aggregated total layoffs across key business dimensions to understand where the impact was most concentrated (e.g., Post-IPO tech giants vs. early-stage startups, and country-level distributions).

```sql
SELECT company, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;
```

### 3. Time-Series Progression & Rolling Total
To visualize how layoffs accumulated month-over-month from 2020 to 2023, I extracted the year-month (`YYYY-MM`) and used a **CTE with a Window Function (`SUM() OVER()`)** to compute a continuous rolling total.

```sql
WITH Rolling_Total AS (
    SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_off
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `MONTH`
    ORDER BY 1 ASC
)
SELECT `MONTH`, 
       total_off, 
       SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;
```

### 4. Top 5 Companies with the Highest Layoffs Per Year
To track which corporations led layoff waves each year without losing annual granularity, I built a **multi-CTE query** combining annual aggregations with `DENSE_RANK()` partitioned by year.

```sql
WITH Company_Year (company, years, total_laid_off) AS (
    SELECT company, YEAR(`date`), SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
), 
Company_Year_Rank AS (
    SELECT *, 
           DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
    FROM Company_Year
    WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;
```

---

## 💡 Summary of Insights
* **Stage Impact:** Post-IPO companies accounted for the largest volume of total layoffs by headcount, while smaller Series A/B startups saw higher rates of complete (100%) closures.
* **Geographic & Sector Concentration:** The United States and consumer/retail/tech sectors experienced the highest absolute layoff numbers.
* **Temporal Trend:** Rolling totals revealed a sharp acceleration in layoffs starting in late 2022 and peaking in early 2023.
