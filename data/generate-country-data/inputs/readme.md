# Country-level data inputs

This directory contains data accessed from the World Bank group to summarize information about countries or other geopolitical areas. The table below documents the sources of each table included in this directory.

All files saved in this subdirectory have the same format and contents as the original datasets obtained from each source. They are stored here as references and for research purposes, but researchers aiming to use these raw data for their own purposes should consult the references below to obtain original data from each source.


| Directory               | File                              |  Source             | Data last updated
| :---                    | :---                              | :---                | :--- 
| cia_factbook            | countries_cfb.tsv                 | CIA World Factbook  | 9 December, 2022
| oecd                    | utilization_dataset.csv           | OECD                | 2023 (acessed 14 April, 2023)
| oecd                    | country_hospitals.tsv             | OECD                | 4 July, 2022 (acessed 16 December, 2022)
| world-bank              | CLASS.xlsx                        | World Bank          | January 2023 (accessed 7 January, 2023)
| world-bank              | OGHIST.xlsx                       | World Bank          | January 2023 (accessed 7 January, 2023)
| who                     | medical_doctors_per10000.csv      | WHO                 | 24 January 2022 (accessed 13 January, 2023)
| who                     | nursing_midwives_per10000.csv     | WHO                 | 8 February 2022 (accessed 13 January, 2023)
| who                     | chw_count.csv                     | WHO                 | 12 January 2022 (accessed 13 January, 2023)
| who                     | who_member_states.tsv                 | WHO                 | February 2023 (accessed 10 February, 2023, manually extracted)
| who                     | IHRScoreperCapacity_202305051146.xlsx | WHO                 | 5 January 2023 (accessed 5 May, 2023)

**Source, CIA World Factbook**
*File: countries_cfb.tsv*

CIA World Factbook. Administrative divisions [Internet]. 2022 [cited 2022 Dec 9]. Available from: https://www.cia.gov/the-world-factbook/field/administrative-divisions/

**Source: OECD**
*Files: country_hospitals.tsv and utilization_dataset.csv*

OECD. Health Care Resources: Hospitals [Internet]. [cited 2022 Dec 16]. Available from: https://stats.oecd.org/index.aspx?queryid=30182
OECD and (WHO)[https://gateway.euro.who.int/en/indicators/hlthres_66-general-hospitals-total/] define general hospitals as "licensed establishments primarily engaged in providing general diagnostic and medical treatment (both surgical and non-surgical) to inpatients with a wide variety of medical conditions."

OECD. Doctors' consultations (indicator) [Internet]. doi: 10.1787/173dcf26-en. [cited 2023 April 14] (Accessed on 14 April 2023). Available from: https://data.oecd.org/healthcare/doctors-consultations.htm
	From OECD: "This indicator presents data on the number of consultations patients have with doctors in a given year. Consultations with doctors can take place in doctors’ offices or clinics, in hospital outpatient departments or, in some cases, in patients’ own homes. Consultations with doctors refer to the number of contacts with physicians, both generalists and specialists. There are variations across countries in the coverage of different types of consultations, notably in outpatient departments of hospitals. The data come from administrative sources or surveys, depending on the country. This indicator is measured per capita."

**Source: World Bank**
*Files: CLASS.xlsx and OGHIST.xlsx*

World Bank. World Bank Country and Lending Groups [Internet]. 2023 [cited 2023 Jan 7]. Available from: https://datahelpdesk.worldbank.org/knowledgebase/articles/906519-world-bank-country-and-lending-groups

**Source: World Health Organization**
*Files: medical_doctors_per10000.csv, nursing_midwives_per10000.csv, dentists_per10000.csv, chw_count.csv, IHRScoreperCapacity_202305051146.xlsx*

World Health Organization. Global Health Workforce statistics database [Internet]. [cited 2023 Jan 13]. Available from: https://www.who.int/data/gho/data/themes/topics/health-workforce

*File: who_member_states.tsv*
This file contains information on WHO member-states and corresponding WHO regional offices, where specified. Data were manually extracted from the WHO website as of February 2023. World Health Organization. Countries overview [Internet]. 2023 [cited 2023 Feb 10]. Available from: https://www.who.int/countries

*File: IHRScoreperCapacity_202305051146.xlsx*/
This file contains information on 2022 SPAR scores. It was accessed May 5, 2023 from the WHO e-SPAR portal. World Health Organization. e-SPAR Public [Internet]. [cited 2023 May 5]. Available from: https://extranet.who.int/e-spar/


https://extranet.who.int/e-spar/


