#############################################
## Background ###############################
#############################################

## This script contains checks used to perform data Q/A during the data 
## collection, management, and curation process

## Code assumes that the working directory is set to IHR-costing

#############################################
## Setup ####################################
#############################################

## NOTE: if you don't already have these libraries installed, you can do so by running install.packages()
## example: install.packages("dplyr")

## Load libraries
library(dplyr) ## reshape, reformat, recode data: https://dplyr.tidyverse.org/reference/recode.html
library(ggplot2) ## for plotting: https://ggplot2.tidyverse.org/
library(scales) ## for commas on axes of plots
library(treemap) ## for treemap visual
library(openxlsx) ## to save Excel files

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

## format all default unit costs as numeric cariables
unit_costs$default_value <- as.numeric(as.character(unit_costs$default_value))

#######################################################
## Check for non-allowable characters #################
#######################################################

## run as a one-off function
# ## https://stackoverflow.com/questions/4993837/r-invalid-multibyte-string
# ## function shared on stackoverflow by R.N.
# find_offending_character <- function(x, maxStringLength=256){  
#   print(x)
#   for (c in 1:maxStringLength){
#     offendingChar <- substr(x,c,c)
#      print(offendingChar) #uncomment if you want the indiv characters printed
#     #the next character is the offending multibyte Character
#   }    
# }
# 
# errors(lapply(line_items$activity, find_offending_character))

##############################################################
## Field: Metric and Metric Score ID #########################
##############################################################

## do all indicators of the JEE have at least one row in line_items? (except scores of 1 and 5)?
stopifnot(
  "Missing JEE indicators" = 
    all(metrics$metric_score_id[which(metrics$framework == "JEE (3.0)" & metrics$score_numeric %in% c(2,3,4))] %in% line_items$jee3_metric_score_id)
)

## are all values of metric score ID unique?
stopifnot(
  "Duplicated metric score IDs" = 
    !any(duplicated(metrics$metric_score_id))
)

## troubleshoot if you see an error above
## ID all unique JEE metrics in metrics table, then see which aren't in the line items list of JEE metrics
#all_jee_metrics <- unique(metrics$metric_id[which(metrics$framework == "JEE (3.0)" & metrics$score_numeric %in% c(2,3,4))])
#all_jee_metrics[-which(all_jee_metrics %in% line_items$jee3_metric_id)]

## are all metrics that are intended included in the metrics spreadsheet?
stopifnot(
  "Missing metric data for JEE 1.0" = 
  "JEE (1.0)" %in% unique(metrics$framework)
)

stopifnot(
  "Missing metric data for JEE 3.0" = 
    "JEE (3.0)" %in% unique(metrics$framework)
)

stopifnot(
  "Missing metric data for SPAR 2.0" = 
    "SPAR (2.0)" %in% unique(metrics$framework)
)

stopifnot(
  "Missing metric data for Health Emergency Preparedness, Response and Resilience (HEPR)" = 
    "Health Emergency Preparedness, Response and Resilience (HEPR)" %in% unique(metrics$framework)
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
## Field: Action ############################
#############################################

## do all line-items have a complete (non-NULL) action specified?
stopifnot(
  "Missing action info" = 
    all(complete.cases(line_items$action))
)

#############################################
## Field: Line-item ID ######################
#############################################

## are all line-item ids unique?
stopifnot(
  "Duplicate line-item IDs" = 
    length(unique(line_items$line_item_id)) == length(line_items$line_item_id)
)

## troubleshoot if you see an error above
## find duplicate line item ids
#line_items[which(duplicated(line_items$line_item_id)),]$line_item_id

#############################################
## Field: Unit cost #########################
#############################################

## do all unit costs have corresponding cost data in the unit_costs table?
stopifnot(
  "Inconsistent unit cost data" = 
    all(line_items$unit_cost %in% unit_costs$unit_cost)
  )

## troubleshoot if you see an error above
## ID all unit costs used in the line items table
#all_unit_costs <- unique(line_items$unit_cost)
#all_unit_costs[-which(all_unit_costs %in% unit_costs$unit_cost)]

## do all unit costs have default values?
stopifnot(
  "Missing default unit cost data" = 
    all(complete.cases(unit_costs$default_value))
)

## troubleshoot if you see an error above
#unit_costs[which(is.na(unit_costs$default_value)),]$unit_cost

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
    all(line_items$administrative_level %in% c("Health facility", "Population", "Local", "Intermediate", "National", "Additional HWC/per 1000 population", "PoE", "Additional healthcare workers (doctors, nurses, and midwives)"))
)

## troubleshoot if error
#unique(line_items$administrative_level)

#############################################
## Field: Optional cost #####################
#############################################

## do all line-items have optional cost (TRUE or FALSE) specified?
stopifnot(
  "Select line item not indicated as an optional cost or not" = 
    all(line_items$optional_cost %in% c("TRUE", "FALSE"))
)

## troubleshoot if you see an error above
#unique(line_items$optional_cost)

#############################################
## Explore most expensive unit costs ########
## Does this pass the sniff test? ###########
#############################################

png("quality-checks/qa-figures/top_unit_costs.png", width = 8, height = 6, units = "in", res = 1200)
unit_costs %>%
  arrange(desc(default_value)) %>%
  top_n(30) %>%
  ggplot(aes(x = default_value, 
             y = factor(unit_cost, levels = rev(unit_cost)),
             fill = category_sloan)) + ## factor coercion keeps order specified in arrange, since I want the barplot sorted
  geom_bar(stat = "identity", color = "black") +
  xlab("Default Cost (2022 USD)\nlog scale") +
  ylab("") +
  labs(caption = "", fill = "Cost category") +
  theme_minimal() + 
  theme(plot.caption = element_text(size = 7), legend.position = "bottom") +
  scale_fill_manual(values = c("#172869", "#088BBE", "#1BB6AF")) +
  scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                labels = trans_format("log10", math_format(10^.x))) +
  ggtitle("Most expensive unit costs")
dev.off()

#############################################
## Explore which unit costs are used ########
## the most times in line_item costs ########
#############################################

png("quality-checks/qa-figures/most_frequent_unit_costs.png", width = 8, height = 6, units = "in", res = 1200)
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
dev.off()

#############################################
## Explore costs for all items/attributes ###
## for a selected country ###################
#############################################

## caveat: don't use these data to look year over year
## assumes no capacity at baseline, only looks at non-optional costs
## everything one-time costed in year 1 (that's not how it would happen, actually)
## then all recurring costs costed each year after that
## lets us look across all items but not intended to be analyzed over time

png("quality-checks/qa-figures/example_treemap.png", width = 8, height = 6, units = "in", res = 1200)
line_items %>%
  filter(complete.cases(jee3_metric_score_id) & jee3_metric_score_id != "NA") %>%
  filter(optional_cost == FALSE) %>%
  left_join(unit_costs, by = "unit_cost") %>%
  left_join((metrics %>% filter(metrics$framework == "JEE (3.0)") %>% select(c(metric_score_id, framework, pillar))),
            by = join_by(jee3_metric_score_id == metric_score_id)) %>%
  bind_cols(countries %>% filter(name == "United States of America")) %>%
  mutate(administrative_level_multiplier =
        as.numeric(as.character(
             ifelse(administrative_level == "National", 1,
             ifelse(administrative_level == "Intermediate", intermediate_area_count,
             ## The United States total includes 3,006 counties; 14 boroughs and 11 census areas in Alaska; the District of Columbia; 64 parishes in Louisiana; Baltimore city, Maryland; St. Louis city, Missouri; that part of Yellowstone National Park in Montana; Carson City, Nevada; and 41 independent cities in Virginia.
             ifelse(administrative_level == "Local", (3006 + 14 + 11  + 1 + 64 + 4 + 1 + 41), ## https://www2.census.gov/geo/pdfs/reference/GARM/Ch4GARM.pdf (exclude yellowstone)
             ## Look at community hospitals, https://www.aha.org/statistics/fast-facts-us-hospitals, assume 50% of hospitals participate in IHR related activities
             ifelse(administrative_level == "Health facility", 5139/.5,
             ifelse(administrative_level == "PoE", 33, ## Assume 10% of PoEs participate in full IHR-related activities: "CBP provides security and facilitation operations at 328 ports of entry throughout the country." https://www.cbp.gov/border-security/ports-entry
             ifelse(administrative_level == "Population", 333287557,  ## https://www.census.gov/newsroom/press-releases/2022/2022-population-estimates.html
             ifelse(administrative_level == "Additional healthcare workers (doctors, nurses, and midwives)", 0, # According to recent OECD data, the US has 26.1 MDs/10,000 capita + 156.9 nurse and midwives/10,000 capita. This corresponds to 183 HCW/10,000 capita or 18.3 HCW/1000 capita, which is greater than the threshold set of the JEE of 4.45 doctors, nurses, and midwives per 1000 capita. As a result, this value is set to zero.
                    "error")))))))))) %>%
  mutate(y1cost = default_value*custom_multiplier_1*custom_multiplier_2*administrative_level_multiplier) %>%
  mutate(y2cost = ifelse(cost_type == "One-time", 0, default_value*custom_multiplier_1*custom_multiplier_2*administrative_level_multiplier)) %>%
  mutate(y3cost = ifelse(cost_type == "One-time", 0, default_value*custom_multiplier_1*custom_multiplier_2*administrative_level_multiplier)) %>%
  mutate(y4cost = ifelse(cost_type == "One-time", 0, default_value*custom_multiplier_1*custom_multiplier_2*administrative_level_multiplier)) %>%
  mutate(y5cost = ifelse(cost_type == "One-time", 0, default_value*custom_multiplier_1*custom_multiplier_2*administrative_level_multiplier)) %>%
  mutate(cost_5yrs = y1cost + y2cost + y3cost + y4cost + y5cost) %>%
treemap(index = c("pillar", "action"),
          vSize = "cost_5yrs",
          #fontsize.labels = 1,
          title = NA,
          vColor = "pillar")
dev.off()

#############################################
## Generate simple worksheet for costing ####
## Exercise per country, based on JEE3 ######
#############################################

## create data structure where users can enter info about the multipliers they'd like to use

## Rationale for examples included below for reference, however, users should modify to reflect their own
## assumptions based on the best-available local knowledge
## local_area_count: The United States total includes 3,006 counties; 14 boroughs and 11 census areas in Alaska; the District of Columbia; 64 parishes in Louisiana; Baltimore city, Maryland; St. Louis city, Missouri; that part of Yellowstone National Park in Montana; Carson City, Nevada; and 41 independent cities in Virginia.
## health_facility_count: Look at community hospitals, https://www.aha.org/statistics/fast-facts-us-hospitals, assume 50% of hospitals participate in IHR related activities
## points_of_entry_count: 5
## additional_doctors_nurses_midwives: According to recent OECD data, the US has 26.1 MDs/10,000 capita + 156.9 nurse and midwives/10,000 capita. This corresponds to 183 HCW/10,000 capita or 18.3 HCW/1000 capita, which is greater than the threshold set of the JEE of 4.45 doctors, nurses, and midwives per 1000 capita. As a result, this value is set to zero.
## population: https://www.census.gov/newsroom/press-releases/2022/2022-population-estimates.html

multipliers <- rbind.data.frame(
  cbind.data.frame(category = "General information",
                   observation = "Country name", 
                   definition = "The name of the country or geographic area for which costing is being completed",
                   example_value = "United States of America", 
                   value = NA,
                   note = "(optional) space for you to note any assumptions or references"),
  cbind.data.frame(category = "General information",
                   observation = "Population",
                   definition = "The size of the population (this must be a number)",
                   example_value = 333287557,
                   value = NA,
                   note = "(optional) space for you to note any assumptions or references"),
  cbind.data.frame(category = "Administrative areas and organization",
                   observation = "Intermediate area count",
                   definition = "The number of intermediate areas in the country (this must be a number)", 
                   example_value = 51,
                   value = NA,
                   note = "(optional) space for you to note any assumptions or references"),
  cbind.data.frame(category = "Administrative areas and organization",
                   observation = "Local area count",
                   definition = "The number of local areas in the country (this must be a number)",
                   example_value = 3143,
                   value = NA,
                   note = "(optional) space for you to note any assumptions or references"),
  cbind.data.frame(category = "Administrative areas and organization",
                   observation = "Health facility count",
                   definition = "The number of health facilities (likely hospitals and government-run health centers) participating in IHR-related activities (this must be a number)", 
                   example_value = 3142,
                   value = NA,
                   note = "(optional) space for you to note any assumptions or references"),
  cbind.data.frame(category = "Administrative areas and organization",
                   observation = "Points of Entry Count",
                   definition = "The number of points of entry participating in IHR-related activities (this must be a number)",
                   example_value = 5,
                   value = NA,
                   note = "(optional) space for you to note any assumptions or references"),
  cbind.data.frame(category = "Healthcare worker requirements",
                   observation = "Additional doctors, nurses, and midwives",
                   definition = "The number of additional doctors, nurses, and midwives, beyond existing workforce capacity, to be considered in cost calculations  (this must be a number)", 
                   example_value = 0,
                   value = NA,
                   note = "(optional) space for you to note any assumptions or references"))

## merge full metric information with line item costs to generate costing worksheet
## add single field, "include" for users to indicate if they'd like to include a specific cost
worksheet_items_jee3 <-  cbind.data.frame(
  include = TRUE,
  merge(metrics, line_items, 
        by.x = "metric_score_id",
        by.y = "jee3_metric_score_id",
        sort = FALSE))

## create a place for countries to enter their score for each unique score
## note that since no countries have completed a third edition JEE as of the time
## of creating this calculator tool, users will have to complete a self-assessment
## and enter this manually; as a placeholder, we will specify a score of 1 against all 
## indicators for JEE 3.0

## first roll up metrics dataframe to a new dataset with just one row per indicator,
## because the metrics dataframe contains one row per indicater per score

raw_scores <- metrics %>%
  filter(framework == "JEE (3.0)") %>%
  group_by(metric_id,framework, pillar, capacity, indicator) %>%
  summarize(n = n(), .groups = 'keep')
  
scores <- cbind.data.frame("metric_id" = raw_scores$metric_id,
                           "framework" = raw_scores$framework,
                           "pillar" = raw_scores$pillar,
                           "capacity" = raw_scores$capacity,
                           "indicator" = raw_scores$indicator,
                           "country_score_numeric" = 1)

## treat pillar as a factor so we keep the prevent, detect, response, other order
scores$pillar <- factor(scores$pillar, levels = c("Prevent", "Detect", "Respond", "IHR Related Hazards and Points of Entry and Border Health"))
scores <- scores[order(scores$pillar, scores$metric_id),]

## list all tabs you want to export in the Excel document worksheet you're making
excel_sheets <- list("Country scores" = scores,
                     "Multipliers" = multipliers,
                     "Unit costs" = unit_costs,
                     "Line items (JEE 3)" = worksheet_items_jee3)

## export worksheet in Excel
write.xlsx(excel_sheets, file = "calculator-tool/jee3_costing_worksheet.xlsx")

