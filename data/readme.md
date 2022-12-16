# IHR-costing
The IHR Costing Tool helps users generate and review cost estimates to support practical planning for sustainable capacity development to prevent, detect, and respond to public health threats, as defined by the International Health Regulations (IHR).

## Data directory

This directory contains the underlying datasets that power the IHR costing tool. For additional information, please see the data dictionary included as part of this repository (in-progress). All files are saved as .tsv viles (tab separated values) and can be opened using your analysis software of choice.


| File                    |  Source                | Data last updated
| :---                    | :---                   | :--- 
| jee3.tsv                | JEE 3.0                | 16 December, 2022
| country.tsv             | CIA World Factbook     | 11 December, 2022
| unit_costs.tsv          | GHSS Research Team     | (to be added)
| detailed_costing.tsv    | GHSS Research Team     | (to be added)

### jee3.tsv
This file contains information on the indicators and attributes associated with the third edition of the [Joint External Evaluation Tool (JEE)](https://www.who.int/publications/i/item/9789240051980).

   - **data last updated:** 16 December, 2022 (JEE published mid-year in 2022)
   - **resolution:** one row per indicator per attribute/score pair
   - **source or reference:** 1. Health Organization. Joint external evaluation tool: International Health Regulations (2005)- third edition. Available from: https://www.who.int/publications-detail-redirect/9789240051980


### country.tsv
This file contains information on geographic areas, including countries and other territories, based on data from the [CIA World Factbook](https://www.cia.gov/the-world-factbook/field/administrative-divisions/) as of 11 December, 2022. It contains one row per country, region, or other geographic area included in the CIA World Factbook administraive dataset. For analyses related to the IHR costing tool, it can be used to estimate the number of administrative regions per country; however, this information is best supplemented by local expertise and information on the administrative organization of IHR-related activities. 

   - **data last updated:** 11 December, 2022
   - **resolution:** one row per country or area
   - **source or reference:** CIA World Factbook. Administrative divisions [Internet]. 2022 [cited 2022 Dec 11]. Available from: https://www.cia.gov/the-world-factbook/field/administrative-divisions/

### unit_costs.tsv
This file contains information on default unit costs for items included in the IHR costing tool. Of note, these costs are best determined on a local and/or regional basis, as unit costs can and do vary substantially from location to location, particularly unit costs associated with personnel salaries. These references are intended to serve as defaults and available references, but are not meant to replace local expertise in procurement, budgeting, and supply chain expertise.

   - **data last updated:** 16 December, 2022
   - **resolution:** one row per unit cost
   - **source or reference:** GHSS Research, citations and URLs included throughout

### detailed_costing.tsv
This file is included for reference only, and contains documentation of any subcosts used to estimate the unit costs reported in the file unit_costs.tsv. For example, the unit_costs table includes the cost of an "outbreak investigation kit", this detailed costing spreadsheet documents the underlying costs used to calculate that cost on the basis of the items identified as required for an outbreak investigation kit in [Connolly MA, Organization WH. Communicable disease control in emergencies: a field manual. World Health Organization; 2005 cited 2022 Oct 21. vii, pg. 234. Available from: https://apps.who.int/iris/handle/10665/96340

   - **data last updated:** 16 December, 2022
   - **resolution:** one row per item
   - **source or reference:** GHSS Research, citations and URLs included throughout



