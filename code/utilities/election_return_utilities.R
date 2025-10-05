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
  
  # Rename columns for simplicity
  df <- df %>%
    rename(
      State = `State (full name)`,
      ElectionDate = `Election date`,
      OfficeDistrict = `Office/district`,
      OfficeNumber = `Office number for sorting`,
      CandidateName = `Candidate name\r\r\n(Copy and paste from source)`,
      PoliticalParty = `Political party`,
      CandidateVotes = `Votes  candidate`,
      TotalVotesInRace = `Total votes in race (if included in the source)`,
      SourceURL = `Source url`,
      SpecialElection = `Special election`
    )
  
  # 1. Create a new Year column
  df <- df %>%
    mutate(Year = format(as.Date(ElectionDate), "%Y"),
           State = toupper(State))
  
  # 2. Identify and classify the political party
  df <- df %>%
    mutate(
      PartyDetailed = PoliticalParty,
      PartySimplified = case_when(
        str_detect(tolower(PoliticalParty), "dem") & !str_detect(tolower(PoliticalParty), "democracy") ~ "Democratic",
        str_detect(tolower(PoliticalParty), "rep") & !str_detect(tolower(PoliticalParty), "representation|repeal") ~ "Republican",
        TRUE ~ "Other"
      )
    )
  
  # 3. Identify main party for each candidate
  df <- df %>%
    group_by(Year, State, OfficeDistrict, OfficeNumber, CandidateName) %>%
    mutate(
      PrimaryParty = case_when(
        (any(PartySimplified == "Democratic") & any(PartySimplified == "Republican")) ~ "Both",
        any(PartySimplified == "Democratic") ~ "Democratic",
        any(PartySimplified == "Republican") ~ "Republican",
        TRUE ~ "Other"
      )
    ) %>%
    ungroup()
  
  # Summarize Total Votes in each State-Year combination
  df <- df %>%
    group_by(State, Year) %>% 
    mutate(TotalVotesInState = sum(CandidateVotes, na.rm = TRUE)) %>% ungroup()
  
  statewise_results <- df %>%
    group_by(State, Year, PrimaryParty) %>%
    summarise(
      PrimaryPartyVotes = sum(CandidateVotes, na.rm = TRUE),
      TotalVotesInState = first(TotalVotesInState),
      .groups = 'drop' 
    ) %>%
    mutate(Proportion = PrimaryPartyVotes / TotalVotesInState) %>% 
    ungroup()
  
  final_df <- statewise_results %>%
    mutate(
      District = "statewide",
      Cand_Num = case_when(
        PrimaryParty == "Democratic" ~ 1,
        PrimaryParty == "Republican" ~ 2,
        TRUE ~ NA
      ),
      Candidate = case_when(
        PrimaryParty == "Democratic" ~ "Democratic Candidates",
        PrimaryParty == "Republican" ~ "Republican Candidates",
        TRUE ~ "Various Candidates"
      ),
      Party_Simplified = case_when(
        PrimaryParty == "Democratic" ~ "DEM",
        PrimaryParty == "Republican" ~ "REP",
        TRUE ~ "OTHER"
      )
    ) %>%
    rename( 
      Party_Detailed = PrimaryParty,
      `Total Votes` = TotalVotesInState,
    )
  
  return_df <- final_df %>%
    rename(
      Total_Votes = `Total Votes`
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
  
}


## For candidate-level AG and SecState from BallotPedia
candidate_level_BP_statewide_offices <- function(df) {
  library(dplyr)
  library(lubridate)
  library(stringr)
  
  # Step 1: Standardize column names
  df_clean <- df %>%
    rename(
      State = `State (full name)`,
      Election_Date = `Election date`,
      Office = `Office/district`,
      Office_Number = `Office number for sorting`,
      Candidate = `Candidate name\r\r\n(Copy and paste from source)`,
      Party_Detailed = `Political party`,
      Candidate_Votes = `Votes  candidate`,
      TotalVotesInRace = `Total votes in race (if included in the source)`,
      SourceURL = `Source url`,
      SpecialElection = `Special election`
    ) %>%
    mutate(
      Year = year(Election_Date),
      District = "statewide",
      Party_Simplified = case_when(
        str_detect(tolower(Party_Detailed), "republican") ~ "Republican",
        str_detect(tolower(Party_Detailed), "democratic") ~ "Democrat",
        TRUE ~ Party_Detailed  # leave unchanged if not matched
      )
    )
  
  # Step 2: Sum votes by candidate (some names may appear under multiple parties)
  summed <- df_clean %>%
    group_by(Year, State, Office, District, Candidate) %>%
    summarise(
      Candidate_Votes = sum(Candidate_Votes, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Step 3: Get party with most votes for each candidate, in case of multiple parties
  top_party <- df_clean %>%
    group_by(Year, State, Office, District, Candidate) %>%
    slice_max(Candidate_Votes, n = 1, with_ties = FALSE) %>%
    select(
      Year, State, Office, District, Candidate,
      Party_Detailed, Party_Simplified
    )
  
  # Step 4: Compute total votes per race
  total_votes <- summed %>%
    group_by(Year, State, Office, District) %>%
    summarise(Total_Votes = sum(Candidate_Votes, na.rm = TRUE), .groups = "drop")
  
  # Step 5: Combine everything
  cleaned <- summed %>%
    left_join(top_party, by = c("Year", "State", "Office", "District", "Candidate")) %>%
    left_join(total_votes, by = c("Year", "State", "Office", "District")) %>%
    mutate(Proportion = Candidate_Votes / Total_Votes) %>%
    select(
      Office, State, District, Year, Candidate,
      Party_Detailed, Party_Simplified,
      Candidate_Votes, Total_Votes, Proportion
    )
  
  return(cleaned)
}


