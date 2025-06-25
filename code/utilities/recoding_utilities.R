## Recoding Utility functions

## Negate for simple syntax
`%notin%` <- Negate(`%in%`)

### Apply codebook and recode
apply_codebook_and_recode <- function(year) {
  # Construct variable names and codebook file name
  base_name <- ifelse(year < 10, paste0("0", year), as.character(year))
  ces_variable_name <- paste0("CES_", base_name, "_rc")
  cps_variable_name <- paste0("CPS_", base_name, "_rc")
  codebook_file <- "code/CODEBOOK.xlsm" ## EDIT HERE
  
  # Read codebook and recode for CES
  ces_codebook <- read.codebook(codebook_file, base_name, CES)
  
  #browser()
  assign(ces_variable_name, recode.df(get(paste0("CES_", base_name, "_raw_subset")), ces_codebook), envir = .GlobalEnv)
  
  # Read codebook and recode for CPS
  cps_codebook <- read.codebook(codebook_file, base_name, CPS)
  assign(cps_variable_name, recode.df(get(paste0("CPS_", base_name, "_raw_subset")), cps_codebook), envir = .GlobalEnv)
}
 

### Read in codebook, output recoded data
# Define function to read in codebook
read.codebook <- function(codebook, sheet = NULL, dataset) {
  dataset <- deparse(substitute(dataset))
  year <- str_sub(codebook,-7,-6)
  
  if (is.null(sheet)) {
    entire.codebook <- read_excel(codebook, skip = 1, .name_repair = "minimal")
  } else {
    entire.codebook <- read_excel(codebook, sheet = sheet, skip = 1, .name_repair = "minimal")
  }
  
  cps_columns <- 1:6
  ces_columns <- 7:12
  
  cps_year_codebook <- entire.codebook[, cps_columns]
  ces_year_codebook <- entire.codebook[, ces_columns]
  
  # Create data frames with names including the year
  if (dataset == "CES") {
    return(assign(paste0("ces.", year, ".codebook"), ces_year_codebook))
  } else if(dataset == "CPS") {
    return(assign(paste0("cps.", year, ".codebook"), cps_year_codebook))
  } else if (dataset == "whole") {
    return(entire.codebook)
  }
  else {
    stop("Must specify CES, CPS, whole")
  }
}
 

### Split and unlist csv character values
## Split and unlist character values (separated by commas) into a vector with n elements
vector.split <- function(vector) {
  if (is.character(vector)) {
    return(unlist(strsplit(as.character(vector), split = ",")))
  } else if (is.numeric(vector)) {
    return(as.numeric(unlist(strsplit(as.character(vector), split = ","))))
  } else {
    print("LIST NEITHER NUMERIC NOR VECTOR")
  }
}

### Recode column
# Column-recoding function
recode_the_vals <- function(x, key) {
  x_name <- quo_name(enquo(x))
  x <- as.factor(x)
  key.sub <- key %>%
    filter(Variable.name %in% x_name)
  label.keys <- tibble(values = vector.split(key.sub$Codes), labels =
                         vector.split(key.sub$New.labels))
  
  recode(x,!!!(deframe(label.keys)))
}

### Add new variables
add.vars <- function(survey.data, key, result) {
  variable.names <- na.omit(key[, 1:2])
  
  for (i in 1:nrow(variable.names)) {
    mother.variable <- variable.names$Mother.variable[i]
    var.name <- variable.names$Variable.name[i]
    
    if (!(var.name %in% names(survey.data))) {
      result <- mutate(result, !!var.name := survey.data[[mother.variable]])
    }
  }
  return(result)
}

### Applies column recode to relevant variables
# Applies column recode functon to all relevant variables in df
recode.df <- function(survey.data, codebook) {
  key <- codebook
  options.list <- suppressMessages(na.omit(key$Variable.name))
  result <- survey.data
  result <- add.vars(survey.data, key, result)
  
  result <- result %>%
    mutate(across(all_of(options.list), ~ recode_the_vals(.x, key)))
  
  return(result)
}

### Clean NA-like inputs
clean_NAs <- function(df) {
  for (var in names(df)) {
    if (is.factor(df[[var]])) {
      # For factors, replace NA-like values with actual NA in levels
      levels(df[[var]])[levels(df[[var]]) %in% c("NA", "", "_NA_")] <- NA
      
      # Drop unused levels
      df[[var]] <- droplevels(df[[var]])
    } else {
      # For non-factors, directly replace NA-like values with actual NA
      df[[var]][df[[var]] %in% c("NA", "", "_NA_")] <- NA
      
      # If it's numeric, also replace -1 with NA
      if (is.numeric(df[[var]])) {
        df[[var]][df[[var]] == -1] <- NA
      }
    }
  }
  
  return(df)
}

ces_rc_df_name_mapping <- c(
  "2012" = "CES_12_rc",
  "2014" = "CES_14_rc",
  "2016" = "CES_16_rc",
  "2018" = "CES_18_rc",
  "2020" = "CES_20_rc",
  "2022" = "CES_22_rc"
)

### Additional Recode Functions
# Define age groups
calculate_age_groups <- function(age_column) {
  # Define age groups
  age_groups <- cut(age_column,
                    breaks = c(17, 29, 39, 49, 59, 69, Inf),
                    labels = c("18-29", "30-39", "40-49", "50-59", "60-69", "70+"),
                    include.lowest = TRUE)
  return(age_groups)
}

# Fips to upper case state name
fips_to_upper_state_name <- function(fips_codes) {
  state_names <- fips(fips_codes, to='Name')
  toupper(state_names)
}

# Extract state from full fips code
extract_state_from_fips <- function(fips_code) {
  as.numeric(substr(fips_code, 1, 2))
}


process_cd <- function(cd_column) {
  column_class <- class(cd_column)
  if (any(grepl("numeric", column_class)) || any(grepl("double", column_class))) {
    cd_column[cd_column == -1] <- NA
    return(as.character(cd_column))
  } else if (column_class == "character") {
    cd_column[cd_column == ""] <- NA
    return(cd_column)
  } else {
    return(cd_column)
  }
}

add_location_vars <- function(ces_rc_datasets, pre_post_location_vars) {
  state_abbreviations <- c(state.abb, "DC")
  # Create a vector of state names including "District of Columbia"
  state_names <- c(state.name, "DISTRICT OF COLUMBIA")
  for (year in names(ces_rc_datasets)) {
    dataset <- ces_rc_datasets[[year]]
    vars <- pre_post_location_vars[[year]]
    
    # Pre-state variable
    if (year == "2006") {
      dataset$PRE_STATE_rc <- toupper(state_names[match(dataset[[vars$pre_state]], state_abbreviations)])
      
    } else {
      dataset$PRE_STATE_rc <- fips_to_upper_state_name(dataset[[vars$pre_state]])
    }
    
    # Post-state variable
    if (year == "2006") {
      dataset$POST_STATE_rc <- toupper(state_names[match(dataset[[vars$post_state]], state_abbreviations)])
    } else {
      dataset$POST_STATE_rc <- fips_to_upper_state_name(dataset[[vars$post_state]])
    }

    # Assign the modified dataset back to its original variable name
    assign(paste0("CES_", substr(year, 3, 4), "_rc"), dataset, envir = .GlobalEnv)
    
    print(paste("CES", year, "location variables created"))
  }
}

# Recode vote-choice variables from just saying "Cand1" or "Cand2" to the corresponding party of those candidates

