#############################################
## Background ###############################
#############################################

## This script contains checks used to perform data Q/A during the data 
## collection, management, and curation process

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

#############################################
## Read in data #############################
#############################################

## TODO: data dictionary for all data
## TODO: currently reading in private google sheets, when finalized save as flat file and move to data/
## TODO: cost PPE

## item cost data
line_items <- read_sheet("https://docs.google.com/spreadsheets/d/1ZLGXzf1Dw77NiTV2bjrolKID-46PQEMR8HCCty_5OK8/edit#gid=0",
                        sheet = 1) ## read in first tab

## info on the JEE at the score/attribute level
jee <- read_sheet("https://docs.google.com/spreadsheets/d/1AgSqLn0DL7utGPZ83kgjWl3OeFp0ctjL5BLY0FZufGY/edit#gid=0",
                  sheet = 1)

## info on unit costs
unit_costs <- read_sheet("https://docs.google.com/spreadsheets/d/1rQUjW09QO-wXXbSMPL9xl7aYRJCPIvGkqz1R3RhyegE/edit#gid=0",
                         sheet = 1)

#############################################
## Clean/reformat data ######################
#############################################

## TODO: remove initials from line_items table (two fields)
## TODO: remove remaining items from the JEE table (one field)
## TODO: remove extra items from the unit costs table (two fields)

## make field names in line_item object more nicely machine readable
## standard: snake case ## https://en.wikipedia.org/wiki/Snake_case
names(line_items) <- recode(names(line_items),
       "ID" = "id",
       "Initials (input)" = "initials_input",
       "Initials (Q/A)" = "initials_qa",
       "Indicator" = "indicator",
       "Score" = "score",
       "Attribute" = "attribute",
       "Requirement" = "requirement",
       "Activity" = "activity",
       "Unit cost name" = "unit_cost_name",
       "Cost unit" = "cost_unit",
       "Description" = "description",
       "Administrative level" = "administrative_level",
       "Cost type" = "cost_type",
       "Custom multiplier 1" = "custom_multiplier_1",
       "Custom multiplier 1 unit" = "custom_multiplier_1_unit",
       "Custom multiplier 2" = "custom_multiplier_2",
       "Custom multiplier 2 unit" = "custom_multiplier_2_unit",
       "Relevant references" = "references",
       "Optional cost?" = "optional_cost",
       "Notes and additional assumptions" = "notes")

names(jee) <- recode(names(jee),
                     "Pillar" = "pillar",
                     "Capacity" = "capacity",
                     "Indicator" = "indicator",
                     "Score" = "score",
                     "Attribute" = "attribute")

names(unit_costs) <- recode(names(unit_costs),
                            "Cost name" = "cost_name",
                            "Description" = "description",
                            "Category (Sloan et al)" = "category_sloan",
                            "Default cost value (USD 2022)" = "value",
                            "Cost unit" = "unit",
                            "Assumptions" = "assumptions",
                            "URL" = "url")

#############################################
## Field: ID ################################
#############################################

## TODO: generate unique ID field

## Are all IDs unique?
# stopifnot(
#   "Not all IDs are unique" =
#   nrow(line_items) == length(unique(line_items$id))
#   )

#############################################
## Field: Indicator #########################
#############################################

## Do all rows in line_items have an indicator?
stopifnot(
  "Not all lines have a specified indicator" = 
  all(complete.cases(line_items$indicator))
  )

## do all indicators of the JEE have at least one row in line_items? (except scores of 1 and 5)?
stopifnot(
  "Missing JEE indicators" = 
    all(jee$indicator %in% line_items$indicator)
)

#############################################
## Field: Score #############################
#############################################

## are all scores between 1 and 4 (inclusive)?
stopifnot(
  "Score less than 1 or greater than 4" = 
  all(line_items$score > 1 & line_items$score < 5)
)

#############################################
## Field: Attribute #########################
#############################################

## do all attributes of the JEE have at least one row in line_items? (except scores of 1 and 5)?
stopifnot(
  "Missing JEE attributes" = 
  all(jee$attribute[which(jee$score > 1 & jee$score < 5)] %in% line_items$attribute)
)

#############################################
## Field: Requirement #######################
#############################################

## do all line-items have a complete (non-NULL) requirement specified?
stopifnot(
  "Missing requirement info" = 
  all(complete.cases(line_items$requirement))
)

#############################################
## Field: Activity ##########################
#############################################

## do all line-items have a complete (non-NULL) activity specified?
stopifnot(
  "Missing activity info" = 
    all(complete.cases(line_items$activity))
)

#############################################
## Field: Unit cost #########################
#############################################

## TODO: currently one XX/unknown unit cost, ensure that gets fixed

## do all unit costs have corresponding cost data in the unit_costs table?
stopifnot(
  "Inconsistent unit cost data" = 
    all(line_items$unit_cost_name %in% unit_costs$cost_name)
  )

## if you see error, look here to find specific unit costs that may be missing from the unit cost table
#table(line_items[-which(line_items$unit_cost_name %in% unit_costs$cost_name),]$unit_cost_name)

#############################################
## Field: Description #######################
#############################################

## TODO: currently 2 missing, confirm that they get fixed

## do all line-items have a complete (non-NULL) description specified?
stopifnot(
  "Missing description info" = 
    all(complete.cases(line_items$description))
)

#############################################
## Field: Administrative level ##############
#############################################

## TODO: currently 2 missing, confirm that they get fixed

## do all line-items have an allowable administrative level specified?
stopifnot(
  "Non-allowable administrative level" = 
    all(line_items$administrative_level %in% c("Health facility", "Population", "Local", "Intermediate", "National"))
)

#############################################
## Field: Optional cost #####################
#############################################

## do all line-items have optional cost (TRUE or FALSE) specified?
stopifnot(
  "Select line item not indicated as an optional cost or not" = 
    all(line_items$optional_cost %in% c("TRUE", "FALSE"))
)

#############################################
## Explore most expensive unit costs ########
## Does this pass the sniff test? ###########
#############################################

unit_costs %>%
  arrange(desc(value)) %>%
  top_n(30) %>%
  ggplot(aes(x = value, 
             y = factor(cost_name, levels = rev(cost_name)),
             fill = category_sloan)) + ## factor coercion keeps order specified in arrange, since I want the barplot sorted
  geom_bar(stat = "identity", color = "black") +
  xlab("Default Cost (2022 USD)") +
  ylab("") +
  scale_x_continuous(label = comma) +
  labs(caption = "", fill = "Cost category") +
  theme_minimal() + 
  theme(plot.caption = element_text(size = 7), legend.position = "bottom") +
  scale_fill_manual(values = c("#172869", "#088BBE", "#1BB6AF")) 
  # scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
  #               labels = trans_format("log10", math_format(10^.x))) 


