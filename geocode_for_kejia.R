
library(tidyverse)
library(tigris)
options(tigris_use_cache = TRUE)
library(sf)
options(tigris_class = "sf")
library(tidycensus)
census_api_key("21b3c956a5fa7ad4a4b6caecf91e5c1dedf391e4")
library(haven)
library(foreign)
library(purrr)
library(readxl)
library(dplyr)
library(stringr)  


###### You can use this once you have the longitudes and latitudes to get the census block/tract/county/state information.
--------------------------------------------------------------------------------------------------------------------------
##### Use R to grab the Census tracts since so many are missing
branchdataA$census_code <- apply(branchdataA, 1, function(row) call_geolocator_latlon(row['Latitude'], row['Longitude']))
branchdataB$census_code <- apply(branchdataB, 1, function(row) call_geolocator_latlon(row['Latitude'], row['Longitude']))
RawBranchC <- rbind(branchdataA, branchdataB)
-------------------------------------------------------------------------------------------------------------------------


### Below is the code that takes the nearby census tracts (also works for blocks). It works using the sf package
  ## to expand the geometries of the tracts and take the intersection of those geometries with any other geometry 
  ## (e.g. any other tract). If you would like an example code the is a little more simple but can demonstrate let me know!

------------------------------------------------------------------------------------------------------------------------
##########################################################################################
############ GEOGRAPHIC ##############
### TRACTS ###
## Need to redefine to include WY since it will have control tracts
stateabr <- c("ak" ,"al", "ar", "az", "ca", "co", "ct", "dc", "de", "fl",
              "ga", "ia", "id", "il", "in", "ks", "ky", "la", "ma",
              "md", "me", "mi", "mn", "mo", "ms", "mt", "nc", "nd", "ne",
              "nh", "nj", "nm", "nv", "ny", "oh", "ok", "or", "pa", "hi",
              "ri", "sc", "sd", "tn", "tx", "ut", "va", "vt", "wa", "wi", "wy", "wv")

### Tract Function
tractfetch <- function(statecode) {
  st.blocks <- tracts(statecode , year=2010) 
}

## Run Function
ustracts <- map(stateabr, function(x){
  tractfetch(x)
})
## Put together all the states into one dataset
ustracts2 <- rbind(  ustracts[[1]], ustracts[[2]], ustracts[[3]], ustracts[[4]], ustracts[[5]], ustracts[[6]]
                     ,ustracts[[7]], ustracts[[8]], ustracts[[9]], ustracts[[10]],ustracts[[11]],ustracts[[12]]
                     ,ustracts[[13]],ustracts[[14]],ustracts[[15]],ustracts[[16]],ustracts[[17]],ustracts[[18]]
                     ,ustracts[[19]],ustracts[[20]],ustracts[[21]],ustracts[[22]],ustracts[[23]],ustracts[[24]]
                     ,ustracts[[25]],ustracts[[26]],ustracts[[27]],ustracts[[28]],ustracts[[29]],ustracts[[30]]
                     ,ustracts[[31]],ustracts[[32]],ustracts[[33]],ustracts[[34]],ustracts[[35]],ustracts[[36]]
                     ,ustracts[[37]],ustracts[[38]],ustracts[[39]],ustracts[[40]],ustracts[[41]],ustracts[[42]]
                     ,ustracts[[43]],ustracts[[44]],ustracts[[45]],ustracts[[46]],ustracts[[47]],ustracts[[48]]
                     ,ustracts[[49]],ustracts[[50]],ustracts[[51]]
)
#####   NEARBY FUNCTION  
# The distance from the highfed borders. And if you want to use centroids or not.
# If you don't use centroids, border intesections are used. 
mapper_nostate <- function(distence, centroidz=FALSE) {
  
  # Pull the blocks for the given state and transform the geometries. 
  st.blocks <- ustracts2 %>%  st_transform(., 3488) %>% .[1:5]
  
  # Diplay the total number of blocks in the state
  print(nrow(st.blocks))
  
  # Only want highfed blocks
  bk.rac <- inner_join(st.blocks, rac.highfed, by="GEOID10")
  
  # Expand the borders of the highfed blocks.
  ## in meters^2 soooooo idk its like a yard or something #murica #imperialsystem
  ## Nathan says he wants 3 km . 
  bk.rac.5k <- st_buffer(bk.rac, dist = distence) ## IN KILOMETERS  
  
  # I need the midpoints, sometimes, we are ramping up this function so it can do both!
  if(centroidz==TRUE){
    st.controls <- st_centroid(st.blocks, of_largest_polygon=TRUE) %>% st_transform(., 3488)
  }
  if(centroidz == FALSE){
    st.controls <- st.blocks
  }
  
  # We want the overlap of the expanded highfed borders and the specified controls
  nearby <- st_intersection(st.controls, bk.rac.5k)
  
  # Only want the ids & drop duplicates - drop geometry for now, we will worry about the map later. 
  nearvec <-  nearby[1:5]  %>% st_drop_geometry() %>%  dplyr::distinct()
  # It should contain the block itself but I should double check.-- IT DOES
  
  # Number of tracts identified 
  print(nrow(nearvec))
  return(nearvec)
  ## THE mapper function should append to nearvec right? well no, but actually yes
}


### Nathan wants 3 matches
# 1. Contiguous - basically all of the border tracts. 
# The way to do this is to buffer the highfed tracts just a little and then run an interscetion
# for any tract boarders that interscet that buffer. 
# 2. 1 mile centroids
# draw a one mile circle from the borders and take all of the block centroids within that buffer. 
# 3. 2 mile centroids
contiguous2 <- mapper_nostate( 100,  centroidz=FALSE)
onemile2    <- mapper_nostate( 1609, centroidz=TRUE)
twomile2    <- mapper_nostate( 3218, centroidz=TRUE)

# Save them seperately
write.csv(contiguous2, file="/home/c1imm01/nathan/c12_tr175_contiguous.csv")  
write.csv(onemile2, file="/home/c1imm01/nathan/c12_tr175_onemile.csv")    
write.csv(twomile2, file="/home/c1imm01/nathan/c12_tr175_twomile.csv")

# Put them all together
alltractsA <- rbind(contiguous2, onemile2, twomile2) %>% dplyr::distinct()
---------------------------------------------------------------------------------------------------------------------
  

## IF you are concerned about the 50+ warnings here is every single one of them :). It just means that the earth is round. 
#1: attribute variables are assumed to be spatially constant throughout all geometries