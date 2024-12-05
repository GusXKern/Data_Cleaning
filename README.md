# Background
This project uses data taken from the SQL Course of [Alex Freberg](https://www.youtube.com/watch?v=8rO7ztF4NtU&pp=ygUFI3NxbDM%3D) which comes from a Kaggle dataset on Nashville housing price data. The dataset includes information on address, sale price, building value, land value, acreage and owner details.

# Tools I Used
For my deep dive into the data analyst job market, I harnessed the power of several key tools:

- **SQL:** The backbone of my analysis, allowing me to query the database and unearth critical insights.
- **PostgreSQL:** The chosen database management system, ideal for handling the job posting data.
- **Visual Studio Code:** My go-to for database management and executing SQL queries.
- **Git & GitHub:** Essential for version control and sharing my SQL scripts and analysis, ensuring collaboration and project tracking.
- **Power BI** Used to perform additional data cleaning and visualization to transform the dataset into interesting and usable insights.

Check out the SQL querys I used here: [project_sql folder](Nashville_data_cleaning.sql)

# The Analysis
Each SQL query for this project aimed at identifying and cleaning a different element of the dataset:

### 1. Change The Sale Date Column to Change the Data Type to Date
```sql
select saledate, --Use this to make sure that the change we are goign to make will work
cast(saledate as date)
from nashville;

ALTER TABLE nashville
ADD COLUMN sale_date date;

UPDATE nashville
SET sale_date = cast(saledate as date);

ALTER TABLE nashville
DROP COLUMN saledate;

select sale_date, saledate
from nashville;    -- Use this to check that the old column is gone
```

### 2. Populate Property Address Data:
- The propertyaddress column contains NULL values, but some of these NULL entries have the same listed parcelID as those with a NULL
- I want to match these values to fill in these NULL values with the addresses that match the parcelIDs

```sql
-- Here we can do a self join to match the null values with other entries where there is a property address associated with the parcelID
SELECT nashville_a.propertyaddress,
nashville_a.parcelid,
nashville_b.propertyaddress,
nashville_b.parcelid                        
FROM nashville as nashville_a
JOIN nashville as nashville_b ON
    nashville_a.parcelid = nashville_b.parcelid
    AND nashville_a.uniqueid <> nashville_b.uniqueid
    WHERE nashville_a.propertyaddress is NULL;

--We can then use this to replace the NULLS in our nashville table with the non-NULL addresses that share ParcelIDs
UPDATE nashville AS n1
SET propertyaddress = n2.propertyaddress
FROM nashville AS n2
    WHERE n1.parcelid = n2.parcelid AND n1.uniqueid <> n2.uniqueid
    AND n1.propertyaddress IS NULL AND n2.propertyaddress IS NOT NULL;
```

### 3. Break the Property Address Column Into Street Name/Number and City

```sql
-- Use this query to break the address up using the comma as a delimiter
SELECT 
    SUBSTRING(propertyaddress,1, POSITION(',' IN propertyaddress) - 1) as property,
    SUBSTRING(propertyaddress,POSITION(',' IN propertyaddress) + 1, LENGTH(propertyaddress)) as property_end
FROM nashville;

-- Add the new columns and fill them in
ALTER TABLE nashville
ADD COLUMN address VARCHAR(512);

UPDATE nashville
SET address = SUBSTRING(propertyaddress,1, POSITION(',' IN propertyaddress) - 1);

ALTER TABLE nashville
ADD COLUMN address_city VARCHAR(512);

UPDATE nashville
SET address_city = SUBSTRING(propertyaddress,POSITION(',' IN propertyaddress) + 1, LENGTH(propertyaddress));

--Alternate Method: Using Split_Part to split up Owneraddress column
SELECT SPLIT_PART(Owneraddress,',', 1) as one,
SPLIT_PART(Owneraddress,',', 2) as two,
SPLIT_PART(Owneraddress,',', 3) as three
FROM nashville;

--Then add and update the columns
ALTER TABLE nashville
ADD COLUMN owner_address VARCHAR(512);

UPDATE nashville
SET owner_address = SPLIT_PART(Owneraddress,',', 1);

ALTER TABLE nashville
ADD COLUMN owner_city VARCHAR(512);

UPDATE nashville
SET owner_city = SPLIT_PART(Owneraddress,',', 2);

ALTER TABLE nashville
ADD COLUMN owner_state VARCHAR(512);

UPDATE nashville
SET owner_state = SPLIT_PART(Owneraddress,',', 3);
```

### 4. Change 'Y' and 'N' to 'Yes' and 'No' in soldasvacant Column
```sql
--Use Case function to change Y and N into Yes and No
SELECT soldasvacant,
    CASE
        WHEN soldasvacant = 'N' THEN 'No'
        WHEN soldasvacant = 'Y' THEN 'Yes'
        ELSE soldasvacant
        END
    FROM nashville;

--Update using CASE from above
UPDATE nashville
SET soldasvacant = CASE
        WHEN soldasvacant = 'N' THEN 'No'
        WHEN soldasvacant = 'Y' THEN 'Yes'
        ELSE soldasvacant
        END;

--Use to make sure that it is just Yes and No now
SELECT soldasvacant, count(soldasvacant)
FROM nashville
GROUP BY soldasvacant;
```

### 5. Removing Duplicates

```sql
-- Find and delete duplicates using a CTE
WITH cte AS(
SELECT
    uniqueid
FROM (
    SELECT
        uniqueid,
        ROW_NUMBER() OVER (PARTITION BY 
        parcelID,
        propertyaddress,
        SalePrice,
        sale_date,
        LegalReference) row_num
    FROM 
        nashville
)
WHERE row_num > 1)

DELETE FROM nashville
WHERE uniqueid IN (SELECT * FROM cte)


--Run to then Export cleaned CSV file
SELECT *
FROM Nashville
```

# Power BI
After exporting the dataset from SQL, I then used Power BI to further clean the data and make a dashboard of visualizations.

## 1. Make New Measures to Filter Out Outliers
- To increase the usefullness of the data, I made new measures for acres, uniqueid's, and total value. Each measure was a COUNT, allowing me to filter out cities and land uses that were skewing the results, since they had limited data. Example:
```Excel
Total Unique IDs = Count(Nashville_Cleaned[uniqueid])
``` 

## 2. Make New Columns to Expand the Usefulness of the Data
- In order to better compare real estate sold in smaller urban areas with those sold in more rural cities surrounding Nashville, I created a column to find the average Sale Price paid per Acre:
```Excel
SalePricePerAcre = IFERROR(Nashville_Cleaned[Sale Price]/Nashville_Cleaned[acreage], 0)
```

## 3. Made Visualizations to Show Key Differences in the Market By City, Land Use, and Year
- The top two visualizations give data on price per acre, average land value, and average total value by city. The bottom two show average sale price by land use, and a trendline of land value, building value, and sale price by year sold.
- I also incorportated the drill down tool into my visualizations to look at differences in price per acre for vacant vs. non-vacant sales. Drilling down by city also affects the other visualizations, making it easier to see city-level data across different criteria.


Check out my Power BI file here: [Nashville Power BI Dashboard](NashvilleBI.pbix)

![Dashboard](Photos\BI_Dashboard.png)

*Dashboard when drilling down into an individual city (Nashville) and Filtering the Years*
![Dashboard](Photos\Dashboard_2.png)

# What I Learned

From working on this project, I've learned new skills in both SQL and Power BI:

- **🧩 Complex SQL Query Crafting:** Used advanced SQL techniques, including SUBSTRING to separate one column into multiple using a delimiter, PARTITION BY to specify which columns I wanted to look for dulplicates in, and WITH clauses to make temporary results sets.
- **📊 Creating New Measures for Filtering:** Used the new meaure tool and the filter by visualization tool to elimnate cities without enough data.
- **💡 Data Visualization:** Leveled up my knowledge of the new column and the drill down tools to make my dashboard visualizations as useful as possible.