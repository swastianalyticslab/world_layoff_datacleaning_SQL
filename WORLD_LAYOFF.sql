-- Data Cleaning

-- Phase 1 — Check the raw data
-- to show the imported table
SELECT *
FROM world_layoffs.layoffs;

-- 1. Remove Duplicates
-- 2. Standardize Data
-- 3. Null/blank values
-- 4. Remove any column not required in ETL process


-- Phase 3 — Create the Cleaning Layer
--  Never destroy your raw data
-- Create a separate table to execute data cleaning

CREATE TABLE world_layoffs.layoffs_staging
LIKE world_layoffs.layoffs;

-- copy the raw data into layoffs_staging table
INSERT INTO world_layoffs.layoffs_staging
SELECT *
FROM world_layoffs.layoffs;

-- to display the created table 
SELECT*
FROM world_layoffs.layoffs_staging;


-- Step 2 — Check number of records
SELECT COUNT(*) AS total_records
FROM world_layoffs.layoffs_staging;

-- find out duplicates in the data

-- shows rows with unique entries
SELECT*,
ROW_NUMBER() OVER(
PARTITION BY company,industry,total_laid_off,percentage_laid_off,'date') AS row_num
FROM world_layoffs.layoffs_staging;

-- to check rows having duplicate entries
WITH duplicate_cte AS
(
SELECT*,
ROW_NUMBER() OVER(
PARTITION BY company,industry,total_laid_off,percentage_laid_off,'date') AS row_num
FROM world_layoffs.layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num>1;

-- to check if the rows presented as duplicates are actually duplicate by taking one of the row using one of the company
SELECT*
FROM world_layoffs.layoffs_staging
WHERE company='Oda';


-- checking duplicates using all the columns to find out exactly similar rows
WITH duplicate_cte AS
(
SELECT*,
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num>1;

-- to check if the rows presented as duplicates are actually duplicate by taking one of the row using one of the company
SELECT*
FROM world_layoffs.layoffs_staging
WHERE company='Casper';



CREATE TABLE layoffs_staging2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT,
    row_num INT
);

SELECT *
FROM world_layoffs.layoffs_staging2;

INSERT INTO world_layoffs.layoffs_staging2
SELECT*,
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE row_num>1;

SELECT*
FROM world_layoffs.layoffs_staging2
WHERE company='Oda';

SELECT*
FROM world_layoffs.layoffs_staging2
WHERE company='Casper';

-- Step 2 — Check number of records
SELECT COUNT(*) AS total_records
FROM world_layoffs.layoffs_staging2;

TRUNCATE TABLE world_layoffs.layoffs_staging2;

INSERT INTO world_layoffs.layoffs_staging2
SELECT *
FROM world_layoffs.layoffs_staging;

INSERT INTO world_layoffs.layoffs_staging2
(
    company,
    location,
    industry,
    total_laid_off,
    percentage_laid_off,
    `date`,
    stage,
    country,
    funds_raised_millions,
    row_num
)
SELECT
    company,
    location,
    industry,
    total_laid_off,
    percentage_laid_off,
    `date`,
    stage,
    country,
    funds_raised_millions,
    ROW_NUMBER() OVER (
        PARTITION BY company,
                     location,
                     industry,
                     total_laid_off,
                     percentage_laid_off,
                     `date`,
                     stage,
                     country,
                     funds_raised_millions
    ) AS row_num
FROM world_layoffs.layoffs_staging;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

-- to delete the duplicates

DELETE
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM world_layoffs.layoffs_staging2;


-- Standardizing data

SELECT company, TRIM(company)
FROM world_layoffs.layoffs_staging2;

UPDATE world_layoffs.layoffs_staging2
SET company= TRIM(company);

SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE world_layoffs.layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

SELECT DISTINCT location
FROM world_layoffs.layoffs_staging2
ORDER BY 1;


SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE country LIKE 'United States%';


SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM world_layoffs.layoffs_staging2
WHERE country LIKE 'United States%';

UPDATE world_layoffs.layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT STR_TO_DATE('3/6/2023', '%m/%d/%Y');

SELECT 
    `date`,
    STR_TO_DATE(`date`, '%m/%d/%Y') AS date_clean
FROM world_layoffs.layoffs_staging2;

SELECT
    `date`,
    STR_TO_DATE(`date`, '%Y-%m-%d') AS date_clean
FROM world_layoffs.layoffs_staging2;

UPDATE world_layoffs.layoffs_staging2
SET `date`= STR_TO_DATE(`date`, '%Y-%m-%d')

ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *
FROM world_layoffs.layoffs_staging2;

SELECT `date`
FROM world_layoffs.layoffs_staging2
WHERE STR_TO_DATE(`date`, '%Y-%m-%d') IS NULL
  AND `date` IS NOT NULL;
  
DESCRIBE world_layoffs.layoffs_staging2;

ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN `date` DATE;

DESCRIBE world_layoffs.layoffs_staging2;


-- WHERE BOTH COLUMNS ARE NULL CAN BE USELESS ROWS
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL
OR industry= '';

-- to check if the data for industry column for Airbnb row is available, we try to populate data if we can
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'Airbnb';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'Bally`s Interactive';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'Carvana';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'Juul';

-- populate cells in industry column where it can be
UPDATE world_layoffs.layoffs_staging2
SET industry =
    CASE
        WHEN company = 'Juul' THEN 'Consumer'
        WHEN company = 'Carvana' THEN 'Transportation'
        WHEN company = 'Airbnb' THEN 'Travel'
        ELSE industry
    END
WHERE company IN ('Juul', 'Carvana', 'Airbnb')
  AND industry = '';


-- Delete Useless data we can't really use
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM world_layoffs.layoffs_staging2;

ALTER TABLE world_layoffs.layoffs_staging2
DROP COLUMN row_num;


SELECT * 
FROM world_layoffs.layoffs_staging2;