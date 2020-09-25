#Load the libraries
library(splitstackshape)
library(data.table)
library(plyr)
library(dplyr)

#Gather the input data from make command
input_path = commandArgs(trailingOnly=TRUE)[1]
output_path = commandArgs(trailingOnly=TRUE)[2]
subsample = commandArgs(trailingOnly=TRUE)[3]

#These data are already reduced down to the unique values './stilt/code/unique_TRI_location_height_year_stilt_RUN.csv'
df <- read.csv(input_path)

DF_new <- expandRows(df, count=366,count.is.col=FALSE) #account for leap year
DF_new <- ddply(DF_new,"id",transform,ID2=1:length(id))
DF_new$OrigDate <- paste(DF_new$YEAR,"01","01",sep="-")
DF_new$run_times <- as.Date(DF_new$ID2,DF_new$OrigDate)
DF_new <- subset(DF_new, select = -c(ID2,OrigDate,id,YEAR))

#For now we only need a small testing subset './stilt/data/receptors_subsample_090920.rds'
sample <- sample_n(DF_new, 20)
saveRDS(sample,file= output_path)
