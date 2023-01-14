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
library(googlesheets4) ## read data from google sheets: https://googlesheets4.tidyverse.org/
library(dplyr) ## reshape, reformat, recode data: https://dplyr.tidyverse.org/reference/recode.html
library(ggplot2) ## for plotting: https://ggplot2.tidyverse.org/
library(scales) ## for commas on axes of plots
library(sqldf) ## for writing SQL in r

#############################################
## Read in data #############################
#############################################

## base data from CIA world factbook
base <- read.delim("data/generate-country-data/inputs/cia_factbook/countries.tsv", header = TRUE)

hospitals <- read.delim("data/generate-country-data/inputs/oecd/country_hospitals.tsv", header = TRUE)

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
  b.intermediate_area_name as intermediate_area_name,
  b.intermediate_area_count as intermediate_area_count,
  b.intermediate_area_reference as intermediate_area_reference,
  b.cia_factbook_note as cia_factbook_note,
  h.Value as general_hospital_count,
  ('OECD Health Care Resources: Hospitals Dataset (' || Year || ')') as general_hospital_reference
from base as b
left join recent_hospital_count as h
  on b.iso_3166 = h.COU
")
