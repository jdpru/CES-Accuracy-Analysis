# CES Accuracy Analysis Codebase Learning Document

## Overview

This project analyzes the accuracy of the Cooperative Election Study (CES) by comparing CES survey responses to known benchmarks (election returns, CPS data, state turnout rates). The analysis evaluates how different weighting methods affect survey accuracy.

## Key Concepts

### 1. Variable Types (Primary vs Secondary)

**Primary Variables**: Variables used by CES for post-stratification weighting. These CANNOT be used to evaluate CES weighting accuracy because they are forced to match benchmarks.

Examples by year:
- 2008-2012: `AGE_GROUP_rc`, `EDUC_rc`, `SEX_rc`, `VOTED_rc`
- 2014+: Added `VOTEREG_rc`, `POST_STATE_rc`, `GOV_CANDIDATE_rc`, `GOV_PARTY_rc`, `SENATOR_CANDIDATE_rc`, `SENATOR_PARTY_rc`
- 2018+: Added `HISPANIC_rc`

**Secondary Variables**: Variables NOT used in CES weighting. These CAN be used for unbiased accuracy assessment.

### 2. Classes

Three main categories of variables:

| Class | Description | Examples |
|-------|-------------|----------|
| **Candidate Choice** | Election voting preferences | President, Governor, U.S. Senate, U.S. House, Attorney General, Secretary of State, State Senator, State Representative |
| **Demographic** | Demographic characteristics | Age group, education, sex, Hispanic origin, region, etc. |
| **Voting** | Voting behavior | Voter turnout (VOTED_rc), voter registration (VOTEREG_rc), vote method (VOTEHOW_rc) |

### 3. Validity Schemes

Validity schemes control which combinations of variables and weighting methods are valid for comparison:

| Validity_Scheme | Description | Use Case |
|-----------------|-------------|----------|
| **All** | No filtering - all variables included | General CES-provided weights analysis |
| **ANESRake - Full** | Variables valid for full ANESRake comparison | Comparing CES weights vs ANESRake-Full |
| **ANESRake - Restricted** | Variables valid for restricted ANESRake comparison | Comparing CES weights vs ANESRake-Restricted |

### 4. Weighting Methods

| Method | Description |
|--------|-------------|
| **CES-Unweighted** | Raw sample matching only, no post-stratification |
| **CES-Provided Weights** | Official CES post-stratification weights |
| **ANESRake-Full** | Raking weights using full variable set |
| **ANESRake-Restricted** | Raking weights using restricted variable set |

### 5. Accuracy Flags

- `Valid_for_Accuracy_Full`: TRUE if variable can be used to evaluate accuracy under full ANESRake scheme
- `Valid_for_Accuracy_Restricted`: TRUE if variable can be used to evaluate accuracy under restricted ANESRake scheme

For unbiased accuracy assessment:
- Variable_Type must be "Secondary" (not used in CES weighting)
- Must not be used in the specific ANESRake scheme being evaluated

## Input Tables Structure

### metrics_base.xlsx
Main data table containing all observations with errors and metadata.

**Key Columns:**
- `Year`, `State`: Identifiers
- `Class`: Demographic, Voting, or Candidate Choice
- `Variable`: Specific variable name (e.g., "President", "U.S. Senate", "AGE_GROUP_rc")
- `Category`: The category/level being measured (e.g., "Democrat", "Republican", "18-29")
- `Variable_Type`: "Primary" or "Secondary"
- `Validity_Scheme`: "All", "ANESRake - Full", or "ANESRake - Restricted"
- `Weighting_Method`: The weighting approach used
- `Error`: Difference between CES estimate and benchmark
- `Benchmark`: True value from election returns/CPS/official data
- `n_respondents`: Number of respondents in the calculation

### dist_errors_bucket_table.xlsx
Error distribution bucketed by absolute error ranges.

**Key Columns:**
- `Validity_Scheme`, `Class`, `Weighting_Method`
- `Error_Bucket`: Range like "[0,1)", "[1,2)", etc.
- `Count`: Number of observations in bucket

### election_rmse_by_competitiveness_range.xlsx
RMSE by election competitiveness (vote margin).

**Key Columns:**
- `Validity_Scheme`, `Specificity`, `Year`, `Weighting_Method`
- `Range_Label`: "0-100%", "30-70%", "40-60%", "45-55%", "95-100%"
- `RMSE`, `Avg_Abs_Error`
- `n_observations`, `n_states`, `n_respondents`

### party_candidate_combined_valid.xlsx
Candidate choice data at both party and candidate specificity levels.

**Key Columns:**
- Similar to metrics_base but specific to Candidate Choice class
- `Specificity`: "Party" or "Candidate"

## Color Scheme (from old notebooks)

```python
# Standard colors used in figures
colors = {
    'CES-Unweighted': '#044c7c',        # Dark blue
    'CES-Provided Weights': '#44bbc3',   # Light teal
    'ANESRake': '#ffaf49'                # Orange
}

# Class colors (ColorBrewer Set2)
class_colors = {
    'Demographic': '#66c2a5',    # Teal
    'Voting': '#fc8d62',         # Orange
    'Candidate Choice': '#8da0cb' # Purple
}
```

## RMSE Calculation

RMSE (Root Mean Square Error) is the primary accuracy metric:

```
RMSE = sqrt(mean(Error^2))
```

Where `Error = CES_Estimate - Benchmark`

## File Structure

```
CES Accuracy Analysis/
├── code/
│   ├── analysisHQ.Rmd          # Main analysis script
│   └── utilities/
│       ├── accuracy_utilities_refactored.R
│       ├── election_return_utilities.R
│       ├── data_structures.R
│       └── recoding_utilities.R
├── tables_and_figures/
│   ├── input_tables/           # New input tables
│   │   ├── metrics_base.xlsx
│   │   ├── dist_errors_bucket_table.xlsx
│   │   ├── election_rmse_by_competitiveness_range.xlsx
│   │   └── party_candidate_combined_valid.xlsx
│   ├── input_tables_old/       # Old input tables
│   ├── output/                 # Output figures
│   ├── figuresHQ_old.ipynb     # Old figures notebook
│   └── radarANDinset_old.ipynb # Old radar/inset notebook
└── data/
    ├── CES Data/               # CES survey data
    ├── Benchmarks/             # Election returns, turnout data
    └── misc/                   # Skip conditions, etc.
```

## New Figures Requirements Summary

### CES Provided Weights Top Line (Validity_Scheme: All)
1. RMSE table by variable and year (CES-Provided Weights, Secondary only)
2. RMSE table by variable and year (Unweighted, Secondary only)
3. RMSE for Vote Share by Office and Year (Secondary only)
4. Histogram with RMSE by Class (Secondary only)
5. Error buckets by Class (Secondary only)
6. Grouped histogram: Average RMSE per year, Primary vs Secondary
7. Grouped histogram: Error reduction with CES weights, Primary vs Secondary
8. RMSE by race competitiveness (Candidate Choice only)

### Weighting Effects (Validity_Scheme: ANESRake - Full)
1. Histogram comparing unweighted, weighted, anesrake weighted (Secondary only)
2. RMSE reductions due to post-stratification by year
3. RMSE reductions due to post-stratification by office
4. Table comparing accuracy across validity schemes by Class
