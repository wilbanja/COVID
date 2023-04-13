-- General check of Deaths data
SELECT *  
FROM Deaths  
ORDER BY location, date

-- General check of Vaccinations data
SELECT *  
FROM Vaccinations  
ORDER BY location, date  

-- Total Cases vs. Total Deaths in the US 
SELECT location, date, total_cases, total_deaths
	,CAST(total_deaths AS REAL)/ total_cases * 100 AS death_percentage  
FROM deaths  
WHERE location = 'United States'  
ORDER BY location, date

-- Countries with highest per capita infection rate
SELECT location, population  
    ,MAX(total_cases) as MaxCases  
    ,MAX(total_cases*1.0/population)*100.0 as PercentPopulationInfected  
FROM deaths  
WHERE continent <> '' AND total_cases IS NOT NULL  
GROUP BY location, population  
ORDER BY PercentPopulationInfected DESC  

-- Countries with highest number of deaths
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM deaths
WHERE continent <> '' AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Continents with highest number of deaths
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM deaths
WHERE continent = '' AND location NOT LIKE '%income%' AND location NOT LIKE '%Union%'
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Global number of deaths until today
SELECT SUM(new_cases) AS TotalCases
	,SUM(new_deaths) AS TotalDeaths
	,SUM(new_deaths*1.0)/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
FROM deaths
WHERE continent IS NOT NULL
ORDER BY 1

-- Global number of deaths by date
SELECT date, SUM(new_cases) AS TotalCases
	,SUM(new_deaths) AS TotalDeaths
	,SUM(new_deaths*1.0)/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
FROM deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

-- Join deaths and vaccinations tables
-- Total population vs. vaccinations
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
    ,SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS VaccinationSum
FROM deaths d
JOIN vaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.continent <> ''
ORDER BY 2, 3

-- Vaccination percentage by country using CTE
WITH PopvsVaccination (continent, location, date, population, new_vaccinations, VaccinationSum) AS 
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
    ,SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS VaccinationSum
FROM deaths d
JOIN vaccinations v
    ON d.location = v.location
    AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.continent <> ''
)

--
SELECT *, VaccinationSum*1.0/population*100 AS PercentVaccinated
FROM PopvsVaccination

-- Vaccination percentage by country using temp table
-- Drop table if it exists
DROP TABLE IF EXISTS PercentPopulationVaccinated;

-- Create the table and set data types
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
continent varchar(50),
location varchar(50),
date date,
population int8,
new_vaccinations int4,
VaccinationSum int8
);

-- Insert data into table from SELECT statement
INSERT INTO PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
    ,SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS VaccinationSum
FROM deaths d
JOIN vaccinations v
    ON d.location = v.location
    AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.continent <> '';

-- Show data from temp table
SELECT *, (VaccinationSum*1.0/population) * 100 AS PercentVaccinated
FROM PercentPopulationVaccinated;

-- Create view to store for data visualizations
DROP VIEW IF EXISTS PercentPopluationVaccinated;
CREATE VIEW PercentPopluationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
    ,SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS VaccinationSum
FROM deaths d
JOIN vaccinations v
    ON d.location = v.location
    AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.continent <> ''
ORDER BY 2, 3

SELECT *
FROM percentpopluationvaccinated p 