#Load the libraries
library(splitstackshape)
library(data.table)
library(plyr)
library(dplyr)


#This simulation data is coming from the validation notebook. No makefile built yet for this part
df <- read.csv('/home/boogie2/Hanson_Lab/TRI_STILT/data/validation/092920_epa_valid_2014.csv')
df$run_times = as.Date(df$run_times, "%m-%d-%Y")
head(df)
sapply(df,class)


sample <- sample_n(df, 100)

#We can save this as a validation set and get it ready to run. Will be a boatload of simulations
saveRDS(sample,file= '/home/boogie2/Hanson_Lab/TRI_STILT/data/processed/stilt_input/092920_epa_valid_2014.rds')