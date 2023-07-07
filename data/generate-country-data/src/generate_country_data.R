#############################################
## Background ###############################
#############################################

## This script contains code to process raw data into a country-level summary
## of the best identified, most recently published data elements
## original data are archived in the data/subdirectory
## assume working directory is set to IHR-costing

#############################################
## Setup ####################################
#############################################

## NOTE: if you don't already have these libraries installed, you can do so by running install.packages()
## example: install.packages("googlesheets4")

## Load libraries
library(dplyr) ## reshape, reformat, recode data: https://dplyr.tidyverse.org/reference/recode.html
library(sqldf) ## for writing SQL in r
library(readr) ## for write_delim

#############################################
## Read in data #############################
#############################################

## base data from CIA world factbook
base <- read.delim("data/generate-country-data/inputs/cia_factbook/countries_fb.tsv", header = TRUE)

## WHO membership data from WHO
who_membership <- read.delim("data/generate-country-data/inputs/who/who_member_states.tsv", header = TRUE)

## NAPHS dates and data reporting from WHO
naphs_dates <- read.delim("data/generate-country-data/inputs/who/naphs_dates.tsv", header = TRUE)

## hospital data from OECD
hospitals <- read.delim("data/generate-country-data/inputs/oecd/country_hospitals.tsv", header = TRUE)

## TODO: look into flag codes in this dataset
## utilization data from OECD
utilization <- read.csv("data/generate-country-data/inputs/oecd/utilization_dataset.csv", header = TRUE)

## MD dataset from WHO
md <- read.csv("data/generate-country-data/inputs/who/medical_doctors_per10000.csv", header = TRUE)

## nurse/midwife dataset from WHO
nurse_midwife <- read.csv("data/generate-country-data/inputs/who/ursing_midwives_per10000.csv", header = TRUE)

## CHW dataset from WHO
chw <- read.csv("data/generate-country-data/inputs/who/chw_count.csv", header = TRUE)

## SPAR dataset (2022)
spar2022 <- read.delim("data/generate-country-data/inputs/who/IHRScoreperCapacity_202305051146.tsv", header = TRUE)
  
#############################################
## Assorted data cleaning ###################
#############################################

## trim trailing white space in 2022 SPAR dataset 
spar2022$country_clean <- trimws(spar2022$Country, which = "right")

## clean up field name so it can be recognized by sqldf below
names(spar2022)[which(names(spar2022) == "C.6.1")] <- "C61"

## clean up missing SPAR data for select fields
spar2022$total_average[which(spar2022$total_average == "no data")] <- NA

#############################################
## Clean country names/ISOs #################
#############################################

## United States (modify in base file from CIA Word Factbook)
if(any(base$name == "United States")){
  base[which(base$name == "United States"),]$name <- "United States of America"
}

## Bahamas / Bahamas, The
if(any(spar2022$country_clean == "Bahamas")){
  spar2022[which(spar2022$country_clean == "Bahamas"),]$country_clean <- "Bahamas, The"
}

## Bolivia (Plurinational State of)
if(any(spar2022$country_clean == "Bolivia (Plurinational State of)")){
  spar2022[which(spar2022$country_clean == "Bolivia (Plurinational State of)"),]$country_clean <- "Bolivia"
}

## Brunei Darussalam / Brunei
if(any(spar2022$country_clean == "Brunei Darussalam")){
  spar2022[which(spar2022$country_clean == "Brunei Darussalam"),]$country_clean <- "Brunei"
}

## Czech Republic / Czechia
if(any(spar2022$country_clean == "Czech Republic")){
  spar2022[which(spar2022$country_clean == "Czech Republic"),]$country_clean <- "Czechia"
}

## Congo/Congo, Republic of the
if(any(spar2022$country_clean == "Congo")){
  spar2022[which(spar2022$country_clean == "Congo"),]$country_clean <- "Congo, Republic of the"
}

## Democratic Republic of the Congo / Congo, Democratic Republic of the
if(any(spar2022$country_clean == "Democratic Republic of the Congo")){
  spar2022[which(spar2022$country_clean == "Democratic Republic of the Congo"),]$country_clean <- "Congo, Democratic Republic of the"
}

## Holy See/ Holy See (Vatican City)
if(any(spar2022$country_clean == "Holy See")){
  spar2022[which(spar2022$country_clean == "Holy See"),]$country_clean <- "Holy See (Vatican City)"
}

##  Iran / Iran (Islamic Republic of)
if(any(spar2022$country_clean == "Iran (Islamic Republic of)")){
  spar2022[which(spar2022$country_clean == "Iran (Islamic Republic of)"),]$country_clean <- "Iran"
}

## Lao People's Democratic Republic / Laos
if(any(spar2022$country_clean == "Lao People's Democratic Republic")){
  spar2022[which(spar2022$country_clean == "Lao People's Democratic Republic"),]$country_clean <- "Laos"
}

## Moldova / Republic of Moldova
if(any(spar2022$country_clean == "Republic of Moldova")){
  spar2022[which(spar2022$country_clean == "Republic of Moldova"),]$country_clean <- "Moldova"
}
## Netherlands / Netherlands (Kingdom of the)
if(any(spar2022$country_clean == "Netherlands (Kingdom of the)")){
  spar2022[which(spar2022$country_clean == "Netherlands (Kingdom of the)"),]$country_clean <- "Netherlands"
}

## Tanzania / United Republic of Tanzania
if(any(spar2022$country_clean == "United Republic of Tanzania")){
  spar2022[which(spar2022$country_clean == "United Republic of Tanzania"),]$country_clean <- "Tanzania"
}

## Russian Federation / Russia
if(any(spar2022$country_clean == "Russian Federation")){
  spar2022[which(spar2022$country_clean == "Russian Federation"),]$country_clean <- "Russia"
}

## Micronesia / Micronesia, Federated States of
if(any(spar2022$country_clean == "Micronesia")){
  spar2022[which(spar2022$country_clean == "Micronesia"),]$country_clean <- "Micronesia, Federated States of"
}

##  North Korea / Democratic People's Republic of Korea 
if(any(spar2022$country_clean == "Democratic People's Republic of Korea")){
  spar2022[which(spar2022$country_clean == "Democratic People's Republic of Korea"),]$country_clean <- "North Korea"
}

## South Korea / Republic of Korea
if(any(spar2022$country_clean == "Republic of Korea")){
  spar2022[which(spar2022$country_clean == "Republic of Korea"),]$country_clean <- "South Korea"
}

## Syrian Arab Republic / Syria
if(any(spar2022$country_clean == "Syrian Arab Republic")){
  spar2022[which(spar2022$country_clean == "Syrian Arab Republic"),]$country_clean <- "Syria"
}

## United Kingdom of Great Britain and Northern Ireland / United Kingdom of Great Britain and Northern Ireland
if(any(spar2022$country_clean == "United Kingdom of Great Britain and Northern Ireland")){
  spar2022[which(spar2022$country_clean == "United Kingdom of Great Britain and Northern Ireland"),]$country_clean <- "United Kingdom"
}

## Venezuela (Bolivarian Republic of) / Venezuela
if(any(spar2022$country_clean == "Venezuela (Bolivarian Republic of)")){
  spar2022[which(spar2022$country_clean == "Venezuela (Bolivarian Republic of)"),]$country_clean <- "Venezuela"
}

## Viet Nam / Vietnam
if(any(spar2022$country_clean == "Viet Nam")){
  spar2022[which(spar2022$country_clean == "Viet Nam"),]$country_clean <- "Vietnam"
}

#############################################
## Merge data together ######################
#############################################

country_dataset <- sqldf(
"
/* identify most recent hospital data */
with recent_hospital_count as (
select 
  h.COU,
  h.Year,
  Value
from hospitals as h
join (
  select 
    COU,
    max(Year) as latest_year
  from hospitals
  where 
    Variable = 'General hospitals'
    and Measure = 'Number'
  group by 
    COU
) as r
on h.COU = r.COU
and h.Year = r.latest_year
and h.Variable = 'General hospitals'
and h.Measure = 'Number'
),

/* identify the most recent utilization data */
recent_utilization as (
select 
  u.LOCATION,
  u.TIME,
  u.Value
from utilization as u
join (
  select 
    LOCATION,
    max(TIME) as latest_year
  from utilization
  where 
    SUBJECT = 'TOT'
    and MEASURE = 'CAP'
  group by 
    LOCATION
) as r
on u.LOCATION = r.LOCATION
and u.TIME = r.latest_year
and u.SUBJECT = 'TOT'
and u.MEASURE = 'CAP'
)

select 
  b.name as name,
  b.iso_3166 as iso_3166,
  b.stanag_code as stanag_code,
  b.internet_code as internet_code,
  wm.who_member_state,
  wm.who_region,
  spar2022.total_average AS spar2022_total_average,
  b.intermediate_area_name as intermediate_area_name,
  b.intermediate_area_count as intermediate_area_count,
  b.intermediate_area_reference as intermediate_area_reference,
  b.cia_factbook_note as cia_factbook_note,
  h.Value as general_hospital_count,
  ('OECD Health Care Resources: Hospitals Dataset (' || Year || ')') as general_hospital_reference,
  u.Value as doctor_consultations_per_capita,
  ('OECD Health Care Utilization: Doctors consultations Dataset (' || TIME || ')') as doctors_consultation_reference,
  md.FactValueNumeric as mds_per_10000capita,
  ('WHO Global Health Workforce statistics database (' || md.Period || ')') as mds_per_10000capita_reference,
  nm.FactValueNumeric as nurses_midwives_per_10000capita,
  ('WHO Global Health Workforce statistics database (' || nm.Period || ')') as nurses_midwives_per_10000capita_reference,
  NULL as data_team_notes
from base as b
left join recent_hospital_count as h
  on b.iso_3166 = h.COU
  and b.iso_3166 != ''
left join recent_utilization as u
  on b.iso_3166 = u.LOCATION
left join md 
  on b.iso_3166 = md.SpatialDimValueCode
  and md.IsLatestYear = TRUE
  and md.indicator = 'Medical doctors (per 10,000)'
left join nurse_midwife as nm
  on b.iso_3166 = nm.SpatialDimValueCode
  and nm.IsLatestYear = 'true'
  and nm.indicator = 'Nursing and midwifery personnel (per 10,000)'
left join who_membership as wm
  on b.iso_3166 = wm.iso_3166
  and b.iso_3166 != ''
left join naphs_dates as nd 
  on b.name = nd.Country
  and nd.Country != 'Tanzania (Zanzibar)' /* excluded */
left join spar2022 
  on b.name = spar2022.country_clean
")

#############################################
## Disambiguate Myanmar/Burma ###############
#############################################

## CIA World Factbook lists both, moving forward standardize as Myanmar based on ISO guidelines
country_dataset[which(country_dataset$name == "Myanmar"), -which(names(country_dataset) == "name")]  <- country_dataset[which(country_dataset$name == "Burma"), -which(names(country_dataset) == "name")]
country_dataset[which(country_dataset$name == "Myanmar"),]$data_team_notes <- "'Burma' also noted in CIA World Factbook"

if(any(country_dataset$name == "Burma")){
  country_dataset <- country_dataset[-which(country_dataset$name == "Burma"),]
}

#############################################
## Q/A ######################################
#############################################

sum(country_dataset$who_member_state, na.rm = TRUE)

country_dataset[which(is.na(country_dataset$who_member_state)),]$name
country_dataset[which(country_dataset$who_member_state == "FALSE"),]$name

## TODO: add check for duplicates

#############################################
## Export data ##############################
#############################################

write_delim(country_dataset[which(country_dataset$who_member_state == TRUE),],
            delim = "\t",
            file = "data/countries.tsv", 
            na = "NA")

