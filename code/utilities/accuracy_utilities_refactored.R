# Refactored Accuracy Calculation Utilities
# Simplified, modular approach to calculating CES accuracy errors
# Author: Claude Code (Refactoring)
# Date: 2025-10-17
#
# Key Design Principles:
# 1. Consistent error convention: Error = CES - Benchmark (positive = overestimate)
# 2. Unified output schema across all measurement types
# 3. Modular functions with single responsibilities
# 4. Configuration-driven to reduce hardcoding

# ==============================================================================
# CONFIGURATION MANAGEMENT
# ==============================================================================

#' Create accuracy calculation configuration
#'
#' @description
#' Centralizes all configuration for accuracy calculations in one place.
#'
#' @param yearly_ces_wt_vars Named list of weight variable names by year
#' @param skip_conditions Data frame with skip conditions
#' @param NC_flag_df Data frame with NC district flags for 2020
#' @param vars_used_ces_weights Named list (by year) of variables used in CES weighting
#' @param anesrake_results Named list (by year) with ANESRake results including varsused
#'
#' @return A configuration list for accuracy calculations
create_accuracy_config <- function(yearly_ces_wt_vars,
                                   skip_conditions,
                                   NC_flag_df,
                                   vars_used_ces_weights = NULL,
                                   anesrake_results = NULL) {
  list(
    # Weight variables by year
    weight_vars = yearly_ces_wt_vars,
    
    # Race type mappings
    race_maps = list(
      party = c(
        HOUSE_PARTY_rc       = "US House",
        SENATOR_PARTY_rc     = "US Senate",
        PRES_PARTY_rc        = "President",
        GOV_PARTY_rc         = "Governor",
        SECSTATE_PARTY_rc    = "Secretary of State",
        AG_PARTY_rc          = "Attorney General",
        ST_REP_PARTY_rc      = "State Representative",
        ST_SENATOR_PARTY_rc  = "State Senator"
      ),
      candidate = c(
        PRES_CANDIDATE_rc     = "President",
        SENATOR_CANDIDATE_rc  = "US Senate",
        HOUSE_CANDIDATE_rc    = "US House",
        GOV_CANDIDATE_rc      = "Governor",
        SECSTATE_CANDIDATE_rc = "Secretary of State",
        AG_CANDIDATE_rc       = "Attorney General"
      )
    ),
    
    # Skip conditions
    skip_conditions = skip_conditions,
    NC_flag_df = NC_flag_df,
    
    # Variables used in weighting processes
    vars_used_ces_weights = vars_used_ces_weights,
    anesrake_results = anesrake_results,
    
    # Standard parties
    standard_parties = c("Democrat", "Republican", "Other")
  )
}


# ==============================================================================
# HELPER: EXTRACT COMPARISON VARIABLES
# ==============================================================================

#' Extract comparison variables from targets object
#'
#' @description
#' Automatically extracts the union of all unique variable names from the
#' all_targets object. This determines which demographic/voting variables
#' can be compared between CES and CPS.
#'
#' @param all_targets Named list (by year) of target lists
#'
#' @return Character vector of unique variable names
#' @export
extract_comparison_vars <- function(all_targets) {
  
  # Get all variable names across all years
  all_vars <- unique(unlist(lapply(all_targets, names)))
  
  # Sort for consistency
  sort(all_vars)
}


# ==============================================================================
# MAIN CALCULATION FUNCTIONS
# ==============================================================================

#' Calculate party-level election errors
#'
#' @description
#' Calculates errors comparing CES party vote shares to actual election returns.
#' Error = CES - Actual (positive means CES overestimates that party).
#'
#' @param year_data_list List of year data with CES surveys
#' @param election_results_df Election returns with party proportions
#' @param config Configuration object from create_accuracy_config()
#'
#' @return Tibble with party-level errors in standardized format
calculate_party_errors <- function(year_data_list, election_results_df, config) {
  
  race_map <- config$race_maps$party
  result_list <- list()
  
  pb <- progress_bar$new(
    format = "Party-level [:year] [:bar] :percent eta: :eta",
    total = length(year_data_list), clear = FALSE, width = 60
  )
  
  for (year_data in year_data_list) {
    pb$tick(tokens = list(year = year_data$year))
    current_year <- year_data$year
    ces_df <- year_data$CES
    
    year_elec <- election_results_df %>% filter(Year == current_year)
    available_races <- intersect(names(ces_df), names(race_map))
    
    year_results <- tibble()
    
    for (race_col in available_races) {
      ces_filtered <- filter_nc_if_needed(ces_df, current_year, race_col, config$NC_flag_df)
      office_label <- race_map[[race_col]]
      
      for (state in unique(na.omit(ces_filtered$POST_STATE_rc))) {
        
        if (should_skip_race(state, current_year, race_col, config$skip_conditions)) {
          next
        }
        
        state_survey <- ces_filtered %>% filter(POST_STATE_rc == state)
        n_resp <- sum(!is.na(state_survey[[race_col]]))
        if (n_resp == 0) next
        
        # Get benchmark
        state_returns <- year_elec %>%
          filter(State == state, Office == office_label)
        if (nrow(state_returns) == 0) {
          stop(glue::glue("No election results for {office_label}, {state}, {current_year}"))
        }
        
        # Calculate proportions for all weighting schemes
        ces_props <- calculate_all_weight_proportions(
          state_survey, race_col, current_year, config, ensure_parties = TRUE
        )
        
        # Benchmark proportions
        benchmark <- c(
          Democrat   = state_returns$DEM_Proportion,
          Republican = state_returns$REP_Proportion,
          Other      = state_returns$OTHER_Proportion
        )
        
        # Determine variable metadata (using raw variable name)
        var_metadata <- determine_variable_metadata(race_col, current_year, config)
        
        # Create rows for each party
        for (party in names(benchmark)) {
          year_results <- bind_rows(
            year_results,
            tibble(
              Year          = current_year,
              State         = state,
              Class         = "Candidate Choice",
              Variable      = office_label,
              Category      = party,
              
              # Variable type tracking
              Variable_Type = var_metadata$variable_type,
              Used_in_ANESRake_Weighting = var_metadata$used_in_anesrake_weighting,
              
              Benchmark     = benchmark[party] * 100,
              
              CES_Unweighted        = ces_props$unweighted[party] * 100,
              CES_Weighted          = ces_props$ces_weight[party] * 100,
              CES_ANESRake_Weighted = ces_props$anes_weight[party] * 100,
              
              # Consistent convention: CES - Benchmark
              Error_Unweighted      = (ces_props$unweighted[party] - benchmark[party]) * 100,
              Error_CES_Weighted    = (ces_props$ces_weight[party] - benchmark[party]) * 100,
              Error_ANESRake        = (ces_props$anes_weight[party] - benchmark[party]) * 100,
              
              n_respondents = n_resp
            )
          )
        }
      }
    }
    
    result_list[[as.character(current_year)]] <- year_results
  }
  
  bind_rows(result_list)
}


#' Calculate candidate-level election errors
#'
#' @description
#' Calculates errors comparing CES candidate vote shares to actual election returns.
#' Uses fuzzy matching to link candidate names. Error = CES - Actual.
#'
#' IMPORTANT: This function returns ONLY the top (modal) candidate per race.
#' The get_top_candidate() helper already filters to the candidate with the
#' highest vote share, so the output does NOT need modalization via keep_modal_only().
#'
#' @param year_data_list List of year data with CES surveys
#' @param candidate_returns_df Candidate-level election returns
#' @param config Configuration object from create_accuracy_config()
#'
#' @return Tibble with candidate-level errors in standardized format (already modal)
calculate_candidate_errors <- function(year_data_list, candidate_returns_df, config) {
  
  race_map <- config$race_maps$candidate
  result_list <- list()
  
  pb <- progress_bar$new(
    format = "Candidate-level [:year] [:bar] :percent eta: :eta",
    total = length(year_data_list), clear = FALSE, width = 60
  )
  
  for (year_data in year_data_list) {
    pb$tick(tokens = list(year = year_data$year))
    current_year <- year_data$year
    
    # Skip years without candidate data
    if (current_year %in% c("2006", "2008")) next
    
    ces_df <- year_data$CES
    ces_cols <- intersect(names(ces_df), names(race_map))
    year_results <- tibble()
    
    for (race_col in ces_cols) {
      ces_filtered <- filter_nc_if_needed(ces_df, current_year, race_col, config$NC_flag_df)
      office_label <- race_map[[race_col]]
      
      for (state in unique(na.omit(ces_filtered$POST_STATE_rc))) {
        
        if (should_skip_race(state, current_year, race_col, config$skip_conditions)) {
          next
        }
        
        state_df <- ces_filtered %>% filter(POST_STATE_rc == state)
        districts <- get_districts_for_office(office_label, state_df)
        
        for (district in districts) {
          
          survey <- filter_by_district(state_df, office_label, district)
          n_resp <- sum(!is.na(survey[[race_col]]))
          if (n_resp == 0) next
          
          # Get benchmark candidate
          top_cand <- get_top_candidate(
            candidate_returns_df, current_year, state, office_label, district
          )
          if (is.null(top_cand)) next
          
          # Fuzzy match
          match_result <- match_candidate_fuzzy(survey, race_col, top_cand$Candidate)
          
          # Find party
          ces_party <- get_candidate_party(survey, race_col, match_result$matched_ces)
          
          # Calculate proportions
          ces_props <- calculate_all_weight_proportions(
            survey, race_col, current_year, config, ensure_parties = FALSE
          )
          
          # Extract values for matched candidate
          benchmark_pct <- top_cand$Proportion * 100
          ces_unwt  <- ces_props$unweighted[match_result$matched_ces] * 100
          ces_wt    <- ces_props$ces_weight[match_result$matched_ces] * 100
          anes_wt   <- ces_props$anes_weight[match_result$matched_ces] * 100
          
          # Determine variable metadata (using raw variable name)
          var_metadata <- determine_variable_metadata(race_col, current_year, config)
          
          year_results <- bind_rows(
            year_results,
            tibble(
              Year          = current_year,
              State         = state,
              District      = district,
              Class         = "Candidate Choice",
              Variable      = office_label,
              Category      = ces_party,
              
              # Variable type tracking
              Variable_Type = var_metadata$variable_type,
              Used_in_ANESRake_Weighting = var_metadata$used_in_anesrake_weighting,
              
              CES_Candidate    = str_to_title(match_result$matched_ces),
              True_Candidate   = str_to_title(top_cand$Candidate),
              Match_Score      = match_result$score,
              
              Benchmark        = benchmark_pct,
              
              CES_Unweighted        = ces_unwt,
              CES_Weighted          = ces_wt,
              CES_ANESRake_Weighted = anes_wt,
              
              # Consistent convention: CES - Benchmark
              Error_Unweighted   = ces_unwt - benchmark_pct,
              Error_CES_Weighted = ces_wt - benchmark_pct,
              Error_ANESRake     = anes_wt - benchmark_pct,
              
              n_respondents = n_resp
            )
          )
        }
      }
    }
    
    result_list[[as.character(current_year)]] <- year_results
  }
  
  bind_rows(result_list)
}


#' Calculate demovote errors (CES vs CPS/State Turnout/State Populations)
#'
#' @description
#' Calculates errors comparing CES demographics and voting behavior to benchmarks.
#' Error = CES - Benchmark (consistent with election errors).
#'
#' Special handling for specific variables:
#' - VOTED_rc (turnout): Uses actual state turnout rates instead of CPS (REQUIRED).
#'   District of Columbia is automatically skipped (no official turnout data available).
#' - POST_STATE_rc (state): Uses actual state population shares instead of CPS (REQUIRED).
#'   Measures CES state sampling accuracy by comparing CES state shares to true population shares.
#' - All other variables: Use CPS as benchmark.
#'
#' Comparison variables are automatically extracted from all_targets.
#'
#' @param year_data_list List of year data with CES and CPS
#' @param all_targets Named list of targets by year (used to auto-extract comparison_vars)
#' @param config Configuration object from create_accuracy_config()
#' @param turnout_statewide Data frame with actual state turnout rates by year (REQUIRED if VOTED_rc in targets)
#' @param state_populations Data frame with actual state population shares by year (REQUIRED if POST_STATE_rc in targets)
#'
#' @return Tibble with demovote errors in standardized format
calculate_demovote_errors <- function(year_data_list,
                                      all_targets,
                                      config,
                                      turnout_statewide,
                                      state_populations) {
  
  # Auto-extract comparison_vars from all_targets
  comparison_vars <- extract_comparison_vars(all_targets)
  message("Auto-extracted ", length(comparison_vars), " comparison variables from all_targets")
  
  all_results <- list()
  
  for (year_data in year_data_list) {
    year <- year_data$year
    ces_df <- year_data$CES
    cps_df <- year_data$CPS
    
    wt_vars <- config$weight_vars[[as.character(year)]]
    
    # Special handling for POST_STATE_rc - process at national level, not by state
    if ("POST_STATE_rc" %in% comparison_vars && "POST_STATE_rc" %in% names(ces_df)) {
      
      # Require state_populations for POST_STATE_rc
      if (missing(state_populations) || is.null(state_populations)) {
        stop("state_populations is REQUIRED for POST_STATE_rc accuracy calculation. Please provide the state_populations data frame with columns: State, Year, Population_Share")
      }
      
      # Get all states in CES for this year
      ces_states <- unique(na.omit(ces_df$POST_STATE_rc))
      
      # Calculate CES state shares (proportion of national sample in each state)
      ces_unwt_shares <- prop.table(table(factor(ces_df$POST_STATE_rc, levels = ces_states)))
      ces_wt_shares <- weighted_prop_zero(ces_df$POST_STATE_rc, ces_df[[wt_vars[1]]], levels = ces_states)
      anes_wt_shares <- weighted_prop_zero(ces_df$POST_STATE_rc, ces_df$anesrake_weight, levels = ces_states)
      
      # Determine variable metadata
      var_metadata <- determine_variable_metadata("POST_STATE_rc", year, config)
      
      # Create row for each state
      for (state in ces_states) {
        
        # Get true state population share from state_populations
        state_pop_row <- state_populations %>%
          filter(State == state, Year == year)
        
        if (nrow(state_pop_row) == 0) {
          stop(glue::glue("No state population data found for {state} in {year}. Check state_populations data."))
        }
        
        true_pop_share <- state_pop_row$Population_Share
        
        all_results[[length(all_results) + 1]] <- tibble(
          Year          = year,
          State         = state,
          Class         = "Demographic",
          Variable      = "POST_STATE_rc",
          Category      = state,
          
          # Variable type tracking
          Variable_Type = var_metadata$variable_type,
          Used_in_ANESRake_Weighting = var_metadata$used_in_anesrake_weighting,
          
          Benchmark     = true_pop_share * 100,
          
          CES_Unweighted        = as.numeric(ces_unwt_shares[state]) * 100,
          CES_Weighted          = as.numeric(ces_wt_shares[state]) * 100,
          CES_ANESRake_Weighted = as.numeric(anes_wt_shares[state]) * 100,
          
          # Consistent convention: CES - Benchmark (CES Share - True Pop Share)
          Error_Unweighted   = (as.numeric(ces_unwt_shares[state]) - true_pop_share) * 100,
          Error_CES_Weighted = (as.numeric(ces_wt_shares[state]) - true_pop_share) * 100,
          Error_ANESRake     = (as.numeric(anes_wt_shares[state]) - true_pop_share) * 100,
          
          n_respondents = sum(ces_df$POST_STATE_rc == state, na.rm = TRUE)
        )
      }
    }
    
    for (state in unique(na.omit(ces_df$POST_STATE_rc))) {
      ces_state <- filter(ces_df, POST_STATE_rc == state)
      cps_state <- filter(cps_df, POST_STATE_rc == state)
      
      for (demo_var in comparison_vars) {
        
        # Skip POST_STATE_rc here - already handled at national level above
        if (demo_var == "POST_STATE_rc") {
          next
        }
        
        if (!(demo_var %in% names(ces_state)) || !(demo_var %in% names(cps_state))) {
          next
        }
        
        # Special handling for VOTED_rc (turnout)
        if (demo_var == "VOTED_rc") {
          
          # Skip DC - no official turnout data available
          if (state == "DISTRICT OF COLUMBIA") {
            next
          }
          
          # Require turnout_statewide for VOTED_rc
          if (is.null(turnout_statewide)) {
            stop("turnout_statewide is required for VOTED_rc accuracy calculation. Please provide the turnout_statewide data frame.")
          }
          
          # Get state turnout from turnout_statewide
          state_turnout <- turnout_statewide %>%
            filter(State == state) %>%
            pull(as.character(year))
          
          # Convert to proportion and handle if missing
          state_turnout_prop <- ifelse(length(state_turnout) > 0,
                                       as.numeric(state_turnout),
                                       NA_real_)
          
          # Error if no state turnout available for this state/year
          if (is.na(state_turnout_prop)) {
            stop(glue::glue("No state turnout data found for {state} in {year}. Check turnout_statewide data."))
          }
          
          # Calculate CES turnout proportions (proportion who "Voted")
          ces_unwt_turnout <- mean(ces_state$VOTED_rc == "Voted", na.rm = TRUE)
          ces_wt_turnout   <- weighted.mean(ces_state$VOTED_rc == "Voted",
                                            ces_state[[wt_vars[1]]],
                                            na.rm = TRUE)
          anes_wt_turnout  <- weighted.mean(ces_state$VOTED_rc == "Voted",
                                            ces_state$anesrake_weight,
                                            na.rm = TRUE)
          
          # Determine variable metadata
          var_metadata <- determine_variable_metadata(demo_var, year, config)
          
          # Create single row for "Voted" category using state turnout as benchmark
          all_results[[length(all_results) + 1]] <- tibble(
            Year          = year,
            State         = state,
            Class         = "Voting",
            Variable      = demo_var,
            Category      = "Voted",
            
            # Variable type tracking
            Variable_Type = var_metadata$variable_type,
            Used_in_ANESRake_Weighting = var_metadata$used_in_anesrake_weighting,
            
            Benchmark     = state_turnout_prop * 100,
            
            CES_Unweighted        = ces_unwt_turnout * 100,
            CES_Weighted          = ces_wt_turnout * 100,
            CES_ANESRake_Weighted = anes_wt_turnout * 100,
            
            # Consistent convention: CES - Benchmark (CES - State Turnout)
            Error_Unweighted   = (ces_unwt_turnout - state_turnout_prop) * 100,
            Error_CES_Weighted = (ces_wt_turnout - state_turnout_prop) * 100,
            Error_ANESRake     = (anes_wt_turnout - state_turnout_prop) * 100,
            
            n_respondents = NA_integer_
          )
          
        } else {
          # Standard handling for all other variables (use CPS as benchmark)
          
          # Harmonize levels
          categories <- sort(unique(c(ces_state[[demo_var]], cps_state[[demo_var]])))
          categories <- categories[!is.na(categories)]
          
          # CPS benchmark proportions
          cps_props <- prop.table(table(factor(cps_state[[demo_var]], levels = categories)))
          
          # CES proportions (all weighting schemes)
          ces_unwt <- prop.table(table(factor(ces_state[[demo_var]], levels = categories)))
          ces_wt   <- weighted_prop_zero(ces_state[[demo_var]], ces_state[[wt_vars[1]]], levels = categories)
          anes_wt  <- weighted_prop_zero(ces_state[[demo_var]], ces_state$anesrake_weight, levels = categories)
          
          # Determine variable metadata (using raw variable name)
          var_metadata <- determine_variable_metadata(demo_var, year, config)
          
          # Create row for each category
          for (cat in categories) {
            all_results[[length(all_results) + 1]] <- tibble(
              Year          = year,
              State         = state,
              Class         = if_else(demo_var %in% c("VOTEHOW_rc"), "Voting", "Demographic"),
              Variable      = demo_var,
              Category      = cat,
              
              # Variable type tracking
              Variable_Type = var_metadata$variable_type,
              Used_in_ANESRake_Weighting = var_metadata$used_in_anesrake_weighting,
              
              Benchmark     = as.numeric(cps_props[cat]) * 100,
              
              CES_Unweighted        = as.numeric(ces_unwt[cat]) * 100,
              CES_Weighted          = as.numeric(ces_wt[cat]) * 100,
              CES_ANESRake_Weighted = as.numeric(anes_wt[cat]) * 100,
              
              # Consistent convention: CES - Benchmark (CES - CPS)
              Error_Unweighted   = (as.numeric(ces_unwt[cat]) - as.numeric(cps_props[cat])) * 100,
              Error_CES_Weighted = (as.numeric(ces_wt[cat]) - as.numeric(cps_props[cat])) * 100,
              Error_ANESRake     = (as.numeric(anes_wt[cat]) - as.numeric(cps_props[cat])) * 100,
              
              n_respondents = NA_integer_
            )
          }
        }
      }
    }
  }
  
  bind_rows(all_results)
}


# ==============================================================================
# MODALIZATION
# ==============================================================================

#' Keep only modal category per group
#'
#' @description
#' Filters error table to retain only the modal (most common) category
#' within each grouping based on benchmark values.
#'
#' @param error_df Error data frame
#' @param group_vars Grouping variables (default: Year, State, Variable)
#'
#' @return Filtered data frame with only modal categories
keep_modal_only <- function(error_df, group_vars = c("Year", "State", "Variable")) {
  
  error_df %>%
    group_by(across(all_of(group_vars))) %>%
    slice_max(order_by = Benchmark, n = 1, with_ties = FALSE) %>%
    ungroup()
}


# ==============================================================================
# OUTPUT FORMATTING
# ==============================================================================

#' Convert errors to long format
#'
#' @description
#' Pivots error columns into long format with Weighting_Method and Error as columns.
#'
#' @param error_df Error data frame in wide format
#'
#' @return Long format data frame
pivot_errors_long <- function(error_df) {
  
  error_df %>%
    pivot_longer(
      cols = starts_with("Error_"),
      names_to = "Weighting_Method",
      values_to = "Error"
    ) %>%
    mutate(
      Weighting_Method = case_when(
        Weighting_Method == "Error_Unweighted"   ~ "Unweighted",
        Weighting_Method == "Error_CES_Weighted" ~ "CES Weights",
        Weighting_Method == "Error_ANESRake"     ~ "ANESRake",
        TRUE ~ Weighting_Method
      )
    )
}


#' Apply variable name standardization
#'
#' @description
#' Maps internal variable names to display names.
#'
#' @param df Data frame with Variable column
#' @param var_map Named vector for variable name mapping
#'
#' @return Data frame with standardized variable names
standardize_variable_names <- function(df, var_map = NULL) {
  
  if (is.null(var_map)) {
    var_map <- c(
      "US Senate"        = "U.S. Senate",
      "US House"         = "U.S. House",
      "President"        = "President",
      "Governor"         = "Governor",
      "AGE_GROUP_rc"     = "Age Group",
      "EDUC_rc"          = "Education",
      "EMPSTAT_rc"       = "Employment Status",
      "FAMINC_rc"        = "Family Income",
      "REGION_rc"        = "Region",
      "SEX_rc"           = "Sex",
      "UNION_rc"         = "Union Membership",
      "VETSTAT_rc"       = "Veteran Status",
      "VOTED_rc"         = "Voting Turnout",
      "VOTEHOW_rc"       = "Voting Method",
      "VOTEREG_rc"       = "Voter Registration",
      "HISPAN_rc"        = "Hispanic Origin",
      "CITIZEN_rc"       = "Citizenship Status",
      "POST_STATE_rc"    = "State of Residence"
    )
  }
  
  df %>%
    mutate(Variable = recode(Variable, !!!var_map, .default = Variable))
}


# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

#' Determine variable type and weighting usage
#'
#' @description
#' Determines if a variable is "Primary" (used in CES weighting) or "Secondary"
#' (not used in CES weighting), and whether it was used in ANESRake weighting.
#'
#' @param var_name Variable name (raw CES variable name like "SEX_rc")
#' @param year Year as character
#' @param config Configuration object
#'
#' @return List with variable_type and used_in_anesrake_weighting
#' @keywords internal
determine_variable_metadata <- function(var_name, year, config) {
  
  # Default values
  variable_type <- "Secondary"
  used_in_anesrake <- FALSE
  
  # Check if used in CES weights
  if (!is.null(config$vars_used_ces_weights)) {
    ces_vars <- config$vars_used_ces_weights[[as.character(year)]]
    if (!is.null(ces_vars) && var_name %in% ces_vars) {
      variable_type <- "Primary"
    }
  }
  
  # Check if used in ANESRake
  if (!is.null(config$anesrake_results)) {
    anes_vars <- config$anesrake_results[[as.character(year)]]$vars_used
    if (!is.null(anes_vars) && var_name %in% anes_vars) {
      used_in_anesrake <- TRUE
    }
  }
  
  list(
    variable_type = variable_type,
    used_in_anesrake_weighting = used_in_anesrake
  )
}


#' Filter NC cases if needed
#' @keywords internal
filter_nc_if_needed <- function(ces_df, year, race_col, NC_flag_df) {
  if (year == 2020 && race_col %in% c("HOUSE_PARTY_rc", "HOUSE_CANDIDATE_rc")) {
    ces_df %>% filter(!(caseid %in% NC_flag_df$caseid))
  } else {
    ces_df
  }
}

#' Check if race should be skipped
#' @keywords internal
should_skip_race <- function(state, year, race_col, skip_conditions) {
  skip_row <- skip_conditions %>%
    filter(State == state, Year == year, Race == race_col, `Skip?` == TRUE)
  nrow(skip_row) > 0
}

#' Calculate proportions for all weighting schemes
#' @keywords internal
calculate_all_weight_proportions <- function(survey_df, var_col, year, config, ensure_parties = FALSE) {
  
  wt_var <- config$weight_vars[[as.character(year)]][1]
  
  unweighted  <- wpct(survey_df[[var_col]], na.rm = TRUE)
  ces_weight  <- wpct(survey_df[[var_col]], weight = survey_df[[wt_var]], na.rm = TRUE)
  anes_weight <- wpct(survey_df[[var_col]], weight = survey_df$anesrake_weight, na.rm = TRUE)
  
  if (ensure_parties) {
    # Ensure all three parties exist with 0 if missing
    for (lvl in config$standard_parties) {
      if (lvl %notin% names(unweighted))  unweighted[lvl]  <- 0
      if (lvl %notin% names(ces_weight))  ces_weight[lvl]  <- 0
      if (lvl %notin% names(anes_weight)) anes_weight[lvl] <- 0
    }
    unweighted  <- unweighted[config$standard_parties]
    ces_weight  <- ces_weight[config$standard_parties]
    anes_weight <- anes_weight[config$standard_parties]
  }
  
  list(
    unweighted  = unweighted,
    ces_weight  = ces_weight,
    anes_weight = anes_weight
  )
}

#' Get districts for office type
#' @keywords internal
get_districts_for_office <- function(office_label, state_df) {
  if (office_label == "US House") {
    unique(na.omit(state_df$CDID_post_rc))
  } else if (office_label == "President") {
    "nationwide"
  } else {
    "statewide"
  }
}

#' Filter by district
#' @keywords internal
filter_by_district <- function(state_df, office_label, district) {
  if (district %notin% c("statewide", "nationwide")) {
    state_df %>% filter(CDID_post_rc == district)
  } else {
    state_df
  }
}

#' Get top candidate from benchmark data
#' @keywords internal
get_top_candidate <- function(candidate_returns, year, state, office, district) {
  
  returns <- candidate_returns %>%
    filter(Year == year, State == state, Office == office, District == district)
  
  if (nrow(returns) == 0) return(NULL)
  
  # Special case: 2010 Alaska Senate (write-in winner not in CES)
  if (year == 2010 && office == "US Senate" && state == "ALASKA") {
    returns %>% filter(Candidate == "JOE MILLER")
  } else {
    returns %>% slice_max(Proportion, n = 1, with_ties = FALSE)
  }
}

#' Fuzzy match candidate name
#' @keywords internal
match_candidate_fuzzy <- function(survey_df, race_col, true_cand) {
  
  ces_vals <- unique(na.omit(survey_df[[race_col]]))
  
  # Case-insensitive exact match
  exact_match <- any(stri_trans_tolower(true_cand) == stri_trans_tolower(ces_vals))
  
  if (!exact_match) {
    # Fuzzy match using Jaro-Winkler
    scores <- stringdist::stringdist(
      stri_trans_tolower(true_cand),
      stri_trans_tolower(ces_vals),
      method = "jw"
    )
    matched_ces <- ces_vals[which.min(scores)]
    score <- min(scores)
  } else {
    matched_ces <- ces_vals[stri_trans_tolower(ces_vals) == stri_trans_tolower(true_cand)][1]
    score <- 0
  }
  
  list(matched_ces = matched_ces, score = score)
}

#' Get party for matched candidate
#' @keywords internal
get_candidate_party <- function(survey_df, race_col, matched_ces) {
  
  party_col <- if (race_col == "PRES_CANDIDATE_rc") {
    "PRES_CANDIDATE_rc"
  } else {
    sub("_CANDIDATE_rc$", "_PARTY_rc", race_col)
  }
  
  if (!party_col %in% names(survey_df)) {
    stop(glue::glue("Missing party column: {party_col}"))
  }
  
  party_val <- survey_df %>%
    transmute(
      cand  = .data[[race_col]],
      party = .data[[party_col]]
    ) %>%
    filter(stri_trans_casefold(cand) == stri_trans_casefold(matched_ces)) %>%
    distinct(party) %>%
    pull(party)
  
  if (length(party_val) != 1) {
    stop(glue::glue("Candidate {matched_ces} has {length(party_val)} party values"))
  }
  
  party_val
}

#' Compute weighted proportions with explicit zeros
#' @keywords internal
weighted_prop_zero <- function(x, w, levels) {
  x <- factor(x, levels = levels)
  w_sums <- tapply(w, x, sum, na.rm = TRUE)
  w_sums[is.na(w_sums)] <- 0
  props <- w_sums / sum(w_sums)
  setNames(props, levels)
}
