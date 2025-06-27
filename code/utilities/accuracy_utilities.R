# This file contains utility functions for calcualting the accuracy of candidate choice and non-candidate choice variables

# Create template accuracy df
create_empty_result_df <- function() {
  data.frame(
    Year = numeric(),
    Race = character(),
    State = character(),
    CES_Candidate = character(),
    True_Candidate = character(),
    CES_Party = character(),
    True_Party = character(),
    Actual_Percent = numeric(),
    CES_Unweighted_Percent = numeric(),
    CES_Weighted_Percent = numeric(),
    ANESRake_Weighted_Percent = numeric(),
    Error_CES_Unweighted = numeric(),
    Error_CES_Weighted = numeric(),
    Error_CES_ANESRake_Weighted = numeric(),
    n_respondents = numeric(),
    stringsAsFactors = FALSE
  )
}

make_tables_pretty <- function(df) {
  #' Format accuracy tables for presentation
  #'
  #' This function takes a combined accuracy results data frame (with all years),
  #' splits it by year, rounds key numeric columns to 1 decimal place, renames
  #' columns for clarity, and ensures state names are in uppercase. It returns a
  #' named list of data frames, one per year, cleaned and ready for export or display.
  tables_by_year <- split(df, df$Year)
  
  # apply rounding + renaming to each element
  tables_pretty <- lapply(tables_by_year, function(tab) {
    tab %>%
      # round numeric columns to 1 decimal
      mutate(across(
        c(
          Actual_Percent,
          CES_Unweighted_Percent,
          CES_Weighted_Percent,
          ANESRake_Weighted_Percent,
          Error_CES_Unweighted,
          Error_CES_Weighted,
          Error_CES_ANESRake_Weighted,
        ),
        ~ round(.x, 1)
      )) %>%
      # rename
      rename(
        CES_Unweighted          = CES_Unweighted_Percent,
        CES_Weighted            = CES_Weighted_Percent,
        CES_ANESRake_Weighted   = ANESRake_Weighted_Percent,
      ) %>%
      
      mutate(
        State = toupper(State)         
      )
  })
  
  
  names(tables_pretty) <- names(tables_by_year)
  return(tables_pretty)
}


weighted_prop_zero <- function(x, w, levels) {
  #' Compute weighted proportions with explicit zeroes for missing levels
  #'
  #' This function computes the weighted proportion of each category in a factor variable,
  #' ensuring that categories with no cases receive a proportion of 0 rather than NA.
  #' It returns a named numeric vector with proportions for each specified level.
  
  # make sure x is a factor
  x <- factor(x, levels = levels)
  
  # sum the weights within each level
  w_sums <- tapply(w, x, sum, na.rm = TRUE)
  
  # any level with no cases will be NA → replace with 0
  w_sums[is.na(w_sums)] <- 0
  
  # divide by total weight
  props <- w_sums / sum(w_sums)
  
  # return a named numeric vector
  setNames(props, levels)
}
