-- Looking at Total Claims vs Total Exposure for French regions and respective areas. Scored A-F with A being rural, F being urban centers
---(total exposure defined in this dataset as 1.0=1 total year a policy was at risk for claim)---
-- Claim Frequency calculated by total claims in an area divided by total exposure; shows a group-level rate claims were filed in a given year
---(a claim frequency of 2.073 means there arearound 2 claim events per year of exposure on a policy in the group)---

Select 
  Region, area,
	 COUNT(*) AS total_claims,
	 SUM(Exposure) AS total_exposure, 
	 CAST(
		 COUNT(*)/NULLIF(SUM(Exposure), 0) 
	AS DECIMAL(10,3)) AS Claim_frequency
From dbo.freMTPL2freq
WHERE exposure > 0 
group by 
	Region, area
order by region, area

-- Looking at Claim Frequency again, this time with age groups
-- Shows the claim frequency per year of exposure within age groups

Select 
  CASE
	WHEN DrivAge Between 18 And 22 Then '18-22'
	WHEN DrivAge Between 23 And 28 Then '23-28'
	WHEN DrivAge Between 29 And 35 Then '29-35'
	WHEN DrivAge Between 36 And 43 Then '36-43'
	WHEN DrivAge Between 44 And 52 Then '44-52'
	WHEN DrivAge Between 53 And 65 Then '53-65'
	Else '65+'
END AS Age_band,
 COUNT(*) AS total_claims,
	 SUM(Exposure) AS total_exposure, 
	 CAST(
		 COUNT(*)/NULLIF(SUM(Exposure), 0) 
	AS DECIMAL(10,3)) AS Claim_frequency
From dbo.freMTPL2freq
WHERE exposure > 0 
group by 
	  CASE
	WHEN DrivAge Between 18 And 22 Then '18-22'
	WHEN DrivAge Between 23 And 28 Then '23-28'
	WHEN DrivAge Between 29 And 35 Then '29-35'
	WHEN DrivAge Between 36 And 43 Then '36-43'
	WHEN DrivAge Between 44 And 52 Then '44-52'
	WHEN DrivAge Between 53 And 65 Then '53-65'
	Else '65+'
END
order by Age_band

-- Looking at Bonus Malus groups across areas and whether it corresponds to higher frequency of claims

Select 
  CASE	
	WHEN bonusmalus <= 75 THEN 'Best'
	WHEN bonusmalus <= 100 THEN 'Good'
	WHEN bonusmalus <= 125 THEN 'Moderate'
	WHEN bonusmalus <= 150 THEN 'High'
	Else 'Worst' 
END AS bonusmalus_group,
  area, 
 COUNT(*) AS total_claims,
	 SUM(Exposure) AS total_exposure, 
	 CAST(
		 COUNT(*)/NULLIF(SUM(Exposure), 0) 
	AS DECIMAL(10,3)) AS Claim_frequency
From dbo.freMTPL2freq
WHERE exposure > 0 
group by area, CASE	
	WHEN bonusmalus <= 75 THEN 'Best'
	WHEN bonusmalus <= 100 THEN 'Good'
	WHEN bonusmalus <= 125 THEN 'Moderate'
	WHEN bonusmalus <= 150 THEN 'High'
	Else 'Worst' 
END
order by 
	 bonusmalus_group, area

-- Vehicle power categories with the highest claim_frequency
-- A higher VehPower # means a more powerful engine, with 4 being the least powerful

Select
Vehpower,
 COUNT(*) AS total_claims, 
	 CAST(
		 COUNT(*)/NULLIF(SUM(Exposure), 0) 
	AS DECIMAL(10,3)) AS Claim_frequency
From dbo.freMTPL2freq
WHERE exposure > 0 
group by 
	VehPower
order by Claim_frequency desc 

-- totals

select  Count(*) as Total_Claims, count(distinct region) as total_regions, 
		 CAST(
		 COUNT(*)/NULLIF(SUM(Exposure), 0) 
	AS DECIMAL(10,3)) AS Claim_frequency
from dbo.freMTPL2freq

-- Looking again at Region/Area claim frequency, but also average payout per claim and average cost per policy anually. 

Select 
	f.region, f.area,
	 CAST(COUNT(f.IDPol)/NULLIF(SUM(f.Exposure), 0) AS DECIMAL(10,3)) AS frequency,
	CAST(AVG(sev.ClaimAmount) AS DECIMAL(12,2)) as AVG_payout,
	CAST(SUM(sev.claimamount) /SUM(f.exposure)AS Decimal(12,2)) AS loss_cost
	from dbo.freMTPL2freq f
Left Join dbo.freMTPL2sev sev
	ON f.IDPOL = sev.IDPOL
	group by f.region, f.area
	order by region, area 

-- using CTE to view risk levels for areas based on average cost per policy

With AreaRisk AS (
Select 
	region, area,
	 CAST(COUNT(f.IDPol)/NULLIF(SUM(f.Exposure), 0) AS DECIMAL(10,3)) AS frequency,
	CAST(AVG(sev.ClaimAmount) AS DECIMAL(12,2)) as AVG_payout,
	CAST(SUM(sev.claimamount) /SUM(f.exposure)AS Decimal(12,2)) AS loss_cost
	from dbo.freMTPL2freq f
Left Join dbo.freMTPL2sev sev
	ON f.IDPOL = sev.IDPOL
	group by region, area
)
SELECT *,
	CASE
		WHEN loss_cost >230 THEN 'HIGH'
		WHEN loss_cost >=155 THEN 'Elevated'
		WHEN Loss_cost >=100 THEN 'medium'
		ELSE 'low'
	END AS risk_level
FROM AreaRisk
Order By loss_cost Desc

-- TEMP TABLE

Drop Table if exists #risklevelbyarea
CREate table #RiskLevelbyArea
(
Region nvarchar(255),
Area nvarchar(255),
frequency decimal (10,3),
AVG_payout decimal (12,2), 
loss_cost decimal (12,2)
)

Insert Into #RiskLevelbyArea
Select 
	region, area,
	 CAST(COUNT(f.IDPol)/NULLIF(SUM(f.Exposure), 0) AS DECIMAL(10,3)) AS frequency,
	CAST(AVG(sev.ClaimAmount) AS DECIMAL(12,2)) as AVG_payout,
	CAST(SUM(sev.claimamount) /SUM(f.exposure)AS Decimal(12,2)) AS loss_cost
	from dbo.freMTPL2freq f
Left Join dbo.freMTPL2sev sev
	ON f.IDPOL = sev.IDPOL
	group by region, area

Select * From #RiskLevelbyArea

-- view data for visualization 

Create view RiskLevelinArea as
Select 
	region, area,
	 CAST(COUNT(f.IDPol)/NULLIF(SUM(f.Exposure), 0) AS DECIMAL(10,3)) AS frequency,
	CAST(AVG(sev.ClaimAmount) AS DECIMAL(12,2)) as AVG_payout,
	CAST(SUM(sev.claimamount) /SUM(f.exposure)AS Decimal(12,2)) AS loss_cost
	from dbo.freMTPL2freq f
Left Join dbo.freMTPL2sev sev
	ON f.IDPOL = sev.IDPOL
	group by region, area

Select * from RiskLevelinArea

Create view ClaimsByPower as
Select
Vehpower,
 COUNT(*) AS total_claims, 
	 CAST(
		 COUNT(*)/NULLIF(SUM(Exposure), 0) 
	AS DECIMAL(10,3)) AS Claim_frequency
From dbo.freMTPL2freq
WHERE exposure > 0 
group by 
	VehPower

Create view BonusMalusFreq as 
Select 
  CASE	
	WHEN bonusmalus <= 75 THEN 'Best'
	WHEN bonusmalus <= 100 THEN 'Good'
	WHEN bonusmalus <= 125 THEN 'Moderate'
	WHEN bonusmalus <= 150 THEN 'High'
	Else 'Worst' 
END AS bonusmalus_group,
  area, 
 COUNT(*) AS total_claims,
	 SUM(Exposure) AS total_exposure, 
	 CAST(
		 COUNT(*)/NULLIF(SUM(Exposure), 0) 
	AS DECIMAL(10,3)) AS Claim_frequency
From dbo.freMTPL2freq
WHERE exposure > 0 
group by area, CASE	
	WHEN bonusmalus <= 75 THEN 'Best'
	WHEN bonusmalus <= 100 THEN 'Good'
	WHEN bonusmalus <= 125 THEN 'Moderate'
	WHEN bonusmalus <= 150 THEN 'High'
	Else 'Worst' 
END

Create view AgeFrequency as 
Select 
  CASE
	WHEN DrivAge Between 18 And 22 Then '18-22'
	WHEN DrivAge Between 23 And 28 Then '23-28'
	WHEN DrivAge Between 29 And 35 Then '29-35'
	WHEN DrivAge Between 36 And 43 Then '36-43'
	WHEN DrivAge Between 44 And 52 Then '44-52'
	WHEN DrivAge Between 53 And 65 Then '53-65'
	Else '65+'
END AS Age_band,
 COUNT(*) AS total_claims,
	 SUM(Exposure) AS total_exposure, 
	 CAST(
		 COUNT(*)/NULLIF(SUM(Exposure), 0) 
	AS DECIMAL(10,3)) AS Claim_frequency
From dbo.freMTPL2freq
WHERE exposure > 0 
group by 
	  CASE
	WHEN DrivAge Between 18 And 22 Then '18-22'
	WHEN DrivAge Between 23 And 28 Then '23-28'
	WHEN DrivAge Between 29 And 35 Then '29-35'
	WHEN DrivAge Between 36 And 43 Then '36-43'
	WHEN DrivAge Between 44 And 52 Then '44-52'
	WHEN DrivAge Between 53 And 65 Then '53-65'
	Else '65+'
END

Create view AreaRiskClass as
Select 
	region, area,
	 CAST(COUNT(f.IDPol)/NULLIF(SUM(f.Exposure), 0) AS DECIMAL(10,3)) AS frequency,
	CAST(AVG(sev.ClaimAmount) AS DECIMAL(12,2)) as AVG_payout,
	CAST(SUM(sev.claimamount) /SUM(f.exposure)AS Decimal(12,2)) AS loss_cost,
	CASE
		WHEN CAST(SUM(sev.claimamount) /SUM(f.exposure)AS Decimal(12,2)) >230 THEN 'HIGH'
		WHEN CAST(SUM(sev.claimamount) /SUM(f.exposure)AS Decimal(12,2)) >=155 THEN 'Elevated'
		WHEN CAST(SUM(sev.claimamount) /SUM(f.exposure)AS Decimal(12,2)) >=100 THEN 'medium'
		ELSE 'low'
	END AS risk_level
from dbo.freMTPL2freq f
Left Join dbo.freMTPL2sev sev
	ON f.IDPOL = sev.IDPOL
group by region, area