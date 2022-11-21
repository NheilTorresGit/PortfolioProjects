
--This is an sql query set for the CovidStatProject database
--The database data was taken from : https//ourworldindata.org/covid-deaths
--However, for the sake of testing queries in this project, we separated our databases into two tables, dbo.CovidDeaths and dbo.CovidVaccinations respectively
--The numbers for this dataset are accurate, real numbers provided by ourworldindata.org, last updated 2022-11-07


--SELECT DATA TO BE USED

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ..CovidDeaths
WHERE continent IS NOT NULL --in this data, having continent means location data is not the summary of the continent
ORDER BY location, date;
   

--QUERY WHICH COMPARES TOTAL CASES VS TOTAL DEATHS IN KUWAIT

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM ..CovidDeaths
WHERE location = 'Kuwait'
ORDER BY location, date;


--QUERY WHICH COMPARES TOTAL CASES VS POPULATION IN KUWAIT
--Details show which percent of the population had Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS population_case_percentage
FROM ..CovidDeaths
WHERE location = 'Kuwait'
ORDER BY location, date;


--QUERY WHICH COUNTRY HAS THE HIGHEST INFECTION RATE
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS population_case_percentage
FROM ..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY population_case_percentage DESC;


--SIMILAR QUERY ABOVE BUT ONLY THE TOP 10
SELECT TOP 10 location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS population_case_percentage
FROM ..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY population_case_percentage DESC;


--QUERY WHICH COUNTRY HAS THE HIGHEST MORTALITY COUNT PER POPULATION
SELECT location, MAX(CAST(total_deaths AS int)) AS total_deaths
FROM ..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_deaths DESC;


--QUERY WHICH CONTINENT HAS THE HIGHEST MORTALITY COUNT PER POPULATION
SELECT location, MAX(CAST(total_deaths AS int)) AS total_deaths
FROM ..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income' --location also has list for places with different income standings so having this is good
GROUP BY location
ORDER BY total_deaths DESC;


--QUERY THE TOTAL NUMBER OF NEW CASES FROM EACH DAY

SELECT date, SUM(new_cases)
FROM ..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, SUM(new_cases) ASC;


--QUERY THE TOTAL NUMBER OF NEW DEATHS FROM EACH DAY

SELECT date, SUM(CAST(new_deaths AS bigint)) AS total_new_deaths
FROM ..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, total_new_deaths ASC;


--QUERY THE DEATH PERCENTAGE IN THE WORLD

SELECT date, (SUM(CAST(new_deaths AS bigint))/SUM(new_cases))*100 AS death_percentage
FROM ..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, death_percentage;

--QUERY LAST THREE QUERIES BUT AS A GRAND TOTAL

SELECT SUM(new_cases) AS total_new_cases, SUM(CAST(new_deaths AS bigint)) AS total_new_deaths, (SUM(CAST(new_deaths AS bigint))/SUM(new_cases))*100 AS death_percentage
FROM ..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY death_percentage;


--JOIN QUERY WHERE WE ALIGN CovidDeaths AND CovidVaccinations' DATA TOGETHER
SELECT *
FROM ..CovidDeaths AS Deaths
	INNER JOIN ..CovidVaccinations AS Vacc ON Vacc.date = Deaths.date AND
	Vacc.location = Deaths.location;


--QUERY WHERE WE COMPARE TOTAL POPULATION VS TOTAL VACCINATIONS
--We used OVER here to preserve each day's details BUT also have details for total_new_vaccinations
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vacc.new_vaccinations,  SUM(CAST(Vacc.new_vaccinations AS bigint)) OVER (PARTITION BY Deaths.location) AS total_new_vaccinations
FROM ..CovidDeaths AS Deaths
	INNER JOIN ..CovidVaccinations AS Vacc ON Vacc.date = Deaths.date AND
	Vacc.location = Deaths.location
WHERE Deaths.continent IS NOT NULL
ORDER BY Deaths.location, Deaths.date;

--Similar query but instead total_new_vaccinations are being updated by the day instead of the total records of this dataset
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vacc.new_vaccinations,  SUM(CAST(Vacc.new_vaccinations AS bigint)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) AS total_new_vaccinations_per_roll
FROM ..CovidDeaths AS Deaths
	INNER JOIN ..CovidVaccinations AS Vacc ON Vacc.date = Deaths.date AND
	Vacc.location = Deaths.location
WHERE Deaths.continent IS NOT NULL
ORDER BY Deaths.location, Deaths.date;


--QUERY WITH ALL THE INFORMATION ABOVE + A VACCINATED/POPULATION COLUMN
WITH PopulationVSVaccinated(continent, location, date, population, new_vaccinations, new_vac_per_roll)
AS
(
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vacc.new_vaccinations,  SUM(CAST(Vacc.new_vaccinations AS bigint)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) AS total_new_vaccinations_per_roll
FROM ..CovidDeaths AS Deaths
	INNER JOIN ..CovidVaccinations AS Vacc ON Vacc.date = Deaths.date AND
	Vacc.location = Deaths.location
WHERE Deaths.continent IS NOT NULL
--ORDER BY Deaths.location, Deaths.date
)
SELECT *, (new_vac_per_roll/population)*100 AS vaccinated_population_in_roll
FROM PopulationVSVaccinated;



------------------
------ VIEW ------
------------------

--View for Kuwait's covid details such as total cases, deaths, death percentage, vaccinations, etc

CREATE VIEW ViewKuwaitCovidDetails AS
SELECT Deaths.location, Deaths.date, Deaths.total_cases, Deaths.total_deaths, (Deaths.total_deaths/Deaths.total_cases)*100 AS death_percentage, Vacc.total_vaccinations, Vacc.people_fully_vaccinated
FROM ..CovidDeaths AS Deaths
	INNER JOIN ..CovidVaccinations AS Vacc ON Vacc.date = Deaths.date AND
	Vacc.location = Deaths.location
WHERE Deaths.location = 'Kuwait' and Vacc.location = 'Kuwait'
--ORDER BY location, date;


--View for Population Vaccinated vs Unvaccinated

CREATE VIEW PercentagePopulationVaccinated AS
WITH PopulationVSVaccinated(continent, location, date, population, new_vaccinations, new_vac_per_roll)
AS
(
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vacc.new_vaccinations,  SUM(CAST(Vacc.new_vaccinations AS bigint)) OVER (PARTITION BY Deaths.location ORDER BY Deaths.location, Deaths.date) AS total_new_vaccinations_per_roll
FROM ..CovidDeaths AS Deaths
	INNER JOIN ..CovidVaccinations AS Vacc ON Vacc.date = Deaths.date AND
	Vacc.location = Deaths.location
WHERE Deaths.continent IS NOT NULL
--ORDER BY Deaths.location, Deaths.date
)
SELECT *, (new_vac_per_roll/population)*100 AS vaccinated_population_in_roll
FROM PopulationVSVaccinated;

CREATE VIEW ViewGlobalSumOfCases AS
SELECT SUM(new_cases) AS total_new_cases, SUM(CAST(new_deaths AS bigint)) AS total_new_deaths, (SUM(CAST(new_deaths AS bigint))/SUM(new_cases))*100 AS death_percentage
FROM ..CovidDeaths
WHERE continent IS NOT NULL
--ORDER BY death_percentage;