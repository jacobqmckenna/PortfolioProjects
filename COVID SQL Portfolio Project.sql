SELECT *
FROM CovidDeaths
WHERE continent is not null
ORDER BY 3,4


SELECT	location,
		date,
		total_cases,
		new_cases,
		total_deaths,
		population
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID in your country

SELECT	location,
		date,
		total_cases,
		total_deaths,
		ROUND((total_deaths/total_cases)*100,2) as death_percentatge
FROM ProjectPortfolio..CovidDeaths
WHERE location = 'United States' AND continent is not null
ORDER BY 1,2


-- Looking at Total Cases vs Population

SELECT	location,
		date,
		population,
		total_cases,
		ROUND((total_cases/population)*100,2) as percentage_population
FROM ProjectPortfolio..CovidDeaths
WHERE location = 'United States' AND continent is not null
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT	location,
		population,
		Max(total_cases) as highest_infection_count,
		ROUND(Max((total_cases/population))*100,2) as percentage_population_infected
FROM ProjectPortfolio..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY percentage_population_infected DESC


-- Showing Countries with the Highest Death County per Population

SELECT	location,
		MAX(cast(total_deaths as BigInt)) as total_death_count
FROM ProjectPortfolio..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY total_death_count DESC

-- Let's break things down by continent

SELECT	location,
		Max(cast(total_deaths as BigInt)) as total_death_count
FROM	ProjectPortfolio..CovidDeaths
WHERE	continent is null
		AND
		location in (SELECT DISTINCT continent
					FROM ProjectPortfolio..CovidDeaths
					WHERE continent is not null)
GROUP BY location
ORDER BY total_death_count DESC


-- Global deaths by date

SELECT	date,
		sum(new_cases) as total_cases,
		Sum(new_deaths) as total_deaths,
		SUM(new_deaths)/sum(nullif(new_cases,0))*100 as death_percentatge
FROM ProjectPortfolio..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1

-- Overall global deahts

SELECT	sum(new_cases) as total_cases,
		Sum(new_deaths) as total_deaths,
		SUM(new_deaths)/sum(nullif(new_cases,0))*100 as death_percentatge
FROM ProjectPortfolio..CovidDeaths
WHERE continent is not null
ORDER BY 1

-- Looking at Total Population vs Vaccinations

SELECT	d.continent,
		d.location,
		d.date,
		d.population,
		v.new_vaccinations,
		SUM(v.new_vaccinations) OVER (Partition BY d.location ORDER BY d.location, d.date) as rolling_vaccinations
FROM ProjectPortfolio..CovidDeaths as d
JOIN ProjectPortfolio..CovidVaccinations as v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null
ORDER BY 2,3

-- Using CTE to calculate roling percentage of population vaccinated by location

WITH PopVsVaccination (continent, location, date, population, new_vaccinations, rolling_vaccinations)
AS
(SELECT	d.continent,
		d.location,
		d.date,
		d.population,
		v.new_vaccinations,
		SUM(v.new_vaccinations) OVER (Partition BY d.location ORDER BY d.location, d.date) as rolling_vaccinations
FROM ProjectPortfolio..CovidDeaths as d
JOIN ProjectPortfolio..CovidVaccinations as v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null
--ORDER BY 2,3
)
SELECT	*,
		rolling_vaccinations/population * 100
FROM PopVsVaccination		


-- Using temp table to calculate roling percentage of population vaccinated by location

 DROP TABLE IF exists #PercentPopulationVaccinated
 Create TABLE #PercentPopulationVaccinated
 (
 continent nvarchar(255),
 location nvarchar(255),
 date datetime,
 population numeric,
 new_vaccinations numeric,
 rolling_vaccinations numeric
 )

Insert into #PercentPopulationVaccinated
 SELECT	d.continent,
		d.location,
		d.date,
		d.population,
		v.new_vaccinations,
		SUM(v.new_vaccinations) OVER (Partition BY d.location ORDER BY d.location, d.date) as rolling_vaccinations
FROM ProjectPortfolio..CovidDeaths as d
JOIN ProjectPortfolio..CovidVaccinations as v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null
--ORDER BY 2,3

SELECT	*,
		rolling_vaccinations/population * 100
FROM #PercentPopulationVaccinated	


-- Creating View to store data for later visualizations

USE ProjectPortfolio
GO
Create View PercentPopulationVaccinated	as
SELECT	d.continent,
		d.location,
		d.date,
		d.population,
		v.new_vaccinations,
		SUM(v.new_vaccinations) OVER (Partition BY d.location ORDER BY d.location, d.date) as rolling_vaccinations
FROM ProjectPortfolio..CovidDeaths as d
JOIN ProjectPortfolio..CovidVaccinations as v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null
--ORDER BY 2,3