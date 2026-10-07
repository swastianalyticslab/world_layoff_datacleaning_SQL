# World Layoffs Data Cleaning & Preparation Using SQL

## Project Overview
This project documents the data cleaning and preparation of a global layoffs dataset using SQL.
The objective was to transform the raw imported table into a cleaner analysis-ready table while preserving the original raw data. The cleaning workflow focused on:
- Creating a separate staging/cleaning layer.
- Checking record counts and duplicate records.
- Removing exact duplicate rows.
- Standardizing company names using TRIM().
- Standardizing industry labels, particularly crypto-related categories.
- Standardizing country names by removing trailing punctuation.
- Converting the date field from text to a SQL DATE.
- Investigating and populating selected missing industry values.
- Removing records where both total_laid_off and percentage_laid_off were unavailable.
- Removing the temporary row_num helper column after duplicate removal.
The supplied SQL explicitly follows the principle of not destroying the raw data by creating a separate cleaning layer.

## Data Source
Input File
- File:[Download/View Raw Dataset](layoffs.csv)
- Dataset: World Layoffs
- Rows: 2,361
- Columns: 9

## Tools Used
1. MySQL – SQL-based data cleaning and transformation.
2. SQL – Duplicate detection, standardization, missing-value handling, date conversion and table modification.

| Tool | Work Performed |
|---|---|
| MySQL | Imported and cleaned the dataset |
| SQL | Duplicate detection and removal |
| SQL | Text standardization |
| SQL | Country and industry normalization |
| SQL | Date conversion |
| SQL | Missing-value investigation and selected imputation |
| SQL | Removal of unusable records |

## Data Cleaning / Preparation Steps
### Phase 1 – Check the Raw Data
The first step was to inspect the imported raw table before making any changes.
```
SELECT *
FROM world_layoffs.layoffs;
```
This query displays the imported raw table and provides the starting point for identifying data-quality issues.

### Phase 2 – Define Cleaning Tasks
The SQL script identifies four major cleaning activities:
```
1. Remove Duplicates
2. Standardize Data
3. Null/blank values
4. Remove any column not required in ETL process
These tasks form the overall cleaning framework used in the project.
```

### Phase 3 – Create the Cleaning Layer
The raw table was preserved and a separate staging table was created for cleaning.
Create staging table
```
CREATE TABLE world_layoffs.layoffs_staging
LIKE world_layoffs.layoffs;
```
Copy raw data into staging
```
INSERT INTO world_layoffs.layoffs_staging
SELECT *
FROM world_layoffs.layoffs;
```
This approach protects the original dataset while allowing transformations to be performed on a working copy.

```
SELECT *
FROM world_layoffs.layoffs_staging;
```

#### Step 1 – Create and Copy to Staging
A second staging table was created with an additional row_num column. This helper column was required for identifying duplicate records using the ROW_NUMBER() window function.
```
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
```

The original staging data was then inserted into this table.

#### Step 2 – Check Record Count and Identify Duplicates
Record count

```
SELECT COUNT(*) AS total_records
FROM world_layoffs.layoffs_staging;
```

The record count was checked before duplicate removal to establish a baseline.

Identify potential duplicates

```
WITH duplicate_cte AS
(
    SELECT *,
    ROW_NUMBER() OVER(
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
    FROM world_layoffs.layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
```

ROW_NUMBER() assigns a sequence number to records that have identical values across the selected fields. Records with row_num > 1 are treated as duplicate occurrences.

Validate suspected duplicates
The SQL also manually inspected companies such as Oda and Casper to determine whether records flagged by the duplicate logic were actually identical.

#### Step 3 – Remove Duplicate Records
The helper table was populated with a duplicate-ranking column:

```
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
```

Then duplicate rows were deleted:

```
DELETE
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;
```

Finally, the table was checked again:

```
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;
```

The supplied CSV contains 5 exact duplicate records to remove, represented by 10 rows belonging to 5 duplicated pairs.
The SQL deletion step is explicitly shown in the supplied script.

#### Step 4 – Standardize Text Fields
4.1 Trim company names
Before updating:

```
SELECT company, TRIM(company)
FROM world_layoffs.layoffs_staging2;


UPDATE world_layoffs.layoffs_staging2
SET company = TRIM(company);
```

This removes unnecessary leading/trailing whitespace from company names.


4.2 Standardize industry values
The unique industry values were reviewed:

```
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY 1;
```

Crypto-related variations were identified:

```
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry LIKE 'Crypto%';
```

They were standardized to a single category:

```
UPDATE world_layoffs.layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```
This consolidates values such as Crypto, Crypto Currency, and CryptoCurrency into the common label Crypto. fileciteturn0file0L186-L200

4.3 Review location and country values

```
SELECT DISTINCT location
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY 1;
```
These queries were used to inspect categorical consistency.

4.4 Standardize United States country value
The dataset contained United States. as well as United States.

```
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE country LIKE 'United States%';
```
The transformation used was:

```
UPDATE world_layoffs.layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
```
This removes the trailing period and standardizes the country label.


#### Step 5 – Standardize Dates
The raw date field was stored as text. The SQL first tested date conversion:
```
SELECT STR_TO_DATE('3/6/2023', '%m/%d/%Y');
```

The supplied script then checked conversion of the date field:
```
SELECT
    `date`,
    STR_TO_DATE(`date`, '%m/%d/%Y') AS date_clean
FROM world_layoffs.layoffs_staging2;
```

SELECT
    `date`,
    STR_TO_DATE(`date`, '%Y-%m-%d') AS date_clean
FROM world_layoffs.layoffs_staging2;
The final conversion was:
```
UPDATE world_layoffs.layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%Y-%m-%d');
```
Then the column was changed to the SQL DATE data type:
```
ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN `date` DATE;
```
The SQL also included a validation query for values that could not be converted:
```
SELECT `date`
FROM world_layoffs.layoffs_staging2
WHERE STR_TO_DATE(`date`, '%Y-%m-%d') IS NULL
  AND `date` IS NOT NULL;
  ```
The date datatype was subsequently checked using DESCRIBE


#### Step 6 – Handle Missing Industry Values
The SQL first identified records where industry was unavailable:
```
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL
OR industry = '';
```
The script then investigated individual companies, including:
```
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
```
For selected companies, the industry was populated using a CASE expression:
```
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
```
#### Step 7 – Remove Unusable Records
The script treats records with no information in either of the two main layoff measures as unusable:
```
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
```
The identified records are then removed:
```
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
```
In the uploaded raw CSV, 362 rows have both total_laid_off and percentage_laid_off missing.

#### Step 8 – Remove the Technical Helper Column
After duplicate removal, the temporary row_num field was no longer needed.
```
ALTER TABLE world_layoffs.layoffs_staging2
DROP COLUMN row_num;
```
The final table was then displayed:
```
SELECT *
FROM world_layoffs.layoffs_staging2;
```
This leaves the cleaned table with the original analytical fields only.

## Data Before Cleaning

![Data Before Cleaning](<Data before cleaning.png>)

## Data After Cleaning

![Data After Cleaning](<Data after cleaning.png>)

## Results / Findings
| Finding | Result |
|---|---|
| Original records | 2,361 |
| Original columns | 9 |
| Exact duplicate records identified for removal | 5 |
| Rows with both `total_laid_off` and `percentage_laid_off` missing | 362 |
| Crypto-related industry variants | 102 rows beginning with `Crypto` |
| `United States.` records requiring punctuation standardization | 4 |
| Missing/blank industry records | 4 |
| Date field | Converted from text to DATE |
| Company names | Trimmed |
| Country values | Trailing period removed from affected US values |
| Temporary `row_num` | Removed after duplicate deletion |

## Key Data-Quality Improvements
- Duplicate records were identified and removed.
- Text fields were standardized.
- Multiple crypto industry labels were consolidated.
- Country punctuation inconsistencies were corrected.
- The date field was converted into a proper date type.
- Selected missing industry values were populated.
- Rows without either of the two main layoff measures were removed.
- The raw dataset was preserved through a staging-table approach.

## Recommendations for Further Analysis
After completing data cleaning, the dataset can be used for exploratory and analytical work such as:
1. Layoffs by Industry
2. Geographic Analysis
3. Time-Series Analysis
4. Company-Level Analysis
5. Funding and Layoff Analysis
6. Dashboard Development

### Author
Swasti

-Data Analytics Portfolio Project
