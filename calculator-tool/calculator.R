
## NOTE: THIS SCRIPT IS A WORK-IN-PROGRESS AND IS NOT READY FOR FINAL USE

#############################################
## Background ###############################
#############################################

## IHR-costing:
## The IHR Costing Tool helps users generate and review cost estimates to support practical planning for 
## sustainable capacity development to prevent, detect, and respond to public health threats, as defined 
## by the International Health Regulations (IHR).

## Calculator Tool
## This script is still in progress, but will eventually include a simple R script that allows users to:
##  - read in data from the data/ directory
##  - specify a set of user inputs and assumptions
##  - estimate yearly costs and generate simple visual graphics and outputs

## This calculator is designed to help calculate costs for one country at a time,

## Code assumes that the working directory is set to IHR-costing

#############################################
## Setup ####################################
#############################################

## Load libraries
## If you don't already have these installed, you will first need to install them by using 
## the command: install.packages(), for example:
## install.packages("dplyr")

library(dplyr) ## reshape, reformat, recode data: https://dplyr.tidyverse.org/reference/recode.html
library(ggplot2) ## for plotting: https://ggplot2.tidyverse.org/
library(scales) ## for commas on axes of plots
library(treemap) ## for treemap visual
library(openxlsx) ## to read in Excel files

#############################################
## Read in data #############################
#############################################

## Read in data from the costing worksheet, one sheet at a time

line_items <- read.xlsx("calculator-tool/jee3_costing_worksheet.xlsx",
                        sheet = "Line items (JEE 3)")

unit_costs <- read.xlsx("calculator-tool/jee3_costing_worksheet.xlsx",
                        sheet = "Unit costs")

multipliers <- read.xlsx("calculator-tool/jee3_costing_worksheet.xlsx",
                         sheet = "Multipliers")

country_scores <- read.xlsx("calculator-tool/jee3_costing_worksheet.xlsx",
                         sheet = "Country scores")

#############################################
## Format data ##############################
#############################################

## todo: remove or comment this piece out in the final calculator tool
## for the purpose of testing, set the value of "value" to the value of "example_value" in the multipliers table
multipliers$value <- multipliers$example_value

## treat multipliers as numeric features
line_items$custom_multiplier_1 <- as.numeric(as.character(line_items$custom_multiplier_1))
line_items$custom_multiplier_2 <- as.numeric(as.character(line_items$custom_multiplier_2))

## if no multiplier is specified, don't multiply by anything (equivalently, multiply by one)
line_items$custom_multiplier_1[which(is.na(line_items$custom_multiplier_1))] <- 1
line_items$custom_multiplier_2[which(is.na(line_items$custom_multiplier_2))] <- 1

## format all default unit costs and all numeric scores as numeric variables
unit_costs$default_value <- as.numeric(as.character(unit_costs$default_value))
line_items$score_numeric <- as.numeric(as.character(line_items$score_numeric))

#######################################################
## Calculate costs per line-item ######################
#######################################################

line_item_costs <- line_items %>%
  ## add info on unit costs, left join so we don't accidentally lose any line items
  left_join(unit_costs[,which(names(unit_costs) %in% c("category_sloan", "category", "subcategory", "unit_cost", "unit", "default_value"))], by = "unit_cost") %>%
  ## add info on country scores
  left_join(country_scores[,which(names(country_scores) %in% c("metric_id", "country_score_numeric"))], by = "metric_id") %>%
  ## add info on multipliers specified at the country level as a new field called "multiplier unit"
   mutate(administrative_multiplier_unit = 
        as.numeric(as.character(
             ifelse(administrative_level == "National", 1,
             ifelse(administrative_level == "Intermediate", multipliers[which(multipliers$observation == "Intermediate area count"),]$value,
             ifelse(administrative_level == "Local", multipliers[which(multipliers$observation == "Local area count"),]$value,
             ifelse(administrative_level == "Health facility", multipliers[which(multipliers$observation == "Health facility count"),]$value,
             ifelse(administrative_level == "PoE", multipliers[which(multipliers$observation == "Points of Entry Count"),]$value,
             ifelse(administrative_level == "Population", multipliers[which(multipliers$observation == "Population"),]$value,
             ifelse(administrative_level == "Additional healthcare workers (doctors, nurses, and midwives)",  multipliers[which(multipliers$observation == "Additional doctors, nurses, and midwives"),]$value,
                    "error")))))))))) %>%
  ## just look at rows where the country's current score is lower than the item being costed (e.g., we don't assume they've already done it)
  filter(country_score_numeric < score_numeric) %>%
  ## mark which costs are included in year 1, 2, 3, 4, and 5
  ## just look at rows marked as include == TRUE (the ones we actually want to cost, specified in the worksheet)
  mutate(costed_y1 = include == TRUE & (score_numeric - country_score_numeric) == 1 ) %>% ## all items that are one score up from the current score get costed in year 1
  mutate(costed_y2 = include == TRUE & (score_numeric - country_score_numeric == 1 & cost_type  == "Recurring") | (score_numeric - country_score_numeric == 2)) %>% ## items will be costed in year 2 if they meeting one of two criteria: (1) they are from year 1, but recurring or (2) they occur at two levels up from the initial score, assuming progress of one point up per year 
  mutate(costed_y3 = include == TRUE & (score_numeric - country_score_numeric <= 2 & cost_type  == "Recurring") | (score_numeric - country_score_numeric == 3)) %>% ## items will be costed in year 3 if they meeting one of two criteria: (1) they are from years 1 or 2, but recurring or (2) they occur at three levels up from the initial score, assuming progress of one point up per year 
  mutate(costed_y4 = include == TRUE & (score_numeric - country_score_numeric <= 3 & cost_type  == "Recurring") | (score_numeric - country_score_numeric == 4)) %>% ## items will be costed in year 4 if they meeting one of two criteria: (1) they are from years 1-3, but recurring or (2) they occur at four levels up from the initial score, assuming progress of one point up per year 
  mutate(costed_y5 = include == TRUE & (score_numeric - country_score_numeric <= 4 & cost_type  == "Recurring") | (score_numeric - country_score_numeric == 5)) %>% ## items will be costed in year 5 if they meeting one of two criteria: (1) they are from years 1-4, but recurring or (2) they occur at five levels up from the initial score, assuming progress of one point up per year (since we don't cost a five, this isn't currently possible)
  ## calculate yearly costs for a five year period
  mutate(y1cost = ifelse(costed_y1 == TRUE, default_value*custom_multiplier_1*custom_multiplier_2*administrative_multiplier_unit, 0)) %>%
  mutate(y2cost = ifelse(costed_y2 == TRUE, default_value*custom_multiplier_1*custom_multiplier_2*administrative_multiplier_unit, 0)) %>%
  mutate(y3cost = ifelse(costed_y3 == TRUE, default_value*custom_multiplier_1*custom_multiplier_2*administrative_multiplier_unit, 0)) %>%
  mutate(y4cost = ifelse(costed_y4 == TRUE, default_value*custom_multiplier_1*custom_multiplier_2*administrative_multiplier_unit, 0)) %>%
  mutate(y5cost = ifelse(costed_y5 == TRUE, default_value*custom_multiplier_1*custom_multiplier_2*administrative_multiplier_unit, 0)) %>%
  mutate(cost_5yrs = y1cost + y2cost + y3cost + y4cost + y5cost) %>%
  select(line_item_id, include, metric_score_id, pillar, capacity, indicator, score_numeric, score_text, attribute, requirement, action, description, unit_cost, administrative_level, y1cost, y2cost, y3cost, y4cost, y5cost, cost_5yrs, cost_type, default_value, custom_multiplier_1, custom_multiplier_2, administrative_multiplier_unit, relevant_references, optional_cost, notes_assumptions, category_sloan, category, subcategory)

##############################################################
## Calculate costs per indicator-score #######################
##############################################################

indicator_score_costs <-
  line_item_costs %>%
  group_by(metric_score_id, indicator, score_numeric, score_text) %>%
  dplyr::summarize(y1cost = sum(y1cost), 
                   y2cost = sum(y2cost),
                   y3cost = sum(y3cost),
                   y4cost = sum(y4cost),
                   y5cost = sum(y5cost),
                   cost_5yrs = sum(cost_5yrs),
                   .groups = "keep")

##############################################################
## Calculate costs per indicator #############################
##############################################################

indicator_costs <-
  indicator_score_costs %>%
  group_by(indicator) %>%
  dplyr::summarize(y1cost = sum(y1cost), 
                   y2cost = sum(y2cost),
                   y3cost = sum(y3cost),
                   y4cost = sum(y4cost),
                   y5cost = sum(y5cost),
                   cost_5yrs = sum(cost_5yrs),
                   .groups = "keep")

##############################################################
## Calculate costs per indicator-score #######################
##############################################################

cost_category_costs <-
  line_item_costs %>%
  group_by(category, subcategory) %>%
  dplyr::summarize(y1cost = sum(y1cost), 
                   y2cost = sum(y2cost),
                   y3cost = sum(y3cost),
                   y4cost = sum(y4cost),
                   y5cost = sum(y5cost),
                   cost_5yrs = sum(cost_5yrs),
                   .groups = "keep") %>%
  arrange(category, desc(cost_5yrs))
  
##############################################################
## Export data ###############################################
##############################################################

## list all tabs you want to export in the Excel document worksheet you're making
excel_sheets <- list("Costs per indicator" = indicator_costs,
                     "Costs per indicator and score" = indicator_score_costs,
                     "Costs per cost category" = cost_category_costs)

## export worksheet in Excel
write.xlsx(excel_sheets, file = "calculator-tool/example_jee3_costing_results.xlsx")

##############################################################
## Generate graphics #########################################
##############################################################

## treemap of costs by category
cost_category_costs %>%
  treemap(index = c("category", "subcategory"),
          vSize = "cost_5yrs",
          #fontsize.labels = 1,
          title = NA,
          vColor = "category") 

