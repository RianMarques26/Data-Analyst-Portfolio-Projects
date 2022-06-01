
SELECT *
FROM Project1..CovidDeaths
ORDER BY 3, 4


-- Selecting Data

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Project1..CovidDeaths
ORDER BY 1, 2


-- Calculating Death Percentage  (Total Cases vs Total Deaths).
-- Shows the probability of a person dying from COVID according to their country's stats.

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM Project1..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2


-- Calculating Infection Percentage (Total Cases vc Population).
-- Shows the percentage of many people were infected by COVID.

SELECT location, date, total_cases, population, (total_cases/population)*100 AS InfectionPercentage
FROM Project1..CovidDeaths
WHERE location like '%brazil%'
ORDER BY 1, 2


-- Calculating countries with Highest Infection Rate (In comparison to population)

SELECT location, MAX(total_cases) AS HighestInfectionCount, population, MAX((total_cases/population))*100 AS InfectionPercentage
FROM Project1..CovidDeaths
GROUP BY location, population
ORDER BY InfectionPercentage DESC


-- Calculating Countries with Hightest Death Count (In comparison to population)

SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM Project1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Calculating Continents with Hightest Death Count (In comparison to population)

SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM Project1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Global Numbers of cases and deaths per day
-- SUM(new_cases) = total_cases / SUM(cast(new_deaths AS int)) = total_deaths

SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS int)) AS TotalDeaths, 
			 SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS GlobalDeathPercentage
FROM Project1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2


-- Total cases and deaths in the world 

SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS int)) AS TotalDeaths, 
	   SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS GlobalDeathPercentage
FROM Project1..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Counting how many people got vaccinated (Total population vs new vaccinations)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinatedCount
FROM Project1..CovidDeaths AS dea
JOIN Project1..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3


-- Calculating percentage of vaccinated people (Using CTE)

WITH PeopleVac (Continent, Location, Date, Population, New_Vaccinations, PeopleVaccinatedCount)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	   SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS PeopleVaccinatedCount
FROM Project1..CovidDeaths AS dea
JOIN Project1..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)

SELECT *, (PeopleVaccinatedCount/Population)*100 AS PeopleVaccinatedPercentage
FROM PeopleVac


-- Calculating percentage of vaccinated people (Using Temp Table)

DROP TABLE IF EXISTS #PercentPeopleVac 
CREATE TABLE #PercentPeopleVac
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
PeopleVaccinatedCount numeric
)

INSERT INTO #PercentPeopleVac
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	   SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS PeopleVaccinatedCount
FROM Project1..CovidDeaths AS dea
JOIN Project1..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *, (PeopleVaccinatedCount/Population)*100 AS PeopleVaccinatedPercentage
FROM #PercentPeopleVac 
ORDER BY 2, 3


-- Creating View for later visualizations

CREATE VIEW PercentPeopleVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	   SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS PeopleVaccinatedCount
FROM Project1..CovidDeaths AS dea
JOIN Project1..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL