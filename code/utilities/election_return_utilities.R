## Calculate party/candidate proportions
calculate_state_level_party_proportions <- function(data) {
  major_parties <- c("DEM", "REP")
  
  # Step 1: Determine the main party affiliation for each candidate
  data <- data %>%
    group_by(state, year, candidate) %>%
    mutate(
      main_party = {
        # Check if a candidate is affiliated with both major parties
        if (all(major_parties %in% party_simplified)) {
          stop(paste("Error: Candidate", candidate, "is affiliated with both DEM and REP."))
        } else if (any(party_simplified %in% major_parties)) {
          # If affiliated with a major party, assign the major party
          party_simplified[party_simplified %in% major_parties][1]
        } else {
          # Otherwise, assign as "OTHER"
          "OTHER"
        }
      }
    ) %>%
    ungroup()
  
  # Step 2: Summarize candidate votes by state, year, and main party
  grouped_data <- data %>%
    group_by(state, year, office, main_party) %>%
    summarise(votes = sum(candidatevotes, na.rm = TRUE), .groups = "drop")
  
  # Step 3: Calculate total votes by state, year, office
  total_votes_data <- grouped_data %>%
    group_by(state, year, office) %>%
    summarise(total_votes = sum(votes, na.rm = TRUE), .groups = "drop")
  
  # Step 4: Calculate the proportion of votes for each main party
  proportions <- grouped_data %>%
    left_join(total_votes_data, by = c("state", "year", "office")) %>%
    mutate(proportion = votes / total_votes) %>%
    select(state, year, office, main_party, proportion) %>%
    pivot_wider(names_from = main_party, values_from = proportion, values_fill = list(proportion = 0)) %>%
    # Ensure all required columns are present
    mutate(DEM = ifelse(is.na(DEM), 0, DEM),
           REP = ifelse(is.na(REP), 0, REP),
           OTHER = ifelse(is.na(OTHER), 0, OTHER))
  
  # Step 5: Rename columns to match the specified output format
  output_df <- proportions %>%
    rename(Year = year,
           State = state,
           Office = office,
           DEM_Proportion = DEM,
           REP_Proportion = REP,
           OTHER_Proportion = OTHER) %>%
    arrange(Year, State, Office)
  
  return(output_df)
}

calculate_cand_num_proportions <- function(df) {
  # Step 1: Process candidates with a 'cand_num'
  df_with_number <- df %>%
    filter(!is.na(cand_num)) %>%
    mutate(
      proportion = candidatevotes / totalvotes,
      candidate_name = candidate
    ) %>%
    select(
      office, state, district, year, candidate_name, cand_num, party_detailed, party_simplified, candidatevotes, totalvotes, proportion
    )
  
  # Step 2: Process candidates without a 'cand_num'
  df_without_number <- df %>%
    filter(is.na(cand_num)) %>%
    group_by(year, state, office, district) %>%
    summarise(
      candidatevotes = sum(candidatevotes),
      totalvotes = max(totalvotes),
      candidate_name = "Other Candidates",
      party_detailed = "Various",
      party_simplified = "OTHER",
      cand_num = NA,
      .groups = 'drop'
    ) %>%
    mutate(
      proportion = candidatevotes / totalvotes
    ) %>%
    select(
      office, state, district, year, candidate_name, cand_num, 
      party_detailed, party_simplified, candidatevotes, totalvotes, proportion
    )
  
  # Step 3: Combine both dataframes
  combined_df <- bind_rows(df_with_number, df_without_number) %>%
    arrange(year, state, desc(cand_num), candidate_name)
  
  return(combined_df)
}


## Reclaculate totalvotes
recalculate_total_votes <- function(data, level) {
  
  if (level == "statewide") {
    # Group by state, year, and office
    candidate_votes <- data %>%
      group_by(state, year, office) %>%
      summarise(candidate_votes_total = sum(candidatevotes, na.rm = TRUE), .groups = "drop")
    
    # Join the candidate votes with the original data to update totalvotes
    updated_data <- data %>%
      left_join(candidate_votes, by = c("state", "year", "office")) %>%
      mutate(totalvotes = candidate_votes_total) %>%
      select(-candidate_votes_total)
    
  } else if (level == "district") {
    # Group by state, year, office, and district
    candidate_votes <- data %>%
      group_by(state, year, office, district) %>%
      summarise(candidate_votes_total = sum(candidatevotes, na.rm = TRUE), .groups = "drop")
    
    # Join the candidate votes with the original data to update totalvotes
    updated_data <- data %>%
      left_join(candidate_votes, by = c("state", "year", "office", "district")) %>%
      mutate(totalvotes = candidate_votes_total) %>%
      select(-candidate_votes_total)
    
  } else {
    # Throw an error if the level parameter is incorrect
    stop("Error: Enter either 'statewide' or 'district' for the level parameter")
  }
  
  return(updated_data)
}

assign_president_candidate_numbers <- function(returns_data) {
  returns_data %>%
    mutate(
      cand_num = case_when(
        party_simplified == "DEM" & year %notin% c(2008, 2016) ~ 1,
        party_simplified == "REP" & year %notin% c(2008, 2016) ~ 2,
        party_simplified == "DEM" & year %in% c(2008, 2016) ~ 2,
        party_simplified == "REP" & year %in% c(2008, 2016) ~ 1,
        TRUE ~ NA_real_
      )
    ) %>%
    relocate(cand_num, .after = party_simplified)
}

make_bp_prop_table <- function(df) {
  
  # ------------------------------------------------------------------
  # 1. Basic normalization
  # ------------------------------------------------------------------
  df <- df %>%
    mutate(
      election_date = as.Date(as.POSIXct(election_date, tz = "UTC")),
      Year = format(election_date, "%Y"),
      State = toupper(state)
    )
  
  # ------------------------------------------------------------------
  # 2. Party classification (STRICT: Democrat / Republican / Other)
  # ------------------------------------------------------------------
  df <- df %>%
    mutate(
      Party_Detailed = party_original,
      Party_Simplified = case_when(
        party_simplified == "Democrat"   ~ "Democrat",
        party_simplified == "Republican" ~ "Republican",
        TRUE                             ~ "Other"
      )
    )
  
  # ------------------------------------------------------------------
  # 3. Identify primary party per candidate within race
  # ------------------------------------------------------------------
  df <- df %>%
    group_by(Year, State, office_district, district, candidate) %>%
    mutate(
      PrimaryParty = case_when(
        any(Party_Simplified == "Democrat") & any(Party_Simplified == "Republican") ~ "Both",
        any(Party_Simplified == "Democrat") ~ "Democrat",
        any(Party_Simplified == "Republican") ~ "Republican",
        TRUE ~ "Other"
      )
    ) %>%
    ungroup()
  
  # ------------------------------------------------------------------
  # 4. Compute total votes per State-Year
  # ------------------------------------------------------------------
  df <- df %>%
    group_by(State, Year) %>%
    mutate(TotalVotesInState = sum(votes, na.rm = TRUE)) %>%
    ungroup()
  
  # ------------------------------------------------------------------
  # 5. Aggregate by State-Year-PrimaryParty
  # ------------------------------------------------------------------
  statewise_results <- df %>%
    group_by(State, Year, PrimaryParty) %>%
    summarise(
      PrimaryPartyVotes = sum(votes, na.rm = TRUE),
      TotalVotesInState = first(TotalVotesInState),
      .groups = "drop"
    ) %>%
    mutate(
      Proportion = PrimaryPartyVotes / TotalVotesInState
    )
  
  # ------------------------------------------------------------------
  # 6. Final formatting (matches old output semantics)
  # ------------------------------------------------------------------
  final_df <- statewise_results %>%
    mutate(
      District = "statewide",
      Cand_Num = case_when(
        PrimaryParty == "Democrat"   ~ 1,
        PrimaryParty == "Republican" ~ 2,
        TRUE                         ~ NA_real_
      ),
      Candidate = case_when(
        PrimaryParty == "Democrat"   ~ "Democratic Candidates",
        PrimaryParty == "Republican" ~ "Republican Candidates",
        TRUE                         ~ "Various Candidates"
      ),
      Party_Simplified = case_when(
        PrimaryParty == "Democrat"   ~ "DEM",
        PrimaryParty == "Republican" ~ "REP",
        TRUE                         ~ "OTHER"
      ),
      Party_Detailed = PrimaryParty,
      Total_Votes = TotalVotesInState
    ) %>%
    select(
      State,
      District,
      Year,
      Candidate,
      Cand_Num,
      Party_Detailed,
      Party_Simplified,
      Total_Votes,
      Proportion
    )
  
  return(final_df)
}

candidate_level_BP_statewide_offices <- function(df) {
  
  df_clean <- df %>%
    mutate(
      Year = year(election_date),
      District = "statewide",
      
      Party_Detailed = party_original,
      Party_Simplified = case_when(
        party_simplified == "Democrat"   ~ "Democrat",
        party_simplified == "Republican" ~ "Republican",
        TRUE                             ~ "Other"
      )
    )
  
  # 1. Sum votes by candidate (handles fusion candidates)
  summed <- df_clean %>%
    group_by(Year, state, office, District, candidate) %>%
    summarise(
      Candidate_Votes = sum(votes, na.rm = TRUE),
      .groups = "drop"
    )
  
  # 2. Pick party from row with MOST votes
  top_party <- df_clean %>%
    group_by(Year, state, office, District, candidate) %>%
    slice_max(votes, n = 1, with_ties = FALSE) %>%   # <-- FIX IS HERE
    select(
      Year, state, office, District, candidate,
      Party_Detailed, Party_Simplified
    )
  
  # 3. Compute total votes per race
  total_votes <- summed %>%
    group_by(Year, state, office, District) %>%
    summarise(
      Total_Votes = sum(Candidate_Votes, na.rm = TRUE),
      .groups = "drop"
    )
  
  # 4. Combine everything
  cleaned <- summed %>%
    left_join(top_party,
              by = c("Year", "state", "office", "District", "candidate")) %>%
    left_join(total_votes,
              by = c("Year", "state", "office", "District")) %>%
    mutate(Proportion = Candidate_Votes / Total_Votes) %>%
    rename(
      State = state,
      Office = office,
      Candidate = candidate
    ) %>%
    select(
      Office, State, District, Year, Candidate,
      Party_Detailed, Party_Simplified,
      Candidate_Votes, Total_Votes, Proportion
    )
  
  return(cleaned)
}
