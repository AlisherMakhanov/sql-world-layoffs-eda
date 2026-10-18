-- ============================================================================
-- EXPLORATORY DATA ANALYSIS (EDA): Global Tech Layoffs Dataset (MySQL)
-- ============================================================================
-- Description: Exploring the cleaned `layoffs_staging2` dataset to uncover 
--              trends, patterns, and key insights across companies, industries, 
--              countries, and time periods.
-- Key SQL Skills: Aggregations, Grouping, Date Functions, Window Functions 
--                 (SUM OVER, DENSE_RANK OVER), and Multiple CTEs.
-- ============================================================================

-- Initial check of the cleaned dataset
SELECT *
FROM layoffs_staging2;

-- ============================================================================
-- STEP 1: High-Level Overview & Extreme Values
-- ============================================================================

-- 1.1 Maximum laid off in a single event and maximum percentage laid off (1 = 100%)
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- 1.2 Companies that went completely under (100% laid off), ordered by funding raised
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- 1.3 Date range of the dataset
SELECT MIN(`date`) AS start_date, MAX(`date`) AS end_date
FROM layoffs_staging2;

-- ============================================================================
-- STEP 2: Layoffs Breakdown by Category (Company, Industry, Country, Stage)
-- ============================================================================

-- 2.1 Total layoffs by Company
SELECT company, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- 2.2 Total layoffs by Industry
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- 2.3 Total layoffs by Country
SELECT country, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- 2.4 Total layoffs by Company Stage (e.g., Post-IPO, Series B, Acquired)
SELECT stage, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- 2.5 Average percentage laid off by Company (Note: total headcount is more informative)
SELECT company, AVG(percentage_laid_off) AS avg_percentage_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- ============================================================================
-- STEP 3: Time-Series Analysis & Rolling Totals
-- ============================================================================

-- 3.1 Total layoffs by Year
SELECT YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- 3.2 Monthly layoff totals (YYYY-MM)
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

-- 3.3 Cumulative (Rolling) Total of layoffs month-over-month using CTE & Window Function
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

-- ============================================================================
-- STEP 4: Advanced Ranking — Top 5 Companies by Layoffs Per Year
-- ============================================================================

-- 4.1 Layoffs by Company broken down by Year
SELECT company, YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- 4.2 Identify Top 5 companies with the highest layoffs for each individual year
-- Using chained CTEs and DENSE_RANK() partitioned by year
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
