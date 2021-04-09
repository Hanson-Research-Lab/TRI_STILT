#**********************************************************************#
#**********************************************************************#
# Read in TRI Files #
#**********************************************************************#
#**********************************************************************#


#******************************************************************************#
# Creates a single file TRI file 
#
# File Path: 
#     /Users/joemyramsay/files/HCI/AP_Modeling/TRI_DispersionModeling/TRI_STILT/data/raw/Toxic_Release_Inventory_raw
# Datasets:
#     tri_(1987-2018)_ut.csv
#
# File Path:
#    /Users/joemyramsay/files/HCI/AP_Modeling/TRI_DispersionModeling/TRI_STILT/data/raw
# Datasets:
#     RSEI_Chemical_Data.csv
#     RSEI_Facility_Data.csv
#     IARC_Class_Full_List.csv
#
#******************************************************************************#

rm(list = ls())
library("tidyverse")

#**********************************************************************#
#**********************************************************************#
#**********************************************************************#
# Combine Files #
#**********************************************************************#
#**********************************************************************#
#**********************************************************************#
### IARC
setwd("/Users/joemyramsay/files/HCI/AP_Modeling/TRI_DispersionModeling/TRI_STILT/data/raw")
iarc <- read.csv("IARC_Class_Full_List.csv")
iarc <- subset(iarc, select = c(CAS.No., Agent, Group))

names(iarc)[names(iarc) == "CAS.No."] <- "cas_std"
names(iarc)[names(iarc) == "Agent"]  <- "chemical_name"
names(iarc)[names(iarc) == "Group"]  <- "iarc_group"

##### Remove Group 3 chemicals
iarc <- subset(iarc, iarc$iarc_group %in% c("1", "2A", "2B"))

##### Make dataset long by cas number
iarc <- separate(iarc, cas_std, c("cas1", "cas2", "cas3", "cas4"), sep = ", ")
iarc$id <- seq.int(nrow(iarc))

iarc <- reshape(iarc, 
                varying = c("cas1", "cas2", "cas3", "cas4"), 
                v.names = "cas_std",
                idvar = "id",
                direction = "long")

iarc$id <- iarc$time <- NULL

##### Remove fields without cas number
iarc <- subset(iarc, !is.na(iarc$cas_std))
iarc <- subset(iarc, str_detect(iarc$cas_std, "[A-Z 0-9]"))


#**********************************************************************#
### RSEI Chemical Data
setwd("/Users/joemyramsay/files/HCI/AP_Modeling/TRI_DispersionModeling/TRI_STILT/data/raw")
rsei_chem <- read.csv("RSEI_Chemical_Data.csv")
rsei_chem <- subset(rsei_chem, select = c(CASNumber, CASStandard, Chemical, Added, 
                                          ExpansionFlag, Core88ChemicalFlag, 
                                          Core95ChemicalFlag, Core98ChemicalFlag, 
                                          Core00ChemicalFlag, Core01ChemicalFlag))

names(rsei_chem)[names(rsei_chem) == "CASNumber"]          <- "cas"
names(rsei_chem)[names(rsei_chem) == "CASStandard"]        <- "cas_std"
names(rsei_chem)[names(rsei_chem) == "Chemical"]           <- "chemical"
names(rsei_chem)[names(rsei_chem) == "Added"]              <- "yr_added"
names(rsei_chem)[names(rsei_chem) == "ExpansionFlag"]      <- "expansion1995"
names(rsei_chem)[names(rsei_chem) == "Core88ChemicalFlag"] <- "core1988"
names(rsei_chem)[names(rsei_chem) == "Core95ChemicalFlag"] <- "core1995"
names(rsei_chem)[names(rsei_chem) == "Core98ChemicalFlag"] <- "core1998"
names(rsei_chem)[names(rsei_chem) == "Core00ChemicalFlag"] <- "core2000"
names(rsei_chem)[names(rsei_chem) == "Core01ChemicalFlag"] <- "core2001"

##### Merge in IARC Grouping
iarc$m1    <- 1
rsei_chem$m2 <- 2
rsei_chem <- merge(iarc, rsei_chem, by = c("cas_std"), all = TRUE)
rsei_chem$merged <- rowSums(rsei_chem[, c('m1', 'm2')], na.rm = TRUE)
rsei_chem$m1 <- rsei_chem$m2<- NULL

rsei_chem <- subset(rsei_chem, rsei_chem$merged == 3)

rsei_chem$merged <- NULL

#**********************************************************************#
### RSEI Facility Data
setwd("/Users/joemyramsay/files/HCI/AP_Modeling/TRI_DispersionModeling/TRI_STILT/data/raw")
rsei_fac <- read.csv("RSEI_Facility_Data.csv")
rsei_fac <- subset(rsei_fac, select = c(FacilityID, FacilityNumber, FRSID, Latitude,
                                        Longitude, Street, City, County, State, ZIP9,
                                        FIPS, STFIPS, StackHeight, StackHeightSource,
                                        NewIndustryFlag)) # StackVelocity,StackDiameter, StackTemperature, StackVelocitySource, StackDiameterSource,StackTemperatureSource

names(rsei_fac)[names(rsei_fac) == "FacilityID"]             <- "facility_id"
names(rsei_fac)[names(rsei_fac) == "FacilityNumber"]         <- "facility_number"
names(rsei_fac)[names(rsei_fac) == "FRSID"]                  <- "frsid"
names(rsei_fac)[names(rsei_fac) == "Latitude"]               <- "rsei_lat"
names(rsei_fac)[names(rsei_fac) == "Longitude"]              <- "rsei_lon"
names(rsei_fac)[names(rsei_fac) == "Street"]                 <- "rsei_street_address"
names(rsei_fac)[names(rsei_fac) == "City"]                   <- "rsei_city"
names(rsei_fac)[names(rsei_fac) == "County"]                 <- "rsei_county"
names(rsei_fac)[names(rsei_fac) == "State"]                  <- "rsei_state"
names(rsei_fac)[names(rsei_fac) == "ZIP9"]                   <- "rsei_zip9"
names(rsei_fac)[names(rsei_fac) == "FIPS"]                   <- "rsei_county_fips"
names(rsei_fac)[names(rsei_fac) == "STFIPS"]                 <- "rsei_state_fips"
names(rsei_fac)[names(rsei_fac) == "StackHeight"]            <- "stack_height"
names(rsei_fac)[names(rsei_fac) == "StackHeightSource"]      <- "stack_height_source"
names(rsei_fac)[names(rsei_fac) == "NewIndustryFlag"]        <- "industry1998"

#names(rsei_fac)[names(rsei_fac) == "StackVelocity"]          <- "stack_velocity"
#names(rsei_fac)[names(rsei_fac) == "StackDiameter"]          <- "stack_diameter"
#names(rsei_fac)[names(rsei_fac) == "StackTemperature"]       <- "stack_temp"
#names(rsei_fac)[names(rsei_fac) == "StackVelocitySource"]    <- "stack_velocity_source"
#names(rsei_fac)[names(rsei_fac) == "StackDiameterSource"]    <- "stack_diameter_source"
#names(rsei_fac)[names(rsei_fac) == "StackTemperatureSource"] <- "stack_temp_source"

##### Remove facilities outside of Utah
rsei_fac <- subset(rsei_fac, rsei_fac$rsei_state %in%  c("UT"))


#**********************************************************************#
### TRI
setwd("/Users/joemyramsay/files/HCI/AP_Modeling/TRI_DispersionModeling/TRI_STILT/data/raw/Toxic_Release_Inventory_raw")
temp <- list.files(pattern = "*.csv")
tri_files <- lapply(temp, read.csv)

names(tri_files) <- str_replace(temp, pattern = ".csv", replacement = "") # Name each tibble to match file name
rm("temp")

##### Combine TRI files into a single dataset
tri_files <- lapply(tri_files, function(x) subset(x, select = c(X1..YEAR, X2..TRIFD, X3..FRS.ID,
                                                                X4..FACILITY.NAME, X6..CITY, X7..COUNTY, 
                                                                X8..ST, X9..ZIP, X12..LATITUDE, X13..LONGITUDE,
                                                                X15..INDUSTRY.SECTOR.CODE, X30..CHEMICAL, 
                                                                X31..CAS...COMPOUND.ID, X35..METAL, 
                                                                X37..CARCINOGEN, X39..UNIT.OF.MEASURE,
                                                                X40..5.1...FUGITIVE.AIR, X41..5.2...STACK.AIR)))

tri_raw <- bind_rows(tri_files, .id = "column_label")
rm("tri_files")

names(tri_raw)[names(tri_raw) == "X1..YEAR"]                  <- "year"
names(tri_raw)[names(tri_raw) == "X2..TRIFD"]                 <- "trifd"
names(tri_raw)[names(tri_raw) == "X3..FRS.ID"]                <- "frsid"
names(tri_raw)[names(tri_raw) == "X4..FACILITY.NAME"]         <- "facility_name"
names(tri_raw)[names(tri_raw) == "X6..CITY"]                  <- "city"
names(tri_raw)[names(tri_raw) == "X7..COUNTY"]                <- "county"
names(tri_raw)[names(tri_raw) == "X8..ST"]                    <- "state"
names(tri_raw)[names(tri_raw) == "X9..ZIP"]                   <- "zip"
names(tri_raw)[names(tri_raw) == "X12..LATITUDE"]             <- "lat"
names(tri_raw)[names(tri_raw) == "X13..LONGITUDE"]            <- "lon"
names(tri_raw)[names(tri_raw) == "X15..INDUSTRY.SECTOR.CODE"] <- "ind_sector_cd"
names(tri_raw)[names(tri_raw) == "X30..CHEMICAL"]             <- "chemical"
names(tri_raw)[names(tri_raw) == "X31..CAS...COMPOUND.ID"]    <- "cas"
names(tri_raw)[names(tri_raw) == "X35..METAL"]                <- "metal"
names(tri_raw)[names(tri_raw) == "X37..CARCINOGEN"]           <- "carcinogen"
names(tri_raw)[names(tri_raw) == "X39..UNIT.OF.MEASURE"]      <- "units"
names(tri_raw)[names(tri_raw) == "X40..5.1...FUGITIVE.AIR"]   <- "fugitive"
names(tri_raw)[names(tri_raw) == "X41..5.2...STACK.AIR"]      <- "stack"

##### Get CAS number into correct format
tri_raw$cas <- str_remove(tri_raw$cas, "^0+")
tri_raw$cas_length <- nchar(tri_raw$cas)

tri_raw$cas_std[str_detect(tri_raw$cas, "^[A-Z]") == TRUE] <- tri_raw$cas

tri_raw$cas_std <-paste(str_sub(tri_raw$cas, 1, tri_raw$cas_length - 3), 
                        str_sub(tri_raw$cas, tri_raw$cas_length - 2, -2), 
                        str_sub(tri_raw$cas, -1), sep ="-")

##### Restrict Dataset
######## AP years: 1990-1999
tri_raw <- subset(tri_raw, tri_raw$year >= 1990 & tri_raw$year <= 1999)

######## Facilities with fugitive & stack emissions > 0
tri_raw <- subset(tri_raw, tri_raw$fugitive > 0 | tri_raw$stack > 0)


#**********************************************************************#
#**********************************************************************#
# Combine Data #
#**********************************************************************#
### Chemical Information
tri_raw$m1   <- 1
rsei_chem$m2 <- 2
tri_clean <- merge(tri_raw, rsei_chem, by = c("cas"), all = TRUE)
tri_clean$merged <- rowSums(tri_clean[, c('m1', 'm2')], na.rm = TRUE)
tri_clean$m1 <- tri_clean$m2<- NULL

tri_clean <- subset(tri_clean, tri_clean$merged == 3)
tri_clean$merged <- NULL

### Facility Information
tri_clean$m1 <- 1
rsei_fac$m2  <- 2
tri_clean <- merge(tri_clean, rsei_fac, by = c("frsid"), all = TRUE)
tri_clean$merged <- rowSums(tri_clean[, c('m1', 'm2')], na.rm = TRUE)
tri_clean$m1 <- tri_clean$m2<- NULL

tri_clean <- subset(tri_clean, tri_clean$merged == 3)
tri_clean$merged <- NULL

##### Check agreement between RSEI lat/lon & TRI lat/lon
tri_clean$lat_flag[tri_clean$lat != tri_clean$rsei_lat] <- 1 
tri_clean$lat_flag[tri_clean$lat == tri_clean$rsei_lat] <- 0 

tri_clean$lon_flag[tri_clean$lon != tri_clean$rsei_lon] <- 1 
tri_clean$lon_flag[tri_clean$lon == tri_clean$rsei_lon] <- 0

tri_clean$lat    <- ifelse(tri_clean$lat_flag == 1, tri_clean$rsei_lat, tri_clean$lat)
tri_clean$lon    <- ifelse(tri_clean$lon_flag == 1, tri_clean$rsei_lon, tri_clean$lon)
tri_clean$city   <- ifelse(tri_clean$city != tri_clean$rsei_city, tri_clean$rsei_city, tri_clean$city)
tri_clean$county <- ifelse(tri_clean$county != tri_clean$rsei_county, tri_clean$rsei_county, tri_clean$county)
tri_clean$zip    <- ifelse(tri_clean$zip != tri_clean$rsei_zip9, tri_clean$rsei_zip9, tri_clean$zip)

tri_clean$lat_flag <- tri_clean$lon_flag <- tri_clean$rsei_lat <- tri_clean$rsei_lon <-
  tri_clean$rsei_city <- tri_clean$rsei_county <- tri_clean$rsei_zip9 <-tri_clean$rsei_state <-
  NULL

### Expand dates
tri_clean$yr_start <- as.Date(paste(tri_clean$year, 1, 1, sep = "-"))
tri_clean$yr_end   <- as.Date(paste(tri_clean$year, 12, 31, sep = "-"))

tri_clean$temp_id <- seq.int(nrow(tri_clean))
tri_dates <- subset(tri_clean, select = c(frsid, yr_start, yr_end, temp_id))

##### Sequence of dates for each corresponding start, end elements
tri_dates <- tri_dates %>%
  transmute(temp_id, tri_date = map2(yr_start, yr_end, seq, by = "1 day")) %>%
  unnest(tri_date) %>% 
  distinct

tri_clean$m1 <- 1
tri_dates$m2 <- 2
tri_clean <- merge(tri_clean, tri_dates, by = c("temp_id"), all = TRUE)
tri_clean$merged <- rowSums(tri_clean[, c('m1', 'm2')], na.rm = TRUE)
tri_clean$m1 <- tri_clean$m2<- NULL
table(tri_clean$merged)
tri_clean$merged <- NULL
tri_clean$temp_id <- NULL

### Calculate daily emissions
tri_clean$n_days <- as.numeric(tri_clean$yr_end - tri_clean$yr_start)

tri_clean$stack_daily <- tri_clean$stack/tri_clean$n_days
tri_clean$fugative_daily <- tri_clean$fugitive/tri_clean$n_days

tri_clean$yr_start <- tri_clean$yr_end <- tri_clean$n_days <- NULL

### Export Dataset
write.csv(tri_clean, file = "/Users/joemyramsay/files/HCI/AP_Modeling/TRI_DispersionModeling/TRI_STILT/data/processed/tri_clean.csv")




