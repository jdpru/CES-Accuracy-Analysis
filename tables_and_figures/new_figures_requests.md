### CES Provided Weights Top Line

All errors computed as RMSE. 

1. metrics_base.xlsx: A big table that reports the RMSE for CES provided weights. Each row will be a variable. Each column will be a year. There will be a divider between the Primary and Secondary variables. Use Validity_Scheme All. 
2. metrics_base.xlsx: A big table that reports the RMSE for Unweighted. Each row will be a variable. Each column will be a year. There will be a divider between the Primary and Secondary variables. Use Validity_Scheme All. This is the results of sample matching *alone*. 
3. CES-Weighted RMSE for Vote Share by Office and Year. Use Validity_Scheme All. Only Secondary variables (Variable_Type). 
4. Histogram with RMSE by Class. Use Validity_Scheme All. Secondary variables. 
5. Error buckets by Class. Use Validity_Scheme All. Secondary variables. 
6. Grouped histogram with average RMSE per year, Primary vs. Secondary variables. Use Validity_Scheme All. 
7. Grouped histogram with reduction in error with CES-provided weights, separately for primary and secondary variables (4 bars per year). Use Validity_Scheme All. 
8. RMSE by race-competitiveness. Use Validity_Scheme All. Only Class Candidate Choice. 

### Weighting Effects

1. Histogram comparing unweighted, weighted, anesrake weighted within each year. Use Validity_Scheme Anesrake - Full. Secondary variables only. 
2. RMSE reductions due to post-stratification by year. Use Validity_Scheme Full. 
3. RMSE reductions due to post-stratification by office. Use Validity_Scheme Full. 
4. Table that compares accuracy across the three validity_schemes by Class.

### Extraneous

1. A scatter plot with the three Classes. Plotting the relationship between state size and error in that class. Dot for each year x class combo. You get the state populations from this path. '/Users/jdpruett/Desktop/CES Accuracy Analysis/data/Benchmarks/Historical_State_Population_by_Year.xlsx’. Review this sheet to understand its structure. 
2. Create a table that does a linear regression to test for error trends over time across the three classes of variables. 
3. There are validity schemes - full vs. restricted set of ANESWeights. I want to create a figure that shows the average error of these two sets over the years. Do any additional analysis for comparing full vs. restricted set of anesrake weights that you think would be useful. 
4. Looking at the party-level reporting. I want to check for systematic party bias by year. So for each year, create a plot that is Democratic vote - republican vote share. This would need to use Specificity level == Party. Validity Scheme All. 
5. I want to test how error changes when I use candidate choice vs. party. Use party_candidate_combined_valid and check if there’s a difference between the two, by office. Create a table.