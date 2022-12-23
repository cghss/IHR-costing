#############################################
## Background ###############################
#############################################

## This script contains checks used to perform data Q/A during the data 
## collection, management, and curation process

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

#############################################
## Read in data #############################
#############################################

## TODO: currently reading in private google sheets, when finalized save as flat file and move to data/
## TODO: check/confirm WASH costs

## item cost data
line_items <- read_sheet("https://docs.google.com/spreadsheets/d/1ZLGXzf1Dw77NiTV2bjrolKID-46PQEMR8HCCty_5OK8/edit#gid=0",
                        sheet = 1) ## read in first tab

## info on the JEE at the score/attribute level
jee <- read.table("data/jee3.tsv", sep = "\t", header = TRUE)

## info on unit costs
unit_costs <- read_sheet("https://docs.google.com/spreadsheets/d/1rQUjW09QO-wXXbSMPL9xl7aYRJCPIvGkqz1R3RhyegE/edit#gid=0",
                         sheet = 1)

unit_costs_grouped <- read_sheet("https://docs.google.com/spreadsheets/d/1rQUjW09QO-wXXbSMPL9xl7aYRJCPIvGkqz1R3RhyegE/edit#gid=0",
                         sheet = 2)

## read in info on countries
countries <- read.table("data/countries.tsv", sep = "\t", header = TRUE)

#############################################
## Clean/reformat data ######################
#############################################

## TODO: remove initials from line_items table (two fields)
## TODO: remove remaining items from the JEE table (one field)
## TODO: remove extra items from the unit costs table (two fields)
## TODO: update data dictionary 

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
       "Unit cost" = "unit_cost",
       "Unit" = "unit",
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

names(unit_costs) <- recode(names(unit_costs),
                            "Unit cost" = "unit_cost",
                            "Description" = "description",
                            "Category (Sloan et al)" = "category_sloan",
                            "Default value (2022 USD)" = "value",
                            "Cost unit" = "unit",
                            "Assumptions" = "assumptions",
                            "URL" = "url")

names(unit_costs_grouped) <- recode(names(unit_costs_grouped),
                            "Cost name" = "cost_name",
                            "Cost subcategory (if any)" = "cost_subcategory",
                            "Item" = "item",
                            "Unit" = "unit",
                            "Unit cost" = "unit cost",
                            "Default value (2022 USD)" = "value",
                            "Reference (example costed item)" = "reference",
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
             y = factor(unit_cost, levels = rev(unit_cost)),
             fill = category_sloan)) + ## factor coercion keeps order specified in arrange, since I want the barplot sorted
  geom_bar(stat = "identity", color = "black") +
  xlab("Default Cost (2022 USD)") +
  ylab("") +
  labs(caption = "", fill = "Cost category") +
  theme_minimal() + 
  theme(plot.caption = element_text(size = 7), legend.position = "bottom") +
  scale_fill_manual(values = c("#172869", "#088BBE", "#1BB6AF")) +
  scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                labels = trans_format("log10", math_format(10^.x))) +
  ggtitle("Most expensive unit costs")

#############################################
## Explore which unit costs are used ########
## the most times in line_item costs ########
#############################################

line_items %>%
  left_join(unit_costs, by = "unit_cost") %>%
  group_by(category_sloan, unit_cost) %>%
  filter(complete.cases(category_sloan)) %>%
  summarize(n = n()) %>%
  arrange(desc(n)) %>%
  top_n(30) %>%
  ungroup() %>%
  ggplot(aes(x = n, 
             y = factor(unit_cost, levels = rev(unit_cost)),
             fill = category_sloan)) + ## factor coercion keeps order specified in arrange, since I want the barplot sorted
  geom_bar(stat = "identity", color = "black") +
  xlab("Number of times unit is costed in line-items") +
  ylab("") +
  scale_x_continuous(label = comma) +
  scale_fill_manual(values = c("#172869", "#088BBE", "#1BB6AF")) +
  labs(caption = "", fill = "Cost category") +
  theme_minimal() + 
  theme(plot.caption = element_text(size = 7), legend.position = "bottom") +
  ggtitle("Most frequently used line-item costs")

#############################################
## Explore costs for all items/attributes ###
## for a selected country ###################
#############################################

a <- line_items %>%
  left_join(unit_costs, by = "unit_cost") %>%
  bind_cols(countries %>% filter(name == "United States")) %>%
  mutate(administrative_level_multiplier = 
         ifelse(administrative_level == "National", 1,
         ifelse(administrative_level == "Intermediate", intermediate_area_count,
    "error")))

                                                  
           
 # mutate(y1cost = value*custom_multiplier_1*custom_multiplier_2*)

#######################################################
## Appendix: Calculate grouped unit costs #############
#######################################################

unit_costs_grouped %>%
  group_by(cost_name, category_sloan) %>%
  summarize(total = sum(value))
