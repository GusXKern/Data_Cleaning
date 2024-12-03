DROP TABLE nashville;

CREATE TABLE nashville (
    UniqueID	INT,
    ParcelID	VARCHAR(512),
    LandUse	VARCHAR(512),
    PropertyAddress	VARCHAR(512),
    SaleDate	VARCHAR(512),
    SalePrice	REAL,
    LegalReference	VARCHAR(512),
    SoldAsVacant	VARCHAR(512),
    OwnerName	VARCHAR(512),
    OwnerAddress	VARCHAR(512),
    Acreage	FLOAT(24),
    TaxDistrict	VARCHAR(512),
    LandValue	INT,
    BuildingValue	INT,
    TotalValue	INT,
    YearBuilt	INT,
    Bedrooms	INT,
    FullBath	INT,
    HalfBath	VARCHAR(512)
);


COPY Nashville FROM 'C:\Users\guske\OneDrive\Data_Cleaning\Nashville.csv' DELIMITER ',' CSV HEADER; -- For permissions reasons I had to run this using \copy in pgadmin4 in the PSQL Tool



/* Data Cleaning Steps
1. Change saledate format
2. Populate Property Address Data
*/

-- 1. Change saledate format from 01-Jan-00 to 2000-01-01

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

/* 2. Populate Property Address Data:
- There are NULL values; but some entries without a NULL have the same parcelID as those with a NULL
- I want to match these values to eliminate NULLS */

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





-- 3. Break out Address into (Address: city, state)
-- Use this to break the address up
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

--Using Split_Part to split up Owneraddress column
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

--4. Change 'Y' and 'N' to Yes and No in soldasvacant column
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

--5.  Removing Duplicates
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



