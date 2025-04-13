pre_post_location_vars <- list(
  # Pre and Post same because non provided
  "2006" = list(
    pre_state = "v1002",
    post_state = "v1002"
  ),
  "2008" = list(
    pre_state = "V206",
    post_state = "V259"
  ),
  "2010" = list(
    pre_state = "V206",
    post_state = "V206_post"
  ),
  "2012" = list(
    pre_state = "inputstate",
    post_state = "inputstate_post"
  ),
  "2014" = list(
    pre_state = "inputstate",
    post_state = "inputstate_post"
  ),
  "2016" = list(
    pre_state = "inputstate",
    post_state = "inputstate_post"
  ),
  "2018" = list(
    pre_state = "inputstate",
    post_state = "inputstate_post"
  ),
  "2020" = list(
    pre_state = "inputstate",
    post_state = "inputstate_post"
  ),
  "2022" = list(
    pre_state = "inputstate",
    post_state = "inputstate_post"
  )
)

yrly_ces_house_candidate_names <- list(
  "2006" = list(
    "US House Cand 1 Name" = "v5001",
    "US House Cand 1 Party" = "v5002",
    "US House Cand 2 Name" = "v5003",
    "US House Cand 2 Party" = "v5004"),
  "2012" = list(
    "US House Cand 1 Name" = "HouseCand1Name_post",
    "US House Cand 1 Party" = "HouseCand1Party_post",
    "US House Cand 2 Name" = "HouseCand2Name_post",
    "US House Cand 2 Party" = "HouseCand2Party_post",
    "US House Cand 3 Name" = "HouseCand3Name_post",
    "US House Cand 3 Party" = "HouseCand3Party_post"),
  "2014" = list(
    "US House Cand 1 Name" = "HouseCand1Name_post",
    "US House Cand 1 Party" = "HouseCand1Party_post",
    "US House Cand 2 Name" = "HouseCand2Name_post",
    "US House Cand 2 Party" = "HouseCand2Party_post",
    "US House Cand 3 Name" = "HouseCand3Name_post",
    "US House Cand 3 Party" = "HouseCand3Party_post"),
  "2016" = list(
    "US House Cand 1 Name" = "HouseCand1Name_post",
    "US House Cand 1 Party" = "HouseCand1Party_post",
    "US House Cand 2 Name" = "HouseCand2Name_post",
    "US House Cand 2 Party" = "HouseCand2Party_post",
    "US House Cand 3 Name" = "HouseCand3Name_post",
    "US House Cand 3 Party" = "HouseCand3Party_post",
    "US House Cand 4 Name" = "HouseCand4Name_post",
    "US House Cand 4 Party" = "HouseCand4Party_post",
    "US House Cand 5 Name" = "HouseCand5Name_post",
    "US House Cand 5 Party" = "HouseCand5Party_post",
    "US House Cand 6 Name" = "HouseCand6Name_post",
    "US House Cand 6 Party" = "HouseCand6Party_post",
    "US House Cand 7 Name" = "HouseCand7Name_post",
    "US House Cand 7 Party" = "HouseCand7Party_post",
    "US House Cand 8 Name" = "HouseCand8Name_post",
    "US House Cand 8 Party" = "HouseCand8Party_post",
    "US House Cand 9 Name" = "HouseCand9Name_post",
    "US House Cand 9 Party" = "HouseCand9Party_post",
    "US House Cand 10 Name" = "HouseCand10Name_post",
    "US House Cand 10 Party" = "HouseCand10Party_post",
    "US House Cand 11 Name" = "HouseCand11Name_post",
    "US House Cand 11 Party" = "HouseCand11Party_post"), 
  "2018" = list(
    "US House Cand 1 Name" = "HouseCand1Name_post",
    "US House Cand 1 Party" = "HouseCand1Party_post",
    "US House Cand 2 Name" = "HouseCand2Name_post",
    "US House Cand 2 Party" = "HouseCand2Party_post",
    "US House Cand 3 Name" = "HouseCand3Name_post",
    "US House Cand 3 Party" = "HouseCand3Party_post"),
  "2020" = list(
    "US House Cand 1 Name" = "HouseCand1Name_post",
    "US House Cand 1 Party" = "HouseCand1Party_post",
    "US House Cand 2 Name" = "HouseCand2Name_post",
    "US House Cand 2 Party" = "HouseCand2Party_post",
    "US House Cand 3 Name" = "HouseCand3Name_post",
    "US House Cand 3 Party" = "HouseCand3Party_post",
    "US House Cand 4 Name" = "HouseCand4Name_post",
    "US House Cand 4 Party" = "HouseCand4Party_post",
    "US House Cand 5 Name" = "HouseCand5Name_post",
    "US House Cand 5 Party" = "HouseCand5Party_post",
    "US House Cand 6 Name" = "HouseCand6Name_post",
    "US House Cand 6 Party" = "HouseCand6Party_post",
    "US House Cand 7 Name" = "HouseCand7Name_post",
    "US House Cand 7 Party" = "HouseCand7Party_post",
    "US House Cand 8 Name" = "HouseCand8Name_post",
    "US House Cand 8 Party" = "HouseCand8Party_post",
    "US House Cand 9 Name" = "HouseCand9Name_post",
    "US House Cand 9 Party" = "HouseCand9Party_post"), 
  "2022" = list(
    "US House Cand 1 Name" = "HouseCand1Name_post",
    "US House Cand 1 Party" = "HouseCand1Party_post",
    "US House Cand 2 Name" = "HouseCand2Name_post",
    "US House Cand 2 Party" = "HouseCand2Party_post",
    "US House Cand 3 Name" = "HouseCand3Name_post",
    "US House Cand 3 Party" = "HouseCand3Party_post",
    "US House Cand 4 Name" = "HouseCand4Name_post",
    "US House Cand 4 Party" = "HouseCand4Party_post",
    "US House Cand 5 Name" = "HouseCand5Name_post",
    "US House Cand 5 Party" = "HouseCand5Party_post",
    "US House Cand 6 Name" = "HouseCand6Name_post",
    "US House Cand 6 Party" = "HouseCand6Party_post",
    "US House Cand 7 Name" = "HouseCand7Name_post",
    "US House Cand 7 Party" = "HouseCand7Party_post",
    "US House Cand 8 Name" = "HouseCand8Name_post",
    "US House Cand 8 Party" = "HouseCand8Party_post"
  ))



# Mapping from candidate names/parties to variables
yrly_ces_candidate_names <- list(
  "2006" = list(
    "Governor" = list(
      "Governor Cand 1 Name" = "v5009",
      "Governor Cand 1 Party" = "v5010",
      "Governor Cand 2 Name" = "v5011",
      "Governor Cand 2 Party" = "v5012"
    ),
    
    "US Senate" = list(
      "US Senate Cand 1 Name" = "v5005",
      "US Senate Cand 1 Party" = "v5006",
      "US Senate Cand 2 Name" = "v5007",
      "US Senate Cand 2 Party" = "v5008"
    )
  ),
  
  "2012" = list(
    "Governor" = list(
      "Governor Cand 1 Name" = "GovCand1Name_post",
      "Governor Cand 1 Party" = "GovCand1Party_post",
      "Governor Cand 2 Name" = "GovCand2Name_post",
      "Governor Cand 2 Party" = "GovCand2Party_post"
    ),
    
    "US Senate" = list(
      "US Senate Cand 1 Name" = "SenCand1Name_post",
      "US Senate Cand 1 Party" = "SenCand1Party_post",
      "US Senate Cand 2 Name" = "SenCand2Name_post",
      "US Senate Cand 2 Party" = "SenCand2Party_post",
      "US Senate Cand 3 Name" = "SenCand3Name_post",
      "US Senate Cand 3 Party" = "SenCand3Party_post"
    ),
    
    "President" = list(
      "President Cand 1 Name" = "PRES_DEM_CAND",
      "President Cand 1 Party" = "PRES_DEM_PARTY",
      "President Cand 2 Name" = "PRES_REP_CAND",
      "President Cand 2 Party" = "PRES_REP_PARTY"
    )
  ), 
  
  "2014" = list(
    "Governor" = list(
      "Governor Cand 1 Name" = "GovCand1Name_post",
      "Governor Cand 1 Party" = "GovCand1Party_post",
      "Governor Cand 2 Name" = "GovCand2Name_post",
      "Governor Cand 2 Party" = "GovCand2Party_post"
    ),
    
    "US Senate" = list(
      "US Senate Cand 1 Name" = "SenCand1Name_post",
      "US Senate Cand 1 Party" = "SenCand1Party_post",
      "US Senate Cand 2 Name" = "SenCand2Name_post",
      "US Senate Cand 2 Party" = "SenCand2Party_post",
      "US Senate Cand 3 Name" = "SenCand3Name_post",
      "US Senate Cand 3 Party" = "SenCand3Party_post"
    )
  ),
  
  "2016" = list(
    "Governor" = list(
      "Governor Cand 1 Name" = "GovCand1Name_post",
      "Governor Cand 1 Party" = "GovCand1Party_post",
      "Governor Cand 2 Name" = "GovCand2Name_post",
      "Governor Cand 2 Party" = "GovCand2Party_post",
      "Governor Cand 3 Name" = "GovCand3Name_post",
      "Governor Cand 3 Party" = "GovCand3Party_post"
    ),
    
    "US Senate" = list(
      "US Senate Cand 1 Name" = "SenCand1Name_post",
      "US Senate Cand 1 Party" = "SenCand1Party_post",
      "US Senate Cand 2 Name" = "SenCand2Name_post",
      "US Senate Cand 2 Party" = "SenCand2Party_post",
      "US Senate Cand 3 Name" = "SenCand3Name_post",
      "US Senate Cand 3 Party" = "SenCand3Party_post",
      "US Senate Cand 4 Name" = "SenCand4Name_post",
      "US Senate Cand 4 Party" = "SenCand4Party_post"
    ),
    "President" = list(
      "President Cand 1 Name" = "PRES_REP_CAND",
      "President Cand 1 Party" = "PRES_REP_PARTY",
      "President Cand 2 Name" = "PRES_DEM_CAND",
      "President Cand 2 Party" = "PRES_DEM_PARTY"
    )
  ),
  
  "2018" = list(
    "Governor" = list(
      "Governor Cand 1 Name" = "GovCand1Name_post",
      "Governor Cand 1 Party" = "GovCand1Party_post",
      "Governor Cand 2 Name" = "GovCand2Name_post",
      "Governor Cand 2 Party" = "GovCand2Party_post",
      "Governor Cand 3 Name" = "GovCand3Name_post",
      "Governor Cand 3 Party" = "GovCand3Party_post"
    ),
    
    "US Senate" = list(
      "US Senate Cand 1 Name" = "SenCand1Name_post",
      "US Senate Cand 1 Party" = "SenCand1Party_post",
      "US Senate Cand 2 Name" = "SenCand2Name_post",
      "US Senate Cand 2 Party" = "SenCand2Party_post",
      "US Senate Cand 3 Name" = "SenCand3Name_post",
      "US Senate Cand 3 Party" = "SenCand3Party_post"
    ),
    
    "Attorney General" = list(
      "Attorney General Cand 1 Name" = "AttCand1Name",
      "Attorney General Cand 1 Party" = "AttCand1Party",
      "Attorney General Cand 2 Name" = "AttCand2Name",
      "Attorney General Cand 2 Party" = "AttCand2Party"
    ),
    
    "Secretary of State" = list(
      "Secretary of State Cand 1 Name" = "SecCand1Name",
      "Secretary of State Cand 1 Party" = "SecCand1Party",
      "Secretary of State Cand 2 Name" = "SecCand2Name",
      "Secretary of State Cand 2 Party" = "SecCand2Party"
    )
  ),
  
  "2020" = list(
    "Governor" = list(
      "Governor Cand 1 Name" = "GovCand1Name_post",
      "Governor Cand 1 Party" = "GovCand1Party_post",
      "Governor Cand 2 Name" = "GovCand2Name_post",
      "Governor Cand 2 Party" = "GovCand2Party_post"),
    
    "US Senate" = list(
      "US Senate Cand 1 Name" = "SenCand1Name_post",
      "US Senate Cand 1 Party" = "SenCand1Party_post",
      "US Senate Cand 2 Name" = "SenCand2Name_post",
      "US Senate Cand 2 Party" = "SenCand2Party_post"
    ),
    
    "Attorney General" = list(
      "Attorney General Cand 1 Name" = "AttCand1Name",
      "Attorney General Cand 1 Party" = "AttCand1Party",
      "Attorney General Cand 2 Name" = "AttCand2Name",
      "Attorney General Cand 2 Party" = "AttCand2Party"
    ),
    
    "Secretary of State" = list(
      "Secretary of State Cand 1 Name" = "SecCand1Name",
      "Secretary of State Cand 1 Party" = "SecCand1Party",
      "Secretary of State Cand 2 Name" = "SecCand2Name",
      "Secretary of State Cand 2 Party" = "SecCand2Party"
    ),
    "President" = list(
      "President Cand 1 Name" = "PRES_DEM_CAND",
      "President Cand 1 Party" = "PRES_DEM_PARTY",
      "President Cand 2 Name" = "PRES_REP_CAND",
      "President Cand 2 Party" = "PRES_REP_PARTY"
    )
  ),
  
  "2022" = list(
    "Governor" = list(
      "Governor Cand 1 Name" = "GovCand1Name_post",
      "Governor Cand 1 Party" = "GovCand1Party_post",
      "Governor Cand 2 Name" = "GovCand2Name_post",
      "Governor Cand 2 Party" = "GovCand2Party_post",
      "Governor Cand 3 Name" = "GovCand3Name_post",
      "Governor Cand 3 Party" = "GovCand3Party_post"
    ),
    
    "US Senate" = list(
      "US Senate Cand 1 Name" = "SenCand1Name_post",
      "US Senate Cand 1 Party" = "SenCand1Party_post",
      "US Senate Cand 2 Name" = "SenCand2Name_post",
      "US Senate Cand 2 Party" = "SenCand2Party_post",
      "US Senate Cand 3 Name" = "SenCand3Name_post",
      "US Senate Cand 3 Party" = "SenCand3Party_post",
      "US Senate Cand 4 Name" = "SenCand4Name_post",
      "US Senate Cand 4 Party" = "SenCand4Party_post"
    ),
    
    "Attorney General" = list(
      "Attorney General Cand 1 Name" = "AttCand1Name",
      "Attorney General Cand 1 Party" = "AttCand1Party",
      "Attorney General Cand 2 Name" = "AttCand2Name",
      "Attorney General Cand 2 Party" = "AttCand2Party"
    ),
    
    "Secretary of State" = list(
      "Secretary of State Cand 1 Name" = "SecCand1Name",
      "Secretary of State Cand 1 Party" = "SecCand1Party",
      "Secretary of State Cand 2 Name" = "SecCand2Name",
      "Secretary of State Cand 2 Party" = "SecCand2Party",
      "Secretary of State Cand 3 Name" = "SecCand3Name",
      "Secretary of State Cand 3 Party" = "SecCand3Party"
    )
  )
)