library(splitstackshape)
library(data.table)
library(plyr)
library(dplyr)

#These data are already reduced down to the unique values
df <- read.csv('./stilt/code/unique_TRI_location_height_year_stilt_RUN.csv')

DF_new <- expandRows(df, count=366,count.is.col=FALSE) #account for leap year
DF_new <- ddply(DF_new,"id",transform,ID2=1:length(id))
DF_new$OrigDate <- paste(DF_new$YEAR,"01","01",sep="-")
DF_new$Date <- as.Date(DF_new$ID2,DF_new$OrigDate)
DF_new <- subset(DF_new, select = -c(ID2,OrigDate,id,YEAR))

#For now we only need a small testing subset
random_sample <- sample_n(DF_new, 20)
saveRDS(random_sample,file='./stilt/data/receptors_subsample_090920.rds')
