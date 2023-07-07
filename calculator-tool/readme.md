# IHR-costing
The IHR Costing Tool helps users generate and review cost estimates to support practical planning for sustainable capacity development to prevent, detect, and respond to public health threats, as defined by the International Health Regulations (IHR).

## Calculator Tool

This directory is still in progress, but will eventually include a simple R script that allows users to:

- read in data from the data/ directory
- specify a set of user inputs and assumptions
- estimate yearly costs and generate simple visual graphics and outputs

The calculator script will be designed to help calculate costs for one country at a time

## Testing

Test case:
- country_score_numeric: 2
- score_numeric: 2
- cost type: startup
- expected outcome: line-item not costed, country is already at this score

Test case:
- country_score_numeric: 2
- score_numeric: 3
- cost type: startup
- expected outocme: line-item costed in year one and not again

Test case:
- country_score_numeric: 2
- score_numeric: 3
- cost type: recurring
- expected outcome: line-item costed in year one and again every year after

Test case:
- country_score_numeric = 2
- score_numeric = 4
- type = start up
- expected outcome: costed in year 2, not again; first year, country goes fron 2->3, second year, country goes from 3->4 (and this gets scored)
