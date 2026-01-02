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
# create_accuracy_config <- function(yearly_ces_wt_vars,
#                                    skip_conditions,
#                                    NC_flag_df,
#                                    vars_used_ces_weights = NULL,
#                                    anesrake_results = NULL) {
#   list(
#     # Weight variables by year
#     weight_vars = yearly_ces_wt_vars,
#     
#     # Race type mappings
#     race_maps = list(
#       party = c(
#         HOUSE_PARTY_rc       = "US House",
#         SENATOR_PARTY_rc     = "US Senate",
#         PRES_PARTY_rc        = "President",
#         GOV_PARTY_rc         = "Governor",
#         SECSTATE_PARTY_rc    = "Secretary of State",
#         AG_PARTY_rc          = "Attorney General",
#         ST_REP_PARTY_rc      = "State Representative",
#         ST_SENATOR_PARTY_rc  = "State Senator"
#       ),
#       candidate = c(
#         PRES_CANDIDATE_rc     = "President",
#         SENATOR_CANDIDATE_rc  = "US Senate",
#         HOUSE_CANDIDATE_rc    = "US House",
#         GOV_CANDIDATE_rc      = "Governor",
#         SECSTATE_CANDIDATE_rc = "Secretary of State",
#         AG_CANDIDATE_rc       = "Attorney General"
#       )
#     ),
#     
#     # Skip conditions
#     skip_conditions = skip_conditions,
#     NC_flag_df = NC_flag_df,
#     
#     # Variables used in weighting processes
#     vars_used_ces_weights = vars_used_ces_weights,
#     anesrake_results = anesrake_results,
#     
#     # Standard parties
#     standard_parties = c("Democrat", "Republican", "Other")
#   )
# }

create_accuracy_config <- function(yearly_ces_wt_vars,
                                   skip_conditions,
                                   NC_flag_df,
                                   vars_used_ces_weights,
                                   anesrake_full_results,
                                   anesrake_restricted_results,
                                   selected_weighting_vars) {
  list(
    weight_vars = yearly_ces_wt_vars,
    
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
    
    skip_conditions = skip_conditions,
    NC_flag_df = NC_flag_df,
    
    vars_used_ces_weights = vars_used_ces_weights,
    
    # BOTH ANESRAKE VARIANTS LIVE HERE
    anesrake = list(
      full = list(
        results = anesrake_full_results
        # vars_used computed dynamically
      ),
      restricted = list(
        results = anesrake_restricted_results,
        vars_used = selected_weighting_vars$Variable
      )
    ),
    
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
calculate_party_errors <- function(year_data_list, election_results_df, config) {
  race_map <- config$race_maps$party
  result_list <- list()
  
  pb <- progress_bar$new(
    format = "Party-level [:year] [:bar] :percent eta: :eta",
    total = length(year_data_list),
    clear = FALSE,
    width = 60
  )
  
  for (year_data in year_data_list) {
    
    pb$tick(tokens = list(year = year_data$year))
    year  <- year_data$year

    ces_df <- year_data$CES
    
    year_elec <- election_results_df %>% filter(Year == year)
    available_races <- intersect(names(ces_df), names(race_map))
    
    year_results <- tibble()
    
    for (race_col in available_races) {
      
      ces_filtered <- filter_nc_if_needed(
        ces_df, year, race_col, config$NC_flag_df
      )
      
      office_label <- race_map[[race_col]]
      
      for (state in unique(na.omit(ces_filtered$POST_STATE_rc))) {
        
        if (should_skip_race(state, year, race_col, config$skip_conditions)) {
          next
        }
        
        state_survey <- ces_filtered %>% filter(POST_STATE_rc == state)
        n_resp <- sum(!is.na(state_survey[[race_col]]))
        if (n_resp == 0) next
        
        # ---- Benchmark ----
        state_returns <- year_elec %>%
          filter(State == state, Office == office_label)
        
        if (nrow(state_returns) == 0) {
          stop(glue::glue(
            "No election results for {office_label}, {state}, {year}"
          ))
        }
        
        benchmark <- c(
          Democrat   = state_returns$DEM_Proportion,
          Republican = state_returns$REP_Proportion,
          Other      = state_returns$OTHER_Proportion
        )
        
        # ---- CES proportions (ALL schemes) ----
        ces_props <- calculate_all_weight_proportions(
          survey_df     = state_survey,
          var_col       = race_col,
          year          = year,
          config        = config,
          ensure_parties = TRUE
        )
        
        # ---- Variable metadata ----
        var_meta <- determine_variable_metadata(
          var_name = race_col,
          year     = year,
          config   = config
        )
        
        # ---- One row per party ----
        for (party in names(benchmark)) {
          
          year_results <- bind_rows(
            year_results,
            tibble(
              Year     = year,
              State    = state,
              Class    = "Candidate Choice",
              Variable = office_label,
              Category = party,
              
              # ---- Metadata ----
              Variable_Type = var_meta$variable_type,
              
              Used_in_ANESRake_Full       = var_meta$used_in_anesrake_full,
              Used_in_ANESRake_Restricted = var_meta$used_in_anesrake_restricted,
              
              Valid_for_Accuracy_Full       = var_meta$valid_for_accuracy_full,
              Valid_for_Accuracy_Restricted = var_meta$valid_for_accuracy_restricted,
              
              # ---- Benchmark ----
              Benchmark = benchmark[party] * 100,
              
              # ---- Estimates ----
              CES_Unweighted = ces_props$unweighted[party] * 100,
              CES_Weighted   = ces_props$ces_weight[party] * 100,
              
              CES_ANESRake_Full =
                ces_props$anes_full[party] * 100,
              
              CES_ANESRake_Restricted =
                ces_props$anes_restricted[party] * 100,
              
              # ---- Errors (CES - Benchmark) ----
              Error_Unweighted =
                (ces_props$unweighted[party] - benchmark[party]) * 100,
              
              Error_CES_Weighted =
                (ces_props$ces_weight[party] - benchmark[party]) * 100,
              
              Error_ANESRake_Full =
                (ces_props$anes_full[party] - benchmark[party]) * 100,
              
              Error_ANESRake_Restricted =
                (ces_props$anes_restricted[party] - benchmark[party]) * 100,
              
              n_respondents = n_resp
            )
          )
        }
      }
    }
    
    result_list[[as.character(year)]] <- year_results
  }
  
  bind_rows(result_list)
}



#' @return Tibble with party-level errors in standardized format
# calculate_party_errors <- function(year_data_list, election_results_df, config) {
#   
#   race_map <- config$race_maps$party
#   result_list <- list()
#   
#   pb <- progress_bar$new(
#     format = "Party-level [:year] [:bar] :percent eta: :eta",
#     total = length(year_data_list), clear = FALSE, width = 60
#   )
#   
#   for (year_data in year_data_list) {
#     pb$tick(tokens = list(year = year_data$year))
#     current_year <- year_data$year
#     ces_df <- year_data$CES
#     
#     year_elec <- election_results_df %>% filter(Year == current_year)
#     available_races <- intersect(names(ces_df), names(race_map))
#     
#     year_results <- tibble()
#     
#     for (race_col in available_races) {
#       ces_filtered <- filter_nc_if_needed(ces_df, current_year, race_col, config$NC_flag_df)
#       office_label <- race_map[[race_col]]
#       
#       for (state in unique(na.omit(ces_filtered$POST_STATE_rc))) {
#         
#         # Debug helper line
#         # if (current_year == 2018 && state == "NORTH DAKOTA" && office_label == "Secretary of State") {
#         #   browser()
#         # }
#         
#         if (should_skip_race(state, current_year, race_col, config$skip_conditions)) {
#           next
#         }
#         
#         state_survey <- ces_filtered %>% filter(POST_STATE_rc == state)
#         n_resp <- sum(!is.na(state_survey[[race_col]]))
#         if (n_resp == 0) next
#         
#         # Get benchmark
#         state_returns <- year_elec %>%
#           filter(State == state, Office == office_label)
#         if (nrow(state_returns) == 0) {
#           stop(glue::glue("No election results for {office_label}, {state}, {current_year}"))
#         }
#         
#         # Calculate proportions for all weighting schemes
#         ces_props <- calculate_all_weight_proportions(
#           state_survey, race_col, current_year, config, ensure_parties = TRUE
#         )
#         
#         # Benchmark proportions
#         benchmark <- c(
#           Democrat   = state_returns$DEM_Proportion,
#           Republican = state_returns$REP_Proportion,
#           Other      = state_returns$OTHER_Proportion
#         )
#         
#         # Determine variable metadata (using raw variable name)
#         var_metadata <- determine_variable_metadata(race_col, current_year, config)
#         
#         # Create rows for each party
#         for (party in names(benchmark)) {
#           year_results <- bind_rows(
#             year_results,
#             tibble(
#               Year          = current_year,
#               State         = state,
#               Class         = "Candidate Choice",
#               Variable      = office_label,
#               Category      = party,
#               
#               # Variable type tracking
#               Variable_Type = var_metadata$variable_type,
#               Used_in_ANESRake_Weighting = var_metadata$used_in_anesrake_weighting,
#               Valid_for_Accuracy = var_metadata$valid_for_accuracy,
#               
#               Benchmark     = benchmark[party] * 100,
#               
#               CES_Unweighted        = ces_props$unweighted[party] * 100,
#               CES_Weighted          = ces_props$ces_weight[party] * 100,
#               CES_ANESRake_Weighted = ces_props$anes_weight[party] * 100,
#               
#               # Consistent convention: CES - Benchmark
#               Error_Unweighted      = (ces_props$unweighted[party] - benchmark[party]) * 100,
#               Error_CES_Weighted    = (ces_props$ces_weight[party] - benchmark[party]) * 100,
#               Error_ANESRake        = (ces_props$anes_weight[party] - benchmark[party]) * 100,
#               
#               n_respondents = n_resp
#             )
#           )
#         }
#       }
#     }
#     
#     result_list[[as.character(current_year)]] <- year_results
#   }
#   
#   bind_rows(result_list)
# }



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
calculate_candidate_errors <- function(year_data_list,
                                       candidate_returns_df,
                                       config) {
  
  race_map <- config$race_maps$candidate
  result_list <- list()
  
  pb <- progress_bar$new(
    format = "Candidate-level [:year] [:bar] :percent eta: :eta",
    total = length(year_data_list), clear = FALSE, width = 60
  )
  
  for (year_data in year_data_list) {
    pb$tick(tokens = list(year = year_data$year))
    current_year <- year_data$year
    
    # Skip since no candidate data
    if (current_year %in% c("2006")) next

    ces_df <- year_data$CES
    ces_cols <- intersect(names(ces_df), names(race_map))
    year_results <- tibble()
    
    for (race_col in ces_cols) {
      ces_filtered <- filter_nc_if_needed(
        ces_df, current_year, race_col, config$NC_flag_df
      )
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
          
          # ---- Benchmark candidate ----
          top_cand <- get_top_candidate(
            candidate_returns_df, current_year, state, office_label, district
          )
          if (is.null(top_cand)) next
          
          # ---- Fuzzy match CES → benchmark ----
          match_result <- match_candidate_fuzzy(
            survey, race_col, top_cand$Candidate
          )
          
          ces_party <- get_candidate_party(
            survey, race_col, match_result$matched_ces
          )
          
          # ---- Proportions (ALL weighting schemes) ----
          ces_props <- calculate_all_weight_proportions(
            survey, race_col, current_year, config, ensure_parties = FALSE
          )
          
          benchmark_pct <- top_cand$Proportion * 100
          
          ces_unwt <- ces_props$unweighted[match_result$matched_ces] * 100
          ces_wt   <- ces_props$ces_weight[match_result$matched_ces] * 100
          
          anes_full <- ces_props$anes_full[match_result$matched_ces] * 100
          anes_res  <- ces_props$anes_restricted[match_result$matched_ces] * 100
          
          # ---- Variable metadata (NOW TWO VALIDITY FLAGS) ----
          var_metadata <- determine_variable_metadata(
            race_col, current_year, config
          )
          
          district_display <- if (district %in% c("statewide", "nationwide")) {
            district
          } else {
            paste0("District ", district)
          }
          
          year_results <- bind_rows(
            year_results,
            tibble(
              Year     = current_year,
              State    = state,
              Class    = "Candidate Choice",
              Variable = office_label,
              District = district_display,
              Category = ces_party,
              
              # ---- Variable classification ----
              Variable_Type = var_metadata$variable_type,
              
              Used_in_ANESRake_Full       = var_metadata$used_in_anesrake_full,
              Used_in_ANESRake_Restricted = var_metadata$used_in_anesrake_restricted,
              
              Valid_for_Accuracy_Full       = var_metadata$valid_for_accuracy_full,
              Valid_for_Accuracy_Restricted = var_metadata$valid_for_accuracy_restricted,
              
              # ---- Matching diagnostics ----
              CES_Candidate  = str_to_title(match_result$matched_ces),
              True_Candidate = str_to_title(top_cand$Candidate),
              Match_Score    = match_result$score,
              
              Benchmark = benchmark_pct,
              
              # ---- Estimates ----
              CES_Unweighted             = ces_unwt,
              CES_Weighted               = ces_wt,
              CES_ANESRake_Full           = anes_full,
              CES_ANESRake_Restricted     = anes_res,
              
              # ---- Errors (CES − Benchmark) ----
              Error_Unweighted            = ces_unwt - benchmark_pct,
              Error_CES_Weighted          = ces_wt   - benchmark_pct,
              Error_ANESRake_Full         = anes_full - benchmark_pct,
              Error_ANESRake_Restricted   = anes_res  - benchmark_pct,
              
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
# 
# calculate_candidate_errors <- function(year_data_list, candidate_returns_df, config) {
#   
#   race_map <- config$race_maps$candidate
#   result_list <- list()
#   
#   pb <- progress_bar$new(
#     format = "Candidate-level [:year] [:bar] :percent eta: :eta",
#     total = length(year_data_list), clear = FALSE, width = 60
#   )
#   
#   for (year_data in year_data_list) {
#     pb$tick(tokens = list(year = year_data$year))
#     current_year <- year_data$year
#     
#     # Skip years without candidate data
#     if (current_year %in% c("2006", "2008")) next
#     
#     ces_df <- year_data$CES
#     ces_cols <- intersect(names(ces_df), names(race_map))
#     year_results <- tibble()
#     
#     for (race_col in ces_cols) {
#       ces_filtered <- filter_nc_if_needed(ces_df, current_year, race_col, config$NC_flag_df)
#       office_label <- race_map[[race_col]]
#       
#       for (state in unique(na.omit(ces_filtered$POST_STATE_rc))) {
#         
#         # Debug helper line
#         # if (current_year == 2016 && state == "LOUISIANA" && office_label == "US Senate") {
#         #   browser()
#         # }
#         
#         if (should_skip_race(state, current_year, race_col, config$skip_conditions)) {
#           next
#         }
#         
#         state_df <- ces_filtered %>% filter(POST_STATE_rc == state)
#         districts <- get_districts_for_office(office_label, state_df)
#         
#         for (district in districts) {
#           
#           survey <- filter_by_district(state_df, office_label, district)
#           n_resp <- sum(!is.na(survey[[race_col]]))
#           if (n_resp == 0) next
#           
#           # Get benchmark candidate
#           top_cand <- get_top_candidate(
#             candidate_returns_df, current_year, state, office_label, district
#           )
#           if (is.null(top_cand)) next
#           
#           # Fuzzy match
#           match_result <- match_candidate_fuzzy(survey, race_col, top_cand$Candidate)
#           
#           # Find party
#           ces_party <- get_candidate_party(survey, race_col, match_result$matched_ces)
#           
#           # Calculate proportions
#           ces_props <- calculate_all_weight_proportions(
#             survey, race_col, current_year, config, ensure_parties = FALSE
#           )
#           
#           # Extract values for matched candidate
#           benchmark_pct <- top_cand$Proportion * 100
#           ces_unwt  <- ces_props$unweighted[match_result$matched_ces] * 100
#           ces_wt    <- ces_props$ces_weight[match_result$matched_ces] * 100
#           anes_wt   <- ces_props$anes_weight[match_result$matched_ces] * 100
#           
#           # Determine variable metadata (using raw variable name)
#           var_metadata <- determine_variable_metadata(race_col, current_year, config)
#           
#           # Format district for display
#           district_display <- if (district %in% c("statewide", "nationwide")) {
#             district
#           } else {
#             paste0("District ", district)
#           }
#           
#           year_results <- bind_rows(
#             year_results,
#             tibble(
#               Year          = current_year,
#               State         = state,
#               Class         = "Candidate Choice",
#               Variable      = office_label,
#               District      = district_display,
#               Category      = ces_party,
#               
#               # Variable type tracking
#               Variable_Type = var_metadata$variable_type,
#               Used_in_ANESRake_Weighting = var_metadata$used_in_anesrake_weighting,
#               Valid_for_Accuracy = var_metadata$valid_for_accuracy,
#               
#               CES_Candidate    = str_to_title(match_result$matched_ces),
#               True_Candidate   = str_to_title(top_cand$Candidate),
#               Match_Score      = match_result$score,
#               
#               Benchmark        = benchmark_pct,
#               
#               CES_Unweighted        = ces_unwt,
#               CES_Weighted          = ces_wt,
#               CES_ANESRake_Weighted = anes_wt,
#               
#               # Consistent convention: CES - Benchmark
#               Error_Unweighted   = ces_unwt - benchmark_pct,
#               Error_CES_Weighted = ces_wt - benchmark_pct,
#               Error_ANESRake     = anes_wt - benchmark_pct,
#               
#               n_respondents = n_resp
#             )
#           )
#         }
#       }
#     }
#     
#     result_list[[as.character(current_year)]] <- year_results
#   }
#   
#   bind_rows(result_list)
# }


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
  
  library(progress)
  
  comparison_vars <- extract_comparison_vars(all_targets)
  message("Auto-extracted ", length(comparison_vars), " comparison variables from all_targets:")
  message(paste(" -", comparison_vars, collapse = "\n"))
  
  # ------------------------------------------------------------
  # Progress bar setup (year × state × variable)
  # ------------------------------------------------------------
  total_steps <- 0
  for (yd in year_data_list) {
    states <- unique(na.omit(yd$CES$POST_STATE_rc))
    total_steps <- total_steps + length(states) * length(comparison_vars)
  }
  
  pb <- progress_bar$new(
    format = "Demographic/Voting Admin accuracy [:bar] :percent | Year :year | State :state | Var :var",
    total  = total_steps,
    clear  = FALSE,
    width  = 60
  )
  
  all_results <- list()
  
  for (year_data in year_data_list) {
    year   <- year_data$year
    ces_df <- year_data$CES
    cps_df <- year_data$CPS
    
    wt_vars <- config$weight_vars[[as.character(year)]]
    
    # ============================================================
    # Special handling for POST_STATE_rc (national distribution)
    # ============================================================
    if ("POST_STATE_rc" %in% comparison_vars && "POST_STATE_rc" %in% names(ces_df)) {
      
      if (missing(state_populations) || is.null(state_populations)) {
        stop("state_populations is REQUIRED for POST_STATE_rc accuracy calculation.")
      }
      
      ces_states <- unique(na.omit(ces_df$POST_STATE_rc))
      
      ces_unwt_shares <- prop.table(table(factor(ces_df$POST_STATE_rc, levels = ces_states)))
      ces_wt_shares   <- weighted_prop_zero(
        ces_df$POST_STATE_rc, ces_df[[wt_vars[1]]], levels = ces_states
      )
      
      anes_full_shares <- weighted_prop_zero(
        ces_df$POST_STATE_rc, ces_df$anesrake_weight_full, levels = ces_states
      )
      anes_res_shares  <- weighted_prop_zero(
        ces_df$POST_STATE_rc, ces_df$anesrake_weight_restricted, levels = ces_states
      )
      
      var_metadata <- determine_variable_metadata("POST_STATE_rc", year, config)
      
      for (state in ces_states) {
        state_pop_row <- state_populations %>% filter(State == state, Year == year)
        if (nrow(state_pop_row) == 0) {
          stop(glue::glue("No state population data found for {state} in {year}."))
        }
        
        true_pop_share <- state_pop_row$Population_Share
        
        all_results[[length(all_results) + 1]] <- tibble(
          Year     = year,
          State    = state,
          Class    = "Demographic",
          Variable = "POST_STATE_rc",
          Category = state,
          
          Variable_Type = var_metadata$variable_type,
          Used_in_ANESRake_Full       = var_metadata$used_in_anesrake_full,
          Used_in_ANESRake_Restricted = var_metadata$used_in_anesrake_restricted,
          Valid_for_Accuracy_Full       = var_metadata$valid_for_accuracy_full,
          Valid_for_Accuracy_Restricted = var_metadata$valid_for_accuracy_restricted,
          
          Benchmark = true_pop_share * 100,
          
          CES_Unweighted          = ces_unwt_shares[state] * 100,
          CES_Weighted            = ces_wt_shares[state] * 100,
          CES_ANESRake_Full       = anes_full_shares[state] * 100,
          CES_ANESRake_Restricted = anes_res_shares[state] * 100,
          
          Error_Unweighted          = (ces_unwt_shares[state] - true_pop_share) * 100,
          Error_CES_Weighted        = (ces_wt_shares[state]   - true_pop_share) * 100,
          Error_ANESRake_Full       = (anes_full_shares[state] - true_pop_share) * 100,
          Error_ANESRake_Restricted = (anes_res_shares[state]  - true_pop_share) * 100,
          
          n_respondents = sum(ces_df$POST_STATE_rc == state, na.rm = TRUE)
        )
      }
    }
    
    # ============================================================
    # State-level comparisons
    # ============================================================
    for (state in unique(na.omit(ces_df$POST_STATE_rc))) {
      ces_state <- filter(ces_df, POST_STATE_rc == state)
      cps_state <- filter(cps_df, POST_STATE_rc == state)
      
      for (demo_var in comparison_vars) {
        
        pb$tick(tokens = list(year = year, state = state, var = demo_var))
        
        if (demo_var == "POST_STATE_rc") next
        if (!(demo_var %in% names(ces_state)) || !(demo_var %in% names(cps_state))) next
        if (year == 2006 && state == "DISTRICT OF COLUMBIA" && demo_var == "VOTEHOW_rc") next
        
        # ============================================================
        # Turnout: VOTED_rc
        # ============================================================
        if (demo_var == "VOTED_rc") {
          
          if (state == "DISTRICT OF COLUMBIA") next
          if (is.null(turnout_statewide)) stop("turnout_statewide required.")
          
          state_turnout_prop <- turnout_statewide %>%
            filter(State == state) %>%
            pull(as.character(year)) %>%
            as.numeric()
          
          categories <- c("Voted", "Did not vote")
          
          ces_unwt <- prop.table(table(factor(ces_state[[demo_var]], levels = categories)))
          ces_wt   <- weighted_prop_zero(ces_state[[demo_var]], ces_state[[wt_vars[1]]], categories)
          anes_full <- weighted_prop_zero(ces_state[[demo_var]], ces_state$anesrake_weight_full, categories)
          anes_res  <- weighted_prop_zero(ces_state[[demo_var]], ces_state$anesrake_weight_restricted, categories)
          
          var_metadata <- determine_variable_metadata(demo_var, year, config)
          
          for (cat in categories) {
            benchmark <- if (cat == "Voted") state_turnout_prop else (1 - state_turnout_prop)
            
            all_results[[length(all_results) + 1]] <- tibble(
              Year     = year,
              State    = state,
              Class    = "Voting Administration",
              Variable = demo_var,
              Category = cat,
              
              Variable_Type = var_metadata$variable_type,
              Used_in_ANESRake_Full       = var_metadata$used_in_anesrake_full,
              Used_in_ANESRake_Restricted = var_metadata$used_in_anesrake_restricted,
              Valid_for_Accuracy_Full       = var_metadata$valid_for_accuracy_full,
              Valid_for_Accuracy_Restricted = var_metadata$valid_for_accuracy_restricted,
              
              Benchmark = benchmark * 100,
              
              CES_Unweighted          = ces_unwt[cat] * 100,
              CES_Weighted            = ces_wt[cat] * 100,
              CES_ANESRake_Full       = anes_full[cat] * 100,
              CES_ANESRake_Restricted = anes_res[cat] * 100,
              
              Error_Unweighted          = (ces_unwt[cat] - benchmark) * 100,
              Error_CES_Weighted        = (ces_wt[cat]   - benchmark) * 100,
              Error_ANESRake_Full       = (anes_full[cat] - benchmark) * 100,
              Error_ANESRake_Restricted = (anes_res[cat]  - benchmark) * 100,
              
              n_respondents = sum(!is.na(ces_state[[demo_var]]))
            )
          }
          
        } else {
          # ============================================================
          # CPS benchmark variables
          # ============================================================
          categories <- sort(unique(c(ces_state[[demo_var]], cps_state[[demo_var]])))
          categories <- categories[!is.na(categories)]
          
          cps_props <- prop.table(table(factor(cps_state[[demo_var]], levels = categories)))
          
          ces_unwt <- prop.table(table(factor(ces_state[[demo_var]], levels = categories)))
          ces_wt   <- weighted_prop_zero(ces_state[[demo_var]], ces_state[[wt_vars[1]]], categories)
          anes_full <- weighted_prop_zero(ces_state[[demo_var]], ces_state$anesrake_weight_full, categories)
          anes_res  <- weighted_prop_zero(ces_state[[demo_var]], ces_state$anesrake_weight_restricted, categories)
          
          var_metadata <- determine_variable_metadata(demo_var, year, config)
          
          for (cat in categories) {
            benchmark <- cps_props[cat]
            
            all_results[[length(all_results) + 1]] <- tibble(
              Year     = year,
              State    = state,
              Class    = if_else(demo_var %in% c("VOTED_rc","VOTEHOW_rc","VOTEREG_rc"),
                                 "Voting Administration", "Demographic"),
              Variable = demo_var,
              Category = cat,
              
              Variable_Type = var_metadata$variable_type,
              Used_in_ANESRake_Full       = var_metadata$used_in_anesrake_full,
              Used_in_ANESRake_Restricted = var_metadata$used_in_anesrake_restricted,
              Valid_for_Accuracy_Full       = var_metadata$valid_for_accuracy_full,
              Valid_for_Accuracy_Restricted = var_metadata$valid_for_accuracy_restricted,
              
              Benchmark = benchmark * 100,
              
              CES_Unweighted          = ces_unwt[cat] * 100,
              CES_Weighted            = ces_wt[cat] * 100,
              CES_ANESRake_Full       = anes_full[cat] * 100,
              CES_ANESRake_Restricted = anes_res[cat] * 100,
              
              Error_Unweighted          = (ces_unwt[cat] - benchmark) * 100,
              Error_CES_Weighted        = (ces_wt[cat]   - benchmark) * 100,
              Error_ANESRake_Full       = (anes_full[cat] - benchmark) * 100,
              Error_ANESRake_Restricted = (anes_res[cat]  - benchmark) * 100,
              
              n_respondents = sum(!is.na(ces_state[[demo_var]]))
            )
          }
        }
      }
    }
  }
  
  bind_rows(all_results)
}


# calculate_demovote_errors <- function(year_data_list,
#                                       all_targets,
#                                       config,
#                                       turnout_statewide,
#                                       state_populations) {
#   
#   # Auto-extract comparison_vars from all_targets
#   comparison_vars <- extract_comparison_vars(all_targets)
#   message("Auto-extracted ", length(comparison_vars), " comparison variables from all_targets:")
#   message(paste(" -", comparison_vars, collapse = "\n"))
#   
#   all_results <- list()
#   
#   for (year_data in year_data_list) {
#     year <- year_data$year
#     ces_df <- year_data$CES
#     cps_df <- year_data$CPS
#     
#     wt_vars <- config$weight_vars[[as.character(year)]]
#     
#     # Special handling for POST_STATE_rc - process at national level, not by state
#     if ("POST_STATE_rc" %in% comparison_vars && "POST_STATE_rc" %in% names(ces_df)) {
#       
#       # Require state_populations for POST_STATE_rc
#       if (missing(state_populations) || is.null(state_populations)) {
#         stop("state_populations is REQUIRED for POST_STATE_rc accuracy calculation. Please provide the state_populations data frame with columns: State, Year, Population_Share")
#       }
#       
#       # Get all states in CES for this year
#       ces_states <- unique(na.omit(ces_df$POST_STATE_rc))
#       
#       # Calculate CES state shares (proportion of national sample in each state)
#       ces_unwt_shares <- prop.table(table(factor(ces_df$POST_STATE_rc, levels = ces_states)))
#       ces_wt_shares <- weighted_prop_zero(ces_df$POST_STATE_rc, ces_df[[wt_vars[1]]], levels = ces_states)
#       anes_wt_shares <- weighted_prop_zero(ces_df$POST_STATE_rc, ces_df$anesrake_weight, levels = ces_states)
#       
#       # Determine variable metadata
#       var_metadata <- determine_variable_metadata("POST_STATE_rc", year, config)
#       
#       # Create row for each state
#       for (state in ces_states) {
#         
#         # Get true state population share from state_populations
#         state_pop_row <- state_populations %>%
#           filter(State == state, Year == year)
#         
#         if (nrow(state_pop_row) == 0) {
#           stop(glue::glue("No state population data found for {state} in {year}. Check state_populations data."))
#         }
#         
#         true_pop_share <- state_pop_row$Population_Share
#         
#         all_results[[length(all_results) + 1]] <- tibble(
#           Year          = year,
#           State         = state,
#           Class         = "Demographic",
#           Variable      = "POST_STATE_rc",
#           Category      = state,
#           
#           # Variable type tracking
#           Variable_Type = var_metadata$variable_type,
#           Used_in_ANESRake_Weighting = var_metadata$used_in_anesrake_weighting,
#           Valid_for_Accuracy = var_metadata$valid_for_accuracy,
#           
#           Benchmark     = true_pop_share * 100,
#           
#           CES_Unweighted        = as.numeric(ces_unwt_shares[state]) * 100,
#           CES_Weighted          = as.numeric(ces_wt_shares[state]) * 100,
#           CES_ANESRake_Weighted = as.numeric(anes_wt_shares[state]) * 100,
#           
#           # Consistent convention: CES - Benchmark (CES Share - True Pop Share)
#           Error_Unweighted   = (as.numeric(ces_unwt_shares[state]) - true_pop_share) * 100,
#           Error_CES_Weighted = (as.numeric(ces_wt_shares[state]) - true_pop_share) * 100,
#           Error_ANESRake     = (as.numeric(anes_wt_shares[state]) - true_pop_share) * 100,
#           
#           n_respondents = sum(ces_df$POST_STATE_rc == state, na.rm = TRUE)
#         )
#       }
#     }
#     
#     for (state in unique(na.omit(ces_df$POST_STATE_rc))) {
#       ces_state <- filter(ces_df, POST_STATE_rc == state)
#       cps_state <- filter(cps_df, POST_STATE_rc == state)
#       
#       for (demo_var in comparison_vars) {
#         
#         # Skip POST_STATE_rc here - already handled at national level above
#         if (demo_var == "POST_STATE_rc") {
#           next
#         }
#         
#         if (!(demo_var %in% names(ces_state)) || !(demo_var %in% names(cps_state))) {
#           next
#         }
#         
#         # Skip DC for 2006 VOTEHOW_rc (only one respondent)
#         if (year == 2006 && state == "DISTRICT OF COLUMBIA" && demo_var == "VOTEHOW_rc") {
#           next
#         }
#         
#         # Special handling for VOTED_rc (turnout)
#         if (demo_var == "VOTED_rc") {
#           
#           # Skip DC - no official turnout data available
#           if (state == "DISTRICT OF COLUMBIA") {
#             next
#           }
#           
#           # Require turnout_statewide for VOTED_rc
#           if (is.null(turnout_statewide)) {
#             stop("turnout_statewide is required for VOTED_rc accuracy calculation. Please provide the turnout_statewide data frame.")
#           }
#           
#           # Get state turnout from turnout_statewide
#           state_turnout <- turnout_statewide %>%
#             filter(State == state) %>%
#             pull(as.character(year))
#           
#           # Convert to proportion and handle if missing
#           state_turnout_prop <- ifelse(length(state_turnout) > 0,
#                                        as.numeric(state_turnout),
#                                        NA_real_)
#           
#           # Error if no state turnout available for this state/year
#           if (is.na(state_turnout_prop)) {
#             stop(glue::glue("No state turnout data found for {state} in {year}. Check turnout_statewide data."))
#           }
#           
#           # VOTED_rc has exactly two categories: "Voted" and "Did not vote"
#           categories <- c("Voted", "Did not vote")
#           
#           # CES proportions for both categories
#           ces_unwt <- prop.table(table(factor(ces_state[[demo_var]], levels = categories)))
#           ces_wt   <- weighted_prop_zero(ces_state[[demo_var]], ces_state[[wt_vars[1]]], levels = categories)
#           anes_wt  <- weighted_prop_zero(ces_state[[demo_var]], ces_state$anesrake_weight, levels = categories)
#           
#           # Determine variable metadata
#           var_metadata <- determine_variable_metadata(demo_var, year, config)
#           
#           # Row for "Voted" category (benchmark = state turnout rate)
#           all_results[[length(all_results) + 1]] <- tibble(
#             Year          = year,
#             State         = state,
#             Class         = "Voting",
#             Variable      = demo_var,
#             Category      = "Voted",
#             
#             Variable_Type = var_metadata$variable_type,
#             Used_in_ANESRake_Weighting = var_metadata$used_in_anesrake_weighting,
#             Valid_for_Accuracy = var_metadata$valid_for_accuracy,
#             
#             Benchmark     = state_turnout_prop * 100,
#             
#             CES_Unweighted        = as.numeric(ces_unwt["Voted"]) * 100,
#             CES_Weighted          = as.numeric(ces_wt["Voted"]) * 100,
#             CES_ANESRake_Weighted = as.numeric(anes_wt["Voted"]) * 100,
#             
#             Error_Unweighted   = (as.numeric(ces_unwt["Voted"]) * 100) - (state_turnout_prop * 100),
#             Error_CES_Weighted = (as.numeric(ces_wt["Voted"]) * 100) - (state_turnout_prop * 100),
#             Error_ANESRake     = (as.numeric(anes_wt["Voted"]) * 100) - (state_turnout_prop * 100),
#             
#             n_respondents = sum(!is.na(ces_state[[demo_var]]))
#           )
#           
#           # Row for "Did not vote" category (benchmark = 1 - turnout rate)
#           all_results[[length(all_results) + 1]] <- tibble(
#             Year          = year,
#             State         = state,
#             Class         = "Voting",
#             Variable      = demo_var,
#             Category      = "Did not vote",
#             
#             Variable_Type = var_metadata$variable_type,
#             Used_in_ANESRake_Weighting = var_metadata$used_in_anesrake_weighting,
#             Valid_for_Accuracy = var_metadata$valid_for_accuracy,
#             
#             Benchmark     = (1 - state_turnout_prop) * 100,
#             
#             CES_Unweighted        = as.numeric(ces_unwt["Did not vote"]) * 100,
#             CES_Weighted          = as.numeric(ces_wt["Did not vote"]) * 100,
#             CES_ANESRake_Weighted = as.numeric(anes_wt["Did not vote"]) * 100,
#             
#             Error_Unweighted   = (as.numeric(ces_unwt["Did not vote"]) * 100) - ((1 - state_turnout_prop) * 100),
#             Error_CES_Weighted = (as.numeric(ces_wt["Did not vote"]) * 100) - ((1 - state_turnout_prop) * 100),
#             Error_ANESRake     = (as.numeric(anes_wt["Did not vote"]) * 100) - ((1 - state_turnout_prop) * 100),
#             
#             n_respondents = sum(!is.na(ces_state[[demo_var]]))
#           )
#           
#         } else {
#           # Standard handling for all other variables (use CPS as benchmark)
#           
#           # Harmonize levels
#           categories <- sort(unique(c(ces_state[[demo_var]], cps_state[[demo_var]])))
#           categories <- categories[!is.na(categories)]
#           
#           # CPS benchmark proportions
#           cps_props <- prop.table(table(factor(cps_state[[demo_var]], levels = categories)))
#           
#           # CES proportions (all weighting schemes)
#           ces_unwt <- prop.table(table(factor(ces_state[[demo_var]], levels = categories)))
#           ces_wt   <- weighted_prop_zero(ces_state[[demo_var]], ces_state[[wt_vars[1]]], levels = categories)
#           anes_wt  <- weighted_prop_zero(ces_state[[demo_var]], ces_state$anesrake_weight, levels = categories)
#           
#           # Determine variable metadata (using raw variable name)
#           var_metadata <- determine_variable_metadata(demo_var, year, config)
#           
#           # Create row for each category
#           for (cat in categories) {
#             all_results[[length(all_results) + 1]] <- tibble(
#               Year          = year,
#               State         = state,
#               Class         = if_else(demo_var %in% c("VOTED_rc", "VOTEHOW_rc", "VOTEREG_rc"), "Voting", "Demographic"),
#               Variable      = demo_var,
#               Category      = cat,
#               
#               # Variable type tracking
#               Variable_Type = var_metadata$variable_type,
#               Used_in_ANESRake_Weighting = var_metadata$used_in_anesrake_weighting,
#               Valid_for_Accuracy = var_metadata$valid_for_accuracy,
#               
#               Benchmark     = as.numeric(cps_props[cat]) * 100,
#               
#               CES_Unweighted        = as.numeric(ces_unwt[cat]) * 100,
#               CES_Weighted          = as.numeric(ces_wt[cat]) * 100,
#               CES_ANESRake_Weighted = as.numeric(anes_wt[cat]) * 100,
#               
#               # Consistent convention: CES - Benchmark (CES - CPS)
#               Error_Unweighted   = (as.numeric(ces_unwt[cat]) - as.numeric(cps_props[cat])) * 100,
#               Error_CES_Weighted = (as.numeric(ces_wt[cat]) - as.numeric(cps_props[cat])) * 100,
#               Error_ANESRake     = (as.numeric(anes_wt[cat]) - as.numeric(cps_props[cat])) * 100,
#               
#               n_respondents = sum(!is.na(ces_state[[demo_var]]))
#             )
#           }
#         }
#       }
#     }
#   }
#   
#   bind_rows(all_results)
# }


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
        Weighting_Method == "Error_Unweighted"   ~ "CES-Unweighted",
        Weighting_Method == "Error_CES_Weighted" ~ "CES-Provided Weights",
        Weighting_Method == "Error_ANESRake"     ~ "ANESRake",
        Weighting_Method == "Error_ANESRake_Full"       ~ "ANESRake-Full",
        Weighting_Method == "Error_ANESRake_Restricted" ~ "ANESRake-Restricted",
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
      "VOTERES_rc"       = "Residence Duration",
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
#' Also determines if variable is "Valid for Accuracy Assessment":
#' - Must be Secondary (not used in CES weighting) AND
#' - Must NOT be used in ANESRake weighting
#'
#' Only variables that are valid for accuracy assessment provide unbiased
#' measures of survey accuracy, since they weren't used to calibrate either
#' weighting scheme.
#'
#' @param var_name Variable name (raw CES variable name like "SEX_rc")
#' @param year Year as character
#' @param config Configuration object
#'
#' @return List with variable_type, used_in_anesrake_weighting, and valid_for_accuracy
#' @keywords internal

# determine_variable_metadata <- function(var_name, year, config) {
#   
#   # Default values
#   variable_type <- "Secondary"
#   used_in_anesrake <- FALSE
#   
#   # Check if used in CES weights
#   if (!is.null(config$vars_used_ces_weights)) {
#     ces_vars <- config$vars_used_ces_weights[[as.character(year)]]
#     if (!is.null(ces_vars) && var_name %in% ces_vars) {
#       variable_type <- "Primary"
#     }
#   }
#   
#   # Check if used in ANESRake
#   if (!is.null(config$anesrake_results)) {
#     anes_vars <- config$anesrake_results[[as.character(year)]]$vars_used
#     if (!is.null(anes_vars) && var_name %in% anes_vars) {
#       used_in_anesrake <- TRUE
#     }
#   }
#   
#   # Valid for accuracy: Secondary AND not used in ANESRake
#   valid_for_accuracy <- (variable_type == "Secondary") && (!used_in_anesrake)
#   
#   list(
#     variable_type = variable_type,
#     used_in_anesrake_weighting = used_in_anesrake,
#     valid_for_accuracy = valid_for_accuracy
#   )
# }

determine_variable_metadata <- function(var_name, year, config) {
  
  year_chr <- as.character(year)
  
  # -----------------------------
  # Used in CES weights?
  # -----------------------------
  variable_type <- "Secondary"
  ces_vars <- config$vars_used_ces_weights[[year_chr]]
  used_in_ces <- !is.null(ces_vars) && (var_name %in% ces_vars)
  if (used_in_ces) variable_type <- "Primary"
  
  # -----------------------------
  # Used in ANESRake FULL? (empirical)
  # -----------------------------
  used_in_anes_full <- FALSE
  full_res <- config$anesrake$full$results[[year_chr]]
  if (!is.null(full_res$vars_used) && var_name %in% full_res$vars_used) {
    used_in_anes_full <- TRUE
  }
  
  # -----------------------------
  # Used in ANESRake RESTRICTED? (design-based)
  # -----------------------------
  used_in_anes_restricted <- var_name %in% config$anesrake$restricted$vars_used
  
  # -----------------------------
  # Validity flags (scheme-specific)
  # -----------------------------
  valid_full <-
    (variable_type == "Secondary") && (!used_in_anes_full)
  
  valid_restricted <-
    (variable_type == "Secondary") && (!used_in_anes_restricted)
  
  list(
    variable_type = variable_type,
    
    used_in_ces_weighting = used_in_ces,
    used_in_anesrake_full = used_in_anes_full,
    used_in_anesrake_restricted = used_in_anes_restricted,
    
    valid_for_accuracy_full = valid_full,
    valid_for_accuracy_restricted = valid_restricted
  )
}



#' Filter NC cases if needed
#' @keywords internal
filter_nc_if_needed <- function(ces_df, year, race_col, NC_flag_df) {
  if (year == 2020 && race_col %in% c("HOUSE_PARTY_rc", "HOUSE_CANDIDATE_rc")) {
    n_before <- nrow(ces_df)
    ces_filtered <- ces_df %>% filter(!(caseid %in% NC_flag_df$caseid))
    n_after <- nrow(ces_filtered)
    n_removed <- n_before - n_after
    
    # Ensure we actually filtered out respondents
    if (n_removed == 0) {
      stop(glue::glue("NC filter should have removed respondents for {race_col} in 2020, but removed 0. Check NC_flag_df."))
    }
    
    message(glue::glue("Filtered {n_removed} NC respondents with incorrect districts for {race_col}"))
    return(ces_filtered)
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
#' Calculate proportions under all weighting schemes
#' @keywords internal
calculate_all_weight_proportions <- function(survey_df,
                                             var_col,
                                             year,
                                             config,
                                             ensure_parties = FALSE) {
  
  year_chr <- as.character(year)
  
  # CES weight
  ces_wt_var <- config$weight_vars[[year_chr]][1]
  
  # ANESRake weight columns
  anes_full_col <- "anesrake_weight_full"
  anes_restr_col <- "anesrake_weight_restricted"
  
  # -----------------------------
  # Compute proportions
  # -----------------------------
  unweighted <- wpct(survey_df[[var_col]], na.rm = TRUE)
  
  ces_weight <- wpct(survey_df[[var_col]], weight = survey_df[[ces_wt_var]], na.rm = TRUE)
  
  anes_full <- wpct(survey_df[[var_col]], weight = survey_df[[anes_full_col]], na.rm = TRUE)
  
  anes_restricted <- wpct(survey_df[[var_col]], weight = survey_df[[anes_restr_col]], na.rm = TRUE)
  
  # -----------------------------
  # Optional party completion
  # -----------------------------
  if (ensure_parties) {
    for (lvl in config$standard_parties) {
      if (lvl %notin% names(unweighted))        unweighted[lvl]        <- 0
      if (lvl %notin% names(ces_weight))        ces_weight[lvl]        <- 0
      if (lvl %notin% names(anes_full))         anes_full[lvl]         <- 0
      if (lvl %notin% names(anes_restricted))   anes_restricted[lvl]   <- 0
    }
    
    unweighted        <- unweighted[config$standard_parties]
    ces_weight        <- ces_weight[config$standard_parties]
    anes_full         <- anes_full[config$standard_parties]
    anes_restricted   <- anes_restricted[config$standard_parties]
  }
  
  # -----------------------------
  # Return structured output
  # -----------------------------
  list(
    unweighted        = unweighted,
    ces_weight        = ces_weight,
    anes_full         = anes_full,
    anes_restricted   = anes_restricted
  )
}

# calculate_all_weight_proportions <- function(survey_df, var_col, year, config, ensure_parties = FALSE) {
#   
#   wt_var <- config$weight_vars[[as.character(year)]][1]
#   
#   unweighted  <- wpct(survey_df[[var_col]], na.rm = TRUE)
#   ces_weight  <- wpct(survey_df[[var_col]], weight = survey_df[[wt_var]], na.rm = TRUE)
#   anes_weight <- wpct(survey_df[[var_col]], weight = survey_df$anesrake_weight, na.rm = TRUE)
#   
#   if (ensure_parties) {
#     # Ensure all three parties exist with 0 if missing
#     for (lvl in config$standard_parties) {
#       if (lvl %notin% names(unweighted))  unweighted[lvl]  <- 0
#       if (lvl %notin% names(ces_weight))  ces_weight[lvl]  <- 0
#       if (lvl %notin% names(anes_weight)) anes_weight[lvl] <- 0
#     }
#     unweighted  <- unweighted[config$standard_parties]
#     ces_weight  <- ces_weight[config$standard_parties]
#     anes_weight <- anes_weight[config$standard_parties]
#   }
#   
#   list(
#     unweighted  = unweighted,
#     ces_weight  = ces_weight,
#     anes_weight = anes_weight
#   )
# }

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
    # Special case: 2016 Louisiana Senate (John Kennedy not listed in CES)
  } else if (year == 2016 && office == "US Senate" && state == "LOUISIANA") {
    returns %>% filter(Candidate == "FOSTER CAMPBELL")
    # Special case: 2018 North Dakota Secretary of State
    # Al Jaeger (Republican incumbent) dropped out and ran as an independent
    # Joshua Boschee was the Democratic candidate who received the most votes among major party candidates
  } else if (year == 2018 && office == "Secretary of State" && state == "NORTH DAKOTA") {
    returns %>% filter(Candidate == "Joshua A. Boschee")
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

#' Check if state/year/variable combination should be skipped for demovote
#' @keywords internal
should_skip_demovote <- function(state, year, var_name) {
  
  # DC has only 1 respondent for voting method in 2006
  if (state == "DISTRICT OF COLUMBIA" && year == 2006 && var_name == "VOTEHOW_rc") {
    return(TRUE)
  }
  
  return(FALSE)
}

