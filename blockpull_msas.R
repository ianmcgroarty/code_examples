############### PREAMBLE - only run once ###############
#install.packages('tigris')
#install.packages('tidycensus')
#install.packages('tidyverse')
#install.packages('xlsx')
#install.packages('cdlTools')
library(cdlTools)
library(tidyverse)
library(tigris)
options(tigris_use_cache = TRUE)
library(sf)
options(tigris_class = "sf")

library(tidycensus)
  census_api_key("21b3c956a5fa7ad4a4b6caecf91e5c1dedf391e4")
library(haven)
library(foreign)
#library(xlsx)
library(readxl)

#########################################################################################################################
############################  EMPEZAMOS #################################################################################
#########################################################################################################################
###### TIMER
g <- rnorm(100000)
h <- rep(NA, 100000)

# START THE CLOCK 
ptm <- proc.time()
  
  
### TEST THE LOOPER 
topmsa <- c(12060, 12580, 14460, 16980, 19100, 19740, 19820, 26420, 31080, 33100, 
            33460, 35620, 37980, 38060, 40140, 41740, 41860, 42660, 45300, 47900)

cb <- core_based_statistical_areas(cb = TRUE)  
#filter(cb, grepl(19100, CBSAFP))

#########################################################
###### GET ALL THE BLOCKS MACRO #########################
#########################################################
metro_blocks <- function(cbsa_code) {
  
  # First, identify which states intersect the metro area using the
  # `states` function in tigris
  st <- states(cb = TRUE)
  cb <- core_based_statistical_areas(cb = TRUE)
  metro <- filter(cb, grepl(cbsa_code, CBSAFP))
  
  stcodes <- st[metro,]$STATEFP
 # browser() IF YOU WANT TO TROUUBLESHOOT
  
  # Then, fetch the blocks, using rbind_tigris if there is more
  # than one state
  ### NOTE: Make sure you want 2010
    tr <- rbind_tigris(
      map(stcodes, function(x) {
        blocks(x , year=2000)
      })
    )
  
  # Now, find out which blocks are within the metro area
  within <- st_within(tr, metro)
  
  within_lgl <- map_lgl(within, function(x) {
    if (length(x) == 1) {
      return(TRUE)
    } else {
      return(FALSE)
    }
  })
  
  # Finally, subset and return the output
  output <- tr[within_lgl,]
  
  return(output)
  
}


############# LETS MAKE SURE IT WORKS
phl <- metro_blocks(37980)
ggplot(phl) + geom_sf()

#phl$state.abbr2 <- apply(phl, 1, function(row) fips(row['STATEFP00'], to='Abbreviation'))

########################################################
######## RUN FOR ALL 20 MSAS AND MAKE DATA #############
########################################################
#allblocks <- data.frame()
testmap <- map(topmsa, function(x){
  metro_blocks(x) %>% 
    mutate(metro_id = x)
#  allblocks <- rbind(allblocks,testmap)
})

allblocks <- rbind(testmap[[1]],testmap[[2]], testmap[[3]],testmap[[4]],testmap[[5]],testmap[[6]]
                    ,testmap[[7]],testmap[[8]],testmap[[9]],testmap[[10]],testmap[[11]], testmap[[12]]
                    ,testmap[[13]],testmap[[14]],testmap[[15]],testmap[[16]],testmap[[17]],testmap[[18]]
                    ,testmap[[19]],testmap[[20]])

### Tack on State Abbreviation since that is what is in CCP
allblocks$stateabbr <- apply(allblocks, 1, function(row) fips(row['STATEFP00'], to='Abbreviation'))
allblocksbkp <- allblocks

########################################################
#################### EXPORT THE DATA ##################
########################################################
keeps <- c("STATEFP00", "COUNTYFP00", "TRACTCE00", "BLOCKCE00", "metro_id",
           "INTPTLAT00", "INTPTLON00", "stateabbr")

## I can't export the geometry variable which is a column of lists. So I need to remove it.
allblocks.no_sf <- as.data.frame(allblocks)
class(allblocks.no_sf)
allblocks.no_sf <- allblocks.no_sf[keeps]

write.csv(allblocks.no_sf, file = "E:/Slava/branches/Data/Geography/allblocks.csv")
