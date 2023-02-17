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

#############################################
## Read in data #############################
#############################################

## base data from CIA world factbook
base <- read.delim("data/generate-country-data/inputs/cia_factbook/countries_fb.tsv", header = TRUE)

## hospital data from OECD
hospitals <- read.delim("data/generate-country-data/inputs/oecd/country_hospitals.tsv", header = TRUE)

## WHO membership data from WHO
who_membership <- read.delim("data/generate-country-data/inputs/who/who_member_states.tsv", header = TRUE)

## NAPHS dates and data reporting from WHO
naphs_dates <- read.delim("data/generate-country-data/inputs/who/naphs_dates.tsv", header = TRUE)

#############################################
## Process individual datasets ##############
#############################################

if(any(base$name == "United States")){
  base[which(base$name == "United States"),]$name <- "United States of America"
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
)

select 
  b.name as name,
  b.iso_3166 as iso_3166,
  b.stanag_code as stanag_code,
  b.internet_code as internet_code,
  wm.who_member_state,
  wm.who_region,
  b.intermediate_area_name as intermediate_area_name,
  b.intermediate_area_count as intermediate_area_count,
  b.intermediate_area_reference as intermediate_area_reference,
  b.cia_factbook_note as cia_factbook_note,
  h.Value as general_hospital_count,
  ('OECD Health Care Resources: Hospitals Dataset (' || Year || ')') as general_hospital_reference,
  NULL as data_team_notes
from base as b
left join recent_hospital_count as h
  on b.iso_3166 = h.COU
  and b.iso_3166 != ''
left join who_membership as wm
  on b.iso_3166 = wm.iso_3166
  and b.iso_3166 != ''
left join naphs_dates as nd 
  on b.name = nd.Country
  and nd.Country != 'Tanzania (Zanzibar)' /* excluded */
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

#############################################
## Export data ##############################
#############################################

write_delim(country_dataset[which(country_dataset$who_member_state == TRUE),],
            delim = "\t",
            file = "data/countries.tsv", 
            na = "NA")

