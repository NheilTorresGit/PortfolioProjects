/*
Cleaning Data in SQL Queries
*/


SELECT *
FROM ..HousingMain;

--------------

-- STANDARDIZE DATE FORMAT ( since we don't need time on the date columns and it is the standard)

SELECT saleDateConverted, SaleDate, CONVERT(Date,SaleDate)
FROM ..HousingMain;

UPDATE ..HousingMain
SET SaleDate = CONVERT(Date,SaleDate);

--Optional: Make a new column for the updated date without the time

ALTER TABLE ..HousingMain
ADD SaleDateConverted Date;

UPDATE ..HousingMain
SET saleDateConverted = CONVERT(Date,SaleDate);


-- POPULATE PROPERTY ADDRESS DATA

SELECT *
FROM ..HousingMain
--Where PropertyAddress is null
ORDER BY ParcelID;


--Populate Property Address, it seems important and a pattern where two unique rows
--with the same ParcelID row seem share the same PropertyAddress
--With that hope, we need to update the null address with info with the matching parcelid with no null addresses

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM ..HousingMain a
JOIN ..HousingMain b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM ..HousingMain a
JOIN ..HousingMain b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;


-- BREAKING OUT ADDRESS INTO 3 COLUMNS (Address, City, State)


--Splitting Property Address

SELECT PropertyAddress
FROM ..HousingMain;
--Where PropertyAddress is null
--order by ParcelID

SELECT
PropertyAddress AS OriginalAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) AS City

FROM ..HousingMain;


--Add new columns
ALTER TABLE ..HousingMain
ADD PropertySplitAddress NVARCHAR(255);

ALTER TABLE ..HousingMain
ADD PropertySplitCity NVARCHAR(255);

--Fill up new columns with split data from original address
UPDATE ..HousingMain
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1 );

UPDATE ..HousingMain
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress));

SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
FROM ..HousingMain

--Splitting Owner Address

SELECT OwnerAddress
FROM ..HousingMain

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM ..HousingMain

ALTER TABLE ..HousingMain
ADD OwnerSplitAddress NVARCHAR(255);

ALTER TABLE ..HousingMain
ADD OwnerSplitCity NVARCHAR(255);

ALTER TABLE ..HousingMain
ADD OwnerSplitState NVARCHAR(255);

UPDATE ..HousingMain
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3);

UPDATE ..HousingMain
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2);

UPDATE ..HousingMain
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1);

SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM ..HousingMain;


-- CHANGE INCONSISTENT VALUES IN "Sold as Vacant" FIELD


SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS Results
FROM ..HousingMain
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END AS ConvertedSoldAsVacant
FROM ..HousingMain;

UPDATE ..HousingMain
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END;

-- REMOVE DUPLICATES
-- (SWITCH SELECT * AT THE BOTTOME WITH COMMENTED DELETE TO MAKE THE QUERY DELETE DUPLICATED DATA)

WITH RowNumCTE AS(
	SELECT *,
		ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID ) row_num

	FROM ..HousingMain
)

SELECT *
--DELETE 
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- DELETE UNUSED COLUMNS

-- Remove redundant columns
ALTER TABLE ..HousingMain
DROP COLUMN OwnerAddress, PropertyAddress;

-- Remove columns we are not interested at 
ALTER TABLE ..HousingMain
DROP COLUMN TaxDistrict, SaleDate;



SELECT *
FROM ..HousingMain;