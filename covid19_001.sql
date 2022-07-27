--Total Cases Vs. Total Deaths
--Shows you the likelihood of dying if you get COVID19 in that location

SELECT TOP (10) location "Location",
	date "Date",
	total_cases "Total Cases",
	total_deaths "Total Deaths", 
	ROUND((total_deaths/total_cases)*100,2) AS "Death Rate"
FROM jim.dbo.covid_deaths$
WHERE location='United States'
ORDER BY 2 DESC;

-- Total Cases vs. Population
-- Shows how many people contracted COVID19 of that location's population

SELECT TOP (10) location "Location",
	date "Date",
	total_cases "Total Cases",
	population "Population",
	ROUND((total_cases/population)*100,2) AS "Infection Rate"
FROM dbo.covid_deaths$
WHERE location='United States'
ORDER BY 2 DESC;

-- Shows Locations w/ Highest Infection Rate Compared to Population

SELECT  location "Location",
	date "Date",
	MAX(total_cases) "Total Cases",
	population "Population",
	ROUND(MAX((total_cases)/population)*100,2) AS "Infection Rate"
FROM dbo.covid_deaths$
GROUP BY date,location, population
ORDER BY [Infection Rate] DESC;

-- Shows Locations w/ Highest Death Rates per Population

SELECT location "Location",
	MAX(CAST(total_deaths as int)) "Total Death Count",
	population "Population"
FROM dbo.covid_deaths$
WHERE location NOT LIKE '%income%' AND continent IS NOT NULL
GROUP BY location, population
ORDER BY 2 DESC;

-- Shows Continents With the Highest Death Count

SELECT continent "Continent", 
	MAX(CAST(total_deaths as int)) "Total Death Count"
FROM dbo.covid_deaths$
WHERE location NOT LIKE '%income%' AND continent IS NOT NULL
GROUP BY continent
ORDER BY "Total Death Count" DESC;

-- Global Numbers

SELECT date,
	SUM(new_cases) AS "Total Cases", 
	SUM(cast(new_deaths AS INT)) AS "Total Deaths", 
	SUM(cast(new_deaths AS INT))/SUM(New_Cases)*100 AS "Death Rate"
  FROM [jim].[dbo].[covid_deaths$]
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 2 DESC;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM jim.dbo.covid_deaths$ dea
Join jim.dbo.covid_vaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3;

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) as
	(
		Select dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations, 
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, 
		dea.Date) as RollingPeopleVaccinated
--, 
From jim.dbo.covid_deaths$ dea
Join jim.dbo.covid_vaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as "Percentage of People Vaxed"
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From jim.dbo.covid_deaths$ dea
Join jim.dbo.covid_vaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM jim.dbo.covid_deaths$ dea
JOIN jim.dbo.covid_vaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL;
