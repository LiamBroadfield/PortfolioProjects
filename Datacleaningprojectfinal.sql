-- Cleaning Data in SQL

Select *
from dbo.insurance_reporting_dataset

----------------------------------------------------------------------------------------------

-- Standardize Date

Select CONVERT(Date, Reporting_Period, 103)
from PortfolioProject.dbo.insurance_reporting_dataset

Update Insurance_reporting_dataset
SET REporting_period = CONVERT(Date, Reporting_Period, 103)

-----------------------------------------------------------------------------------------------

-- Populate Company data
-- Added Company ID as identifier for a join

Select *
from PortfolioProject.dbo.insurance_reporting_dataset
Where Company is null
order by reporting_period
 
Select a.CompanyID, a.Company AS CurrentCompany, 
b.Company as CompanyName, COALESCE(a.Company, b.Company) AS Company_Name
from dbo.Insurance_reporting_dataset a
Left Join (VALUES
(1, 'Acme Insurance'), (2, 'Beacon Mutual'), (3, 'Crestline Assurance'), (4, 'Delta Underwriters'), (5, 'Evergreen Casualty') )
AS b(CompanyID, Company)
ON a.CompanyID = b.CompanyID

update a 
SET a.Company = b.Company
from dbo.Insurance_reporting_dataset a
Join (VALUES
(1, 'Acme Insurance'), (2, 'Beacon Mutual'), (3, 'Crestline Assurance'), (4, 'Delta Underwriters'), (5, 'Evergreen Casualty') )
AS b(CompanyID, Company)
ON a.CompanyID = b.CompanyID
Where a.COmpany IS Null

-----------------------------------------------------------------------------------------------

-- Splitting Reporting Period into date and year

Select
Substring(reporting_period, 1, CHARINDEX('-',Reporting_period)-1)as Year,
Substring(reporting_period, CHARINDEX('-',Reporting_period)+1, LEN(reporting_period)) as date
from dbo.insurance_reporting_dataset

Alter table dbo.insurance_reporting_dataset
Add PeriodSplitYear int

update dbo.insurance_reporting_dataset
set PeriodSplitYear = Substring(reporting_period, 1, CHARINDEX('-',Reporting_period)-1)

Alter table dbo.insurance_reporting_dataset
add PeriodSplitdate nvarchar(255)

update dbo.insurance_reporting_dataset
set PeriodSplitDate = Substring(reporting_period, CHARINDEX('-',Reporting_period)+1, LEN(reporting_period))

-----------------------------------------------------------------------------------------------

-- Change Y/N to "yes" and "no" in "IsAudited" column

Select Distinct(IsAudited), Count(IsAudited)
from insurance_reporting_dataset
group by IsAudited
order by 2

select Isaudited,
Case When IsAudited = 'Y' THEN 'Yes'
When Isaudited = 'N' THEN 'No'
Else IsAudited
END
From insurance_reporting_dataset

update insurance_reporting_dataset
set isaudited = Case When IsAudited = 'Y' THEN 'Yes'
When Isaudited = 'N' THEN 'No'
Else IsAudited
END

-----------------------------------------------------------------------------------------------

-- Checking For duplicate data

With RowNumCTE AS(
Select *, 
	ROW_Number()OVER(
	Partition By ImportBatchID, Acquisition_Expenses, Claims_incurred,Premiums_written
	Order by ImportBatchID) row_num

from insurance_reporting_dataset
)
Delete
from RowNumCTE
where row_num > 1

-----------------------------------------------------------------------------------------------

-- Deleting Useless Columns

Select *from dbo.insurance_reporting_dataset

Alter Table insurance_reporting_dataset
Drop column reporting_period, year

Alter Table insurance_reporting_dataset
Drop column ImportbatchID --Random #, only useful for finding dupes- since none, delete