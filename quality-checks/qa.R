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
library(dplyr) ## reshape, reformat, recode data: https://dplyr.tidyverse.org/reference/recode.html
library(ggplot2) ## for plotting: https://ggplot2.tidyverse.org/
library(scales) ## for commas on axes of plots

#############################################
## Read in data #############################
#############################################

## item cost data
line_items <- read.delim("data/line_items.tsv", header = TRUE)

## info on metrics (including JEE) at the score/attribute level
metrics <- read.delim("data/metrics.tsv",  header = TRUE)

## info on unit costs
unit_costs <- read.delim("data/unit_costs.tsv", header = TRUE)
unit_costs_grouped <- read.delim("data/detailed_costing.tsv", header = TRUE)

## read in info on countries
countries <- read.table("data/countries.tsv", sep = "\t", header = TRUE)

#############################################
## Format data ##############################
#############################################

## treat multipliers as numeric features
line_items$custom_multiplier_1 <- as.numeric(as.character(line_items$custom_multiplier_1))
line_items$custom_multiplier_2 <- as.numeric(as.character(line_items$custom_multiplier_2))

## if no multiplier is specified, don't multiply by anything (equivalently, multiply by one)
line_items$custom_multiplier_1[which(is.na(line_items$custom_multiplier_1))] <- 1
line_items$custom_multiplier_2[which(is.na(line_items$custom_multiplier_2))] <- 1

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
    all(metrics$indicator[which(metrics$metric == "JEE (3.0)")] %in% line_items$indicator)
)

## are all metrics that are intended included in the metrics spreadsheet?
stopifnot(
  "Missing metric data for JEE 1.0" = 
  "JEE (1.0)" %in% unique(metrics$metric)
)

stopifnot(
  "Missing metric data for JEE 3.0" = 
    "JEE (3.0)" %in% unique(metrics$metric)
)

stopifnot(
  "Missing metric data for SPAR 2.0" = 
    "SPAR (2.0)" %in% unique(metrics$metric)
)

stopifnot(
  "Missing metric data for Health Emergency Preparedness, Response and Resilience (HEPR)" = 
    "Health Emergency Preparedness, Response and Resilience (HEPR)" %in% unique(metrics$metric)
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
## Field: Metrics #########################
#############################################

## do all metrics/asstributes of the JEE have at least one row in line_items? (except scores of 1 and 5)?
stopifnot(
  "Missing JEE attributes" = 
  all(metrics$metrics[which(metrics$score > 1 & metrics$score < 5 & metrics$metric == "JEE (3.0)")] %in% line_items$metrics)
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

## do all unit costs have corresponding cost data in the unit_costs table?
stopifnot(
  "Inconsistent unit cost data" = 
    all(line_items$unit_cost_name %in% unit_costs$cost_name)
  )

#############################################
## Field: Description #######################
#############################################

## do all line-items have a complete (non-NULL) description specified?
stopifnot(
  "Missing description info" = 
    all(complete.cases(line_items$description))
)

#############################################
## Field: Administrative level ##############
#############################################

## do all line-items have an allowable administrative level specified?
stopifnot(
  "Non-allowable administrative level" = 
    all(line_items$administrative_level %in% c("Health facility", "Population", "Local", "Intermediate", "National", "Additional HWC/per 1000 population", "PoE"))
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
  arrange(desc(default_value)) %>%
  top_n(30) %>%
  ggplot(aes(x = default_value, 
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

## don't use these data to look year over year
## assumes no capacity at baseline
## everything one-time costed in year 1 (that's not how it would happen, actually)
## then all recurring costs costed each year after that
## lets us look across all items but not intended to be analyzed over time
a <- line_items %>%
  left_join(unit_costs, by = "unit_cost") %>%
  left_join(metrics %>% 
              filter(metrics$metric == "JEE (3.0)") %>% 
              select(c(metric_id, metric, pillar)), by = "metric_id") %>%
  bind_cols(countries %>% filter(name == "United States")) %>%
  mutate(administrative_level_multiplier = 
        as.numeric(as.character(
             ifelse(administrative_level == "National", 1,
             ifelse(administrative_level == "Intermediate", intermediate_area_count,
             ## The United States total includes 3,006 counties; 14 boroughs and 11 census areas in Alaska; the District of Columbia; 64 parishes in Louisiana; Baltimore city, Maryland; St. Louis city, Missouri; that part of Yellowstone National Park in Montana; Carson City, Nevada; and 41 independent cities in Virginia.
             ifelse(administrative_level == "Local", (3006 + 14 + 11  + 1 + 64 + 4 + 1 + 41), ## https://www2.census.gov/geo/pdfs/reference/GARM/Ch4GARM.pdf (exclude yellowstone)    
             ## Look at community hospitals, https://www.aha.org/statistics/fast-facts-us-hospitals, assume 50% of hospitals participate in IHR related activities
             ifelse(administrative_level == "Health facility", 5139/.5, 
             ifelse(administrative_level == "Additional HWC/per 1000 population", 0, 
             ifelse(administrative_level == "PoE", 5, ## todo pick number
             ifelse(administrative_level == "Population", 333287557,  ## https://www.census.gov/newsroom/press-releases/2022/2022-population-estimates.html
             "error"))))))))) %>%
  mutate(y1cost = default_value*custom_multiplier_1*custom_multiplier_2*administrative_level_multiplier) %>%
  mutate(y2cost = ifelse(cost_type == "One-time", 0, default_value*custom_multiplier_1*custom_multiplier_2*administrative_level_multiplier)) %>%
  mutate(y3cost = ifelse(cost_type == "One-time", 0, default_value*custom_multiplier_1*custom_multiplier_2*administrative_level_multiplier)) %>%
  mutate(y4cost = ifelse(cost_type == "One-time", 0, default_value*custom_multiplier_1*custom_multiplier_2*administrative_level_multiplier)) %>%
  mutate(y5cost = ifelse(cost_type == "One-time", 0, default_value*custom_multiplier_1*custom_multiplier_2*administrative_level_multiplier)) %>%
  mutate(cost_5yrs = y1cost + y2cost + y3cost + y4cost + y5cost) 
                       
a %>% 
  treemap(index = c("pillar", "activity"),
          vSize = "cost_5yrs",
          fontsize.labels = 1,
          vColor = "pillar")                    
           

#######################################################
## Appendix: Calculate grouped unit costs #############
#######################################################

unit_costs_grouped %>%
  group_by(cost_name, category_sloan) %>%
  summarize(total = sum(value))
