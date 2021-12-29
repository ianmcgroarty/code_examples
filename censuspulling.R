library(tidycensus)
library(tidyverse)
library(stringr)
library(purrr)
library(dplyr)
census_api_key("21b3c956a5fa7ad4a4b6caecf91e5c1dedf391e4")

## CHECK OUT THE VARIABLES 
v17 <- load_variables(2010, "sf1")
v18 <- load_variables(2017, "acs5")



m90 <- get_decennial(geography = "state", variables = "H043A001", year = 2010 , keep_geo_vars = TRUE)

# Internet example https://cran.r-project.org/web/packages/tidycensus/tidycensus.pdf
vars10 <- c("P005003", "P005004", "P005006", "P004003")
il <- get_decennial(geography = "county", variables = vars10, year = 2010,
                    summary_var = "P001001", state = "IL", geometry = TRUE) %>%
  mutate(pct = 100 * (value / summary_value))

## Doesn't work?
il <- get_decennial(geography = "block", variables = vars10, year = 2010,
                    summary_var = "P001001", state = "IL", geometry = TRUE) 


# internet example https://stackoverflow.com/questions/54262394/error-when-using-get-decennial-to-get-2010-block-group-data-but-can-get-block
b_10 <- get_decennial(geography = "block", 
                      variables = "P001001", 
                      year      = 2010,
                      state     = "WY", 
                      county    = "Teton", 
                      geometry  =  FALSE)
## Doesn't work - suspicion that you have to specify county... 
  # Confirmed here: https://walkerke.github.io/tidycensus/articles/basic-usage.html


## What I can do is loop over every county of the state 

## Get the county codes 
stct <- get_decennial(geography = "county" , variables = "P001001" , year=2010, state ="WY") 
  stct$geo <- as.character(stct$GEOID)
  ccode <- substr(stct$geo,3,5)
  

## The County FUNCTION    
getdec.state <- function(county){ 
  b_10 <- get_decennial(geography = "block", 
                      variables = "P001001", 
                      year      = 2010,
                      state     = "WY",
                      county    = county, 
                      geometry  =  FALSE)
}

##PROVE THE COUNTY FUNCTION
wy <- map_dfr(ccode, function(x){
  getdec.state(x)
})



#### STATE FUNCTION
getdec.statecounty <- function(statecode){ 
      stct <- get_decennial(geography = "county" , variables = "P001001" , year=2010, state = statecode) 
      stct$geo <- as.character(stct$GEOID)
      ccode <- substr(stct$geo,3,5)
      
      ## Have to redefine the county to include the correct state
      getdec.state <- function(county){ 
        b_10 <- get_decennial(geography = "block", 
                              variables = "P001001", 
                              year      = 2010,
                              state     = statecode,
                              county    = county, 
                              geometry  =  FALSE)
      }
      
      ##PROVE THE COUNTY FUNCTION With the corresponding state (i.e. get the blocks for each county)
      wy <- map_dfr(ccode, function(x){
        getdec.state(x)
      })
}

##PROVE STATE
stateabr <- c("nj")
blocks <- map_df(stateabr, function(x){
  getdec.statecounty(x)
})



########### ACS ############
# example from the internet 
tarr <- get_acs(geography = "tract", variables = "B19013_001",
                state = "TX", county = "Tarrant", geometry = TRUE)

v18 <- load_variables(2017, "acs5")

# Sex and Age 
  sexage <- c(paste0('B01001_00',1:9) , paste0('B01001_0',10:49))
  married <- c(paste0('B12001_00',1:9), paste0('B12001_0',10:17))
  race <- c(paste0('B02001_00',1:9), 'B02001_010')
  income <-  c(paste0('B19001_00',1:9), paste0('B19001_0',10:17))
  education <- c(paste0('B15003_00',1:9) , paste0('B15003_0',10:25))
  
  
tarr <- get_acs(year = 2018, survey="acs1", geography = "county", variable = "B19013_001",
                state = "AL", geometry = TRUE , keep_geo_vars = FALSE)

stateabr <- c("ak", "al", "ar", "az", "ca", "co", "ct", "dc", "de", "fl",
              "ga", "hi", "ia", "id", "il", "in", "ks", "ky", "la", "ma",
              "md", "me", "mi", "mn", "mo", "ms", "mt", "nc", "nd", "ne",
              "nh", "nj", "nm", "nv", "ny", "oh", "ok", "or", "pa",
              "ri", "sc", "sd", "tn", "tx", "ut", "va", "vt", "wa", "wi","wy","wv")


stateabr.x <- c("ak")
acsvars13 <- map_dfr(stateabr.x, function(stcd){
  get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education),
          state = stcd13, geometry = TRUE , keep_geo_vars = FALSE)
})
ak <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education),
        state = "ak", geometry = TRUE , keep_geo_vars = FALSE)


acsvars14 <- map_dfr(stateabr, function(stcd){
  get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education),
          state = stcd, geometry = TRUE , keep_geo_vars = FALSE)
})

acsvars15 <- map_dfr(stateabr, function(stcd){
  get_acs(year = 2015, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education),
          state = stcd, geometry = TRUE , keep_geo_vars = FALSE)
})
acsvars16 <- map_dfr(stateabr, function(stcd){
  get_acs(year = 2016, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education),
          state = stcd, geometry = TRUE , keep_geo_vars = FALSE)
})
acsvars17 <- map_dfr(stateabr, function(stcd){
  get_acs(year = 2017, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education),
          state = stcd, geometry = TRUE , keep_geo_vars = FALSE)
})

acs17vars <- as.data.frame(tarr)
acs17vars <- acs17vars[1:4]
write.csv(acs17vars, file = "H:/Nathan/frb_acs17.csv")


stateabr <- c("ak", "al", "ar", "az", "ca", "co", "ct", "dc", "de", "fl",
              "ga", "hi", "ia", "id", "il", "in", "ks", "ky", "la", "ma",
              "md", "me", "mi", "mn", "mo", "ms", "mt", "nc", "nd", "ne",
              "nh", "nj", "nm", "nv", "ny", "oh", "ok", "or", "pa",
              "ri", "sc", "sd", "tn", "tx", "ut", "va", "vt", "wa", "wi","wy","wv")


acsvars13 <- map_dfr(stateabr, function(stcd){
  get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001",
          state = stcd, geometry = FALSE , keep_geo_vars = FALSE)
})

ak13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ak" , geometry = FALSE , keep_geo_vars = FALSE)
al13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "al" , geometry = FALSE , keep_geo_vars = FALSE)
ar13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ar" , geometry = FALSE , keep_geo_vars = FALSE)
az13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "az" , geometry = FALSE , keep_geo_vars = FALSE)
ca13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ca" , geometry = FALSE , keep_geo_vars = FALSE)
co13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "co" , geometry = FALSE , keep_geo_vars = FALSE)
ct13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ct" , geometry = FALSE , keep_geo_vars = FALSE)
dc13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "dc" , geometry = FALSE , keep_geo_vars = FALSE)
de13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "de" , geometry = FALSE , keep_geo_vars = FALSE)
fl13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "fl" , geometry = FALSE , keep_geo_vars = FALSE)
ga13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ga" , geometry = FALSE , keep_geo_vars = FALSE)
hi13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "hi" , geometry = FALSE , keep_geo_vars = FALSE)
ia13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ia" , geometry = FALSE , keep_geo_vars = FALSE)
id13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "id" , geometry = FALSE , keep_geo_vars = FALSE)
il13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "il" , geometry = FALSE , keep_geo_vars = FALSE)
in13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "in" , geometry = FALSE , keep_geo_vars = FALSE)
ks13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ks" , geometry = FALSE , keep_geo_vars = FALSE)
ky13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ky" , geometry = FALSE , keep_geo_vars = FALSE)
la13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "la" , geometry = FALSE , keep_geo_vars = FALSE)
ma13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "me" , geometry = FALSE , keep_geo_vars = FALSE)
md13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "md" , geometry = FALSE , keep_geo_vars = FALSE)
me13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "me" , geometry = FALSE , keep_geo_vars = FALSE)
mi13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "mi" , geometry = FALSE , keep_geo_vars = FALSE)
mn13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "mn" , geometry = FALSE , keep_geo_vars = FALSE)
mo13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "mo" , geometry = FALSE , keep_geo_vars = FALSE)
ms13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ms" , geometry = FALSE , keep_geo_vars = FALSE)
mt13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "mt" , geometry = FALSE , keep_geo_vars = FALSE)
nc13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "nc" , geometry = FALSE , keep_geo_vars = FALSE)
nd13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "nd" , geometry = FALSE , keep_geo_vars = FALSE)
ne13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ne" , geometry = FALSE , keep_geo_vars = FALSE)
nh13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "nh" , geometry = FALSE , keep_geo_vars = FALSE)
nj13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "nj" , geometry = FALSE , keep_geo_vars = FALSE)
nm13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "nm" , geometry = FALSE , keep_geo_vars = FALSE)
nv13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "nv" , geometry = FALSE , keep_geo_vars = FALSE)
ny13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ny" , geometry = FALSE , keep_geo_vars = FALSE)
oh13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "oh" , geometry = FALSE , keep_geo_vars = FALSE)
ok13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ok" , geometry = FALSE , keep_geo_vars = FALSE)
or13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "or" , geometry = FALSE , keep_geo_vars = FALSE)
pa13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "pa" , geometry = FALSE , keep_geo_vars = FALSE)
ri13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ri" , geometry = FALSE , keep_geo_vars = FALSE)
sc13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "sc" , geometry = FALSE , keep_geo_vars = FALSE)
sd13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "sd" , geometry = FALSE , keep_geo_vars = FALSE)
tn13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "tn" , geometry = FALSE , keep_geo_vars = FALSE)
tx13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "tx" , geometry = FALSE , keep_geo_vars = FALSE)
ut13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "ut" , geometry = FALSE , keep_geo_vars = FALSE)
va13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "va" , geometry = FALSE , keep_geo_vars = FALSE)
vt13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "vt" , geometry = FALSE , keep_geo_vars = FALSE)
wa13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "wa" , geometry = FALSE , keep_geo_vars = FALSE)
wi13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "wi" , geometry = FALSE , keep_geo_vars = FALSE)
wy13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "wy" , geometry = FALSE , keep_geo_vars = FALSE)
wv13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = "B06011_001", state = "wv" , geometry = FALSE , keep_geo_vars = FALSE)


medinc13 <- rbind(ak13, al13, ar13, az13, ca13, co13, ct13, dc13, de13, fl13,
                 ga13, hi13, ia13, id13, il13, in13, ks13, ky13, la13, ma13,
                 md13, me13, mi13, mn13, mo13, ms13, mt13, nc13, nd13, ne13,
                 nh13, nj13, nm13, nv13, ny13, oh13, ok13, or13, pa13,
                 ri13, sc13, sd13, tn13, tx13, ut13, va13, vt13, wa13, wi13,wy13,wv13)


ak14 <- get_acs(year = 2017, survey="acs5", geography = "tract", variable = "B06011_001", state = "ak" , geometry = FALSE , keep_geo_vars = FALSE)
al14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "al" , geometry = FALSE , keep_geo_vars = FALSE)
ar14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "ar" , geometry = FALSE , keep_geo_vars = FALSE)
az14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "az" , geometry = FALSE , keep_geo_vars = FALSE)
ca14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "ca" , geometry = FALSE , keep_geo_vars = FALSE)
co14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "co" , geometry = FALSE , keep_geo_vars = FALSE)
ct14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "ct" , geometry = FALSE , keep_geo_vars = FALSE)
dc14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "dc" , geometry = FALSE , keep_geo_vars = FALSE)
de14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "de" , geometry = FALSE , keep_geo_vars = FALSE)
fl14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "fl" , geometry = FALSE , keep_geo_vars = FALSE)
ga14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "ga" , geometry = FALSE , keep_geo_vars = FALSE)
hi14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "hi" , geometry = FALSE , keep_geo_vars = FALSE)
ia14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "ia" , geometry = FALSE , keep_geo_vars = FALSE)
id14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "id" , geometry = FALSE , keep_geo_vars = FALSE)
il14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "il" , geometry = FALSE , keep_geo_vars = FALSE)
in14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "in" , geometry = FALSE , keep_geo_vars = FALSE)
ks14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "ks" , geometry = FALSE , keep_geo_vars = FALSE)
ky14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "ky" , geometry = FALSE , keep_geo_vars = FALSE)
la14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "la" , geometry = FALSE , keep_geo_vars = FALSE)
ma14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "me" , geometry = FALSE , keep_geo_vars = FALSE)
md14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "md" , geometry = FALSE , keep_geo_vars = FALSE)
me14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "me" , geometry = FALSE , keep_geo_vars = FALSE)
mi14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "mi" , geometry = FALSE , keep_geo_vars = FALSE)
mn14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "mn" , geometry = FALSE , keep_geo_vars = FALSE)
mo14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "mo" , geometry = FALSE , keep_geo_vars = FALSE)
ms14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "ms" , geometry = FALSE , keep_geo_vars = FALSE)
mt14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "mt" , geometry = FALSE , keep_geo_vars = FALSE)
nc14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "nc" , geometry = FALSE , keep_geo_vars = FALSE)
nd14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "nd" , geometry = FALSE , keep_geo_vars = FALSE)
ne14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "ne" , geometry = FALSE , keep_geo_vars = FALSE)
nh14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "nh" , geometry = FALSE , keep_geo_vars = FALSE)
nj14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "nj" , geometry = FALSE , keep_geo_vars = FALSE)
nm14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "nm" , geometry = FALSE , keep_geo_vars = FALSE)
nv14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "nv" , geometry = FALSE , keep_geo_vars = FALSE)
ny14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "ny" , geometry = FALSE , keep_geo_vars = FALSE)
oh14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "oh" , geometry = FALSE , keep_geo_vars = FALSE)
ok14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "ok" , geometry = FALSE , keep_geo_vars = FALSE)
or14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "or" , geometry = FALSE , keep_geo_vars = FALSE)
pa14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "pa" , geometry = FALSE , keep_geo_vars = FALSE)
ri14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "ri" , geometry = FALSE , keep_geo_vars = FALSE)
sc14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "sc" , geometry = FALSE , keep_geo_vars = FALSE)
sd14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "sd" , geometry = FALSE , keep_geo_vars = FALSE)
tn14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "tn" , geometry = FALSE , keep_geo_vars = FALSE)
tx14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "tx" , geometry = FALSE , keep_geo_vars = FALSE)
ut14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "ut" , geometry = FALSE , keep_geo_vars = FALSE)
va14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "va" , geometry = FALSE , keep_geo_vars = FALSE)
vt14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "vt" , geometry = FALSE , keep_geo_vars = FALSE)
wa14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "wa" , geometry = FALSE , keep_geo_vars = FALSE)
wi14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "wi" , geometry = FALSE , keep_geo_vars = FALSE)
wy14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "wy" , geometry = FALSE , keep_geo_vars = FALSE)
wv14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = "B06011_001", state = "wv" , geometry = FALSE , keep_geo_vars = FALSE)

medinc14 <- rbind(ak14, al14, ar14, az14, ca14, co14, ct14, dc14, de14, fl14,
                  ga14, hi14, ia14, id14, il14, in14, ks14, ky14, la14, ma14,
                  md14, me14, mi14, mn14, mo14, ms14, mt14, nc14, nd14, ne14,
                  nh14, nj14, nm14, nv14, ny14, oh14, ok14, or14, pa14,
                  ri14, sc14, sd14, tn14, tx14, ut14, va14, vt14, wa14, wi14,wy14,wv14)



medinc15 <- map_dfr(stateabr, function(stcd){
  get_acs(year = 2015, survey="acs5", geography = "tract", variable = "B06011_001",
          state = stcd, geometry = FALSE , keep_geo_vars = FALSE)
})

medinc16 <- map_dfr(stateabr, function(stcd){
  get_acs(year = 2016, survey="acs5", geography = "tract", variable = "B06011_001",
          state = stcd, geometry = FALSE , keep_geo_vars = FALSE)
})


medinc17 <- map_dfr(stateabr, function(stcd){
  get_acs(year = 2017, survey="acs5", geography = "tract", variable = "B06011_001",
          state = stcd, geometry = FALSE , keep_geo_vars = FALSE)
})

st1 <- left_join(medinc17, medinc16, by = "GEOID")
st2 <- left_join(st1, medinc15, by = "GEOID")
st3 <- left_join(st2, medinc14, by = "GEOID")
st4 <- left_join(st3, medinc13, by = "GEOID")

write.csv(st4, file = "H:/Nathan/frb_acs_medinc.csv")

