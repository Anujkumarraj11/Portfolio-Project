
select *
from [portfolio project].dbo.covid_death$ as  tb;

select *
from [portfolio project].dbo.covid_Vac$;

select date,(sum(cast(total_deaths as int))/sum(population))*100 as per_death from [portfolio project].dbo.covid_death$
group by date
order by per_death desc;

select continent,(sum(cast(total_deaths as float))/population)*100 as per_death 
from [portfolio project].dbo.covid_death$
group by continent
order by per_death desc;

--Total death per total case in specific country
select location,cast(total_deaths as float) as tot_death,total_cases, (cast(total_deaths as float)/total_cases)*100 as death_per
from [portfolio project].dbo.covid_death$
order by tot_death desc



alter table [portfolio project].dbo.covid_death$
alter column total_deaths float;

alter table [portfolio project].dbo.covid_death$
alter column total_cases float;


Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [portfolio project].dbo.covid_death$
where location like '%stan'
order by 1,2;

Select Location, date,total_deaths,population, (total_cases/population)*100 as DeathPercentage
From [portfolio project].dbo.covid_death$
where location like '%stan'
order by 1,2;

Select Location,sum(total_deaths) as death_per_location, (sum(total_deaths) /sum(total_cases))*100 as DeathPercentage_per_country
From [portfolio project].dbo.covid_death$
group by location
having sum(total_deaths) /sum(total_cases) is not null
order by 3;

Select Location,sum(total_deaths) as death_per_location, (sum(total_deaths) /sum(total_cases))*100 as DeathPercentage_per_country
From [portfolio project].dbo.covid_death$
group by location
having sum(total_deaths) /sum(total_cases) is not null
order by 3

-- Countries with Highest Infection Rate compared to Population
Select Location,max(total_cases) as Max_infection, max((total_cases/population))*100 as Per_populatio_infection
From [portfolio project].dbo.covid_death$
group by location,population
order by 3

-- Countries with Highest Death Count per Population
Select Location,max(total_deaths) as Max_death, max((total_deaths/population))*100 as Per_populatio_infection
From [portfolio project].dbo.covid_death$
group by location,population
order by 3

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
Select continent,max(total_deaths) as Max_death, max((total_deaths/population))*100 as Per_populatio_infection
From [portfolio project].dbo.covid_death$
Where continent is not null 
group by continent
order by 3

-- GLOBAL NUMBERS
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From [portfolio project].dbo.covid_death$
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

-- Total Population vs Vaccinations

--data conversion
alter table [portfolio project].dbo.covid_Vac$
alter column new_vaccinations float;

alter table [portfolio project].dbo.covid_Vac$
alter column total_vaccinations float;

 --Shows Percentage of Population that has recieved at least one Covid Vaccine
Select de.continent,de.location,de.date ,de.population,
va.new_vaccinations,sum(CAST(va.new_vaccinations AS BIGINT)) 
over (partition by de.location order by de.location,de.date) as RollingPeopleVaccinated
,(sum(CAST(va.new_vaccinations AS BIGINT)) 
over (partition by de.location order by de.location,de.date))*100/de.population as PERPeopleVaccinated
--,(RollingPeopleVaccinated/de.population)*100
From [portfolio project].dbo.covid_death$ as de
join [portfolio project].dbo.covid_Vac$ as va
on de.location=va.location and de.date=va.date
where de.continent is not null 

-- Using CTE to perform Calculation on Partition By in previous query
with popVsvac(Continent, Location, Date, Population,
New_Vaccinations, RollingPeopleVaccinated)
as(Select de.continent,de.location,de.date ,de.population,
va.new_vaccinations,sum(CAST(va.new_vaccinations AS BIGINT)) 
over (partition by de.location order by de.location,de.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/de.population)*100
From [portfolio project].dbo.covid_death$ as de
join [portfolio project].dbo.covid_Vac$ as va
on de.location=va.location and de.date=va.date
where de.continent is not null
)
select *,( RollingPeopleVaccinated/Population)*100 as per_vaccinated
from popVsvac
 
-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated 
Select de.continent,de.location,de.date ,de.population,
va.new_vaccinations,sum(CAST(va.new_vaccinations AS BIGINT)) 
over (partition by de.location order by de.location,de.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/de.population)*100
From [portfolio project].dbo.covid_death$ as de
join [portfolio project].dbo.covid_Vac$ as va
on de.location=va.location and de.date=va.date

select *,( RollingPeopleVaccinated/Population)*100 as per_vaccinated
from #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
CREATE View [portfolio project].dbo.percentPopulationVaccinated as
Select de.continent,de.location,de.date ,de.population,
va.new_vaccinations,sum(CAST(va.new_vaccinations AS BIGINT)) 
over (partition by de.location order by de.location,de.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/de.population)*100
From [portfolio project].dbo.covid_death$ as de
join [portfolio project].dbo.covid_Vac$ as va
on de.location=va.location and de.date=va.date
where de.continent is not null 
