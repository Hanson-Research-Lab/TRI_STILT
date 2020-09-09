df <- read.csv('./stilt/code/unique_TRI_location_height_year_stilt_RUN.csv')
temp <- subset(df,select=c(lati,long,zagl,YEAR))

#We should only need to run simulations for those with distinct lati, long and zagl (will need a way of rejoining later)
temp <- unique(temp)
head(temp)

temp$run_time=as.POSIXct('1990-01-01 00:00:00', tz='UTC')

head(temp)
#saveRDS(temp,file='receptors_1990.rds')

t_start <- '1990-01-01 00:00:00'
t_end   <- '1990-02-01 00:00:00'
run_times <- seq(from = as.POSIXct(t_start, tz = 'UTC'),
                 to   = as.POSIXct(t_end, tz = 'UTC'),
                 by   = 'day')

require(data.table)
setDT(temp)[ ,list(lati=lati, long=long,zagl=zagl, run_times), by = 1:nrow(temp)]