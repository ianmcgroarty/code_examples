library(tidycensus)
library(tidyverse)
library(stringr)
library(purrr)
census_api_key("21b3c956a5fa7ad4a4b6caecf91e5c1dedf391e4")

## CHECK OUT THE VARIABLES 
#v17 <- load_variables(2010, "sf1")
v18 <- load_variables(2017, "acs5")

#####################################################################
########### ACS ###################################################
  ## The variables Nathan deserves AND the ones he needs right now.
    sexage <- c(paste0('B01001_00',1:9) , paste0('B01001_0',10:49))
    married <- c(paste0('B12001_00',1:9), paste0('B12001_0',10:17))
    race <- c(paste0('B02001_00',1:9), 'B02001_010')
    income <-  c(paste0('B19001_00',1:9), paste0('B19001_0',10:17), 'B06011_001')
    education <- c(paste0('B15003_00',1:9) , paste0('B15003_0',10:25))

  ## The states.   
  stateabr <- c("ak", "al", "ar", "az", "ca", "co", "ct", "dc", "de", "fl",
                "ga", "hi", "ia", "id", "il", "in", "ks", "ky", "la", "ma",
                "md", "me", "mi", "mn", "mo", "ms", "mt", "nc", "nd", "ne",
                "nh", "nj", "nm", "nv", "ny", "oh", "ok", "or", "pa",
                "ri", "sc", "sd", "tn", "tx", "ut", "va", "vt", "wa", "wi","wy","wv")

  ## I'm sorry 2013 and 2014 can't be pulled in the traditional manner. 
          
  #### 2013 & 2014 ACS ####
        ak13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ak" , geometry = FALSE , keep_geo_vars = FALSE)
        al13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "al" , geometry = FALSE , keep_geo_vars = FALSE)
        ar13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ar" , geometry = FALSE , keep_geo_vars = FALSE)
        az13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "az" , geometry = FALSE , keep_geo_vars = FALSE)
        ca13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ca" , geometry = FALSE , keep_geo_vars = FALSE)
        co13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "co" , geometry = FALSE , keep_geo_vars = FALSE)
        ct13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ct" , geometry = FALSE , keep_geo_vars = FALSE)
        dc13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "dc" , geometry = FALSE , keep_geo_vars = FALSE)
        de13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "de" , geometry = FALSE , keep_geo_vars = FALSE)
        fl13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "fl" , geometry = FALSE , keep_geo_vars = FALSE)
        ga13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ga" , geometry = FALSE , keep_geo_vars = FALSE)
        hi13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "hi" , geometry = FALSE , keep_geo_vars = FALSE)
        ia13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ia" , geometry = FALSE , keep_geo_vars = FALSE)
        id13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "id" , geometry = FALSE , keep_geo_vars = FALSE)
        il13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "il" , geometry = FALSE , keep_geo_vars = FALSE)
        in13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "in" , geometry = FALSE , keep_geo_vars = FALSE)
        ks13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ks" , geometry = FALSE , keep_geo_vars = FALSE)
        ky13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ky" , geometry = FALSE , keep_geo_vars = FALSE)
        la13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "la" , geometry = FALSE , keep_geo_vars = FALSE)
        ma13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "me" , geometry = FALSE , keep_geo_vars = FALSE)
        md13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "md" , geometry = FALSE , keep_geo_vars = FALSE)
        me13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "me" , geometry = FALSE , keep_geo_vars = FALSE)
        mi13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "mi" , geometry = FALSE , keep_geo_vars = FALSE)
        mn13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "mn" , geometry = FALSE , keep_geo_vars = FALSE)
        mo13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "mo" , geometry = FALSE , keep_geo_vars = FALSE)
        ms13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ms" , geometry = FALSE , keep_geo_vars = FALSE)
        mt13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "mt" , geometry = FALSE , keep_geo_vars = FALSE)
        nc13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "nc" , geometry = FALSE , keep_geo_vars = FALSE)
        nd13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "nd" , geometry = FALSE , keep_geo_vars = FALSE)
        ne13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ne" , geometry = FALSE , keep_geo_vars = FALSE)
        nh13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "nh" , geometry = FALSE , keep_geo_vars = FALSE)
        nj13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "nj" , geometry = FALSE , keep_geo_vars = FALSE)
        nm13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "nm" , geometry = FALSE , keep_geo_vars = FALSE)
        nv13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "nv" , geometry = FALSE , keep_geo_vars = FALSE)
        ny13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ny" , geometry = FALSE , keep_geo_vars = FALSE)
        oh13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "oh" , geometry = FALSE , keep_geo_vars = FALSE)
        ok13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ok" , geometry = FALSE , keep_geo_vars = FALSE)
        or13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "or" , geometry = FALSE , keep_geo_vars = FALSE)
        pa13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "pa" , geometry = FALSE , keep_geo_vars = FALSE)
        ri13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ri" , geometry = FALSE , keep_geo_vars = FALSE)
        sc13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "sc" , geometry = FALSE , keep_geo_vars = FALSE)
        sd13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "sd" , geometry = FALSE , keep_geo_vars = FALSE)
        tn13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "tn" , geometry = FALSE , keep_geo_vars = FALSE)
        tx13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "tx" , geometry = FALSE , keep_geo_vars = FALSE)
        ut13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ut" , geometry = FALSE , keep_geo_vars = FALSE)
        va13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "va" , geometry = FALSE , keep_geo_vars = FALSE)
        vt13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "vt" , geometry = FALSE , keep_geo_vars = FALSE)
        wa13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "wa" , geometry = FALSE , keep_geo_vars = FALSE)
        wi13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "wi" , geometry = FALSE , keep_geo_vars = FALSE)
        wy13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "wy" , geometry = FALSE , keep_geo_vars = FALSE)
        wv13 <- get_acs(year = 2013, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "wv" , geometry = FALSE , keep_geo_vars = FALSE)
        
        
        acsvars13 <- rbind(ak13, al13, ar13, az13, ca13, co13, ct13, dc13, de13, fl13,
                           ga13, hi13, ia13, id13, il13, in13, ks13, ky13, la13, ma13,
                           md13, me13, mi13, mn13, mo13, ms13, mt13, nc13, nd13, ne13,
                           nh13, nj13, nm13, nv13, ny13, oh13, ok13, or13, pa13,
                           ri13, sc13, sd13, tn13, tx13, ut13, va13, vt13, wa13, wi13,wy13,wv13)
        
        
        ak14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ak" , geometry = FALSE , keep_geo_vars = FALSE)
        al14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "al" , geometry = FALSE , keep_geo_vars = FALSE)
        ar14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ar" , geometry = FALSE , keep_geo_vars = FALSE)
        az14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "az" , geometry = FALSE , keep_geo_vars = FALSE)
        ca14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ca" , geometry = FALSE , keep_geo_vars = FALSE)
        co14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "co" , geometry = FALSE , keep_geo_vars = FALSE)
        ct14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ct" , geometry = FALSE , keep_geo_vars = FALSE)
        dc14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "dc" , geometry = FALSE , keep_geo_vars = FALSE)
        de14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "de" , geometry = FALSE , keep_geo_vars = FALSE)
        fl14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "fl" , geometry = FALSE , keep_geo_vars = FALSE)
        ga14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ga" , geometry = FALSE , keep_geo_vars = FALSE)
        hi14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "hi" , geometry = FALSE , keep_geo_vars = FALSE)
        ia14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ia" , geometry = FALSE , keep_geo_vars = FALSE)
        id14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "id" , geometry = FALSE , keep_geo_vars = FALSE)
        il14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "il" , geometry = FALSE , keep_geo_vars = FALSE)
        in14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "in" , geometry = FALSE , keep_geo_vars = FALSE)
        ks14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ks" , geometry = FALSE , keep_geo_vars = FALSE)
        ky14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ky" , geometry = FALSE , keep_geo_vars = FALSE)
        la14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "la" , geometry = FALSE , keep_geo_vars = FALSE)
        ma14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "me" , geometry = FALSE , keep_geo_vars = FALSE)
        md14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "md" , geometry = FALSE , keep_geo_vars = FALSE)
        me14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "me" , geometry = FALSE , keep_geo_vars = FALSE)
        mi14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "mi" , geometry = FALSE , keep_geo_vars = FALSE)
        mn14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "mn" , geometry = FALSE , keep_geo_vars = FALSE)
        mo14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "mo" , geometry = FALSE , keep_geo_vars = FALSE)
        ms14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ms" , geometry = FALSE , keep_geo_vars = FALSE)
        mt14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "mt" , geometry = FALSE , keep_geo_vars = FALSE)
        nc14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "nc" , geometry = FALSE , keep_geo_vars = FALSE)
        nd14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "nd" , geometry = FALSE , keep_geo_vars = FALSE)
        ne14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ne" , geometry = FALSE , keep_geo_vars = FALSE)
        nh14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "nh" , geometry = FALSE , keep_geo_vars = FALSE)
        nj14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "nj" , geometry = FALSE , keep_geo_vars = FALSE)
        nm14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "nm" , geometry = FALSE , keep_geo_vars = FALSE)
        nv14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "nv" , geometry = FALSE , keep_geo_vars = FALSE)
        ny14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ny" , geometry = FALSE , keep_geo_vars = FALSE)
        oh14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "oh" , geometry = FALSE , keep_geo_vars = FALSE)
        ok14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ok" , geometry = FALSE , keep_geo_vars = FALSE)
        or14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "or" , geometry = FALSE , keep_geo_vars = FALSE)
        pa14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "pa" , geometry = FALSE , keep_geo_vars = FALSE)
        ri14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ri" , geometry = FALSE , keep_geo_vars = FALSE)
        sc14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "sc" , geometry = FALSE , keep_geo_vars = FALSE)
        sd14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "sd" , geometry = FALSE , keep_geo_vars = FALSE)
        tn14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "tn" , geometry = FALSE , keep_geo_vars = FALSE)
        tx14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "tx" , geometry = FALSE , keep_geo_vars = FALSE)
        ut14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "ut" , geometry = FALSE , keep_geo_vars = FALSE)
        va14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "va" , geometry = FALSE , keep_geo_vars = FALSE)
        vt14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "vt" , geometry = FALSE , keep_geo_vars = FALSE)
        wa14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "wa" , geometry = FALSE , keep_geo_vars = FALSE)
        wi14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "wi" , geometry = FALSE , keep_geo_vars = FALSE)
        wy14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "wy" , geometry = FALSE , keep_geo_vars = FALSE)
        wv14 <- get_acs(year = 2014, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education), state = "wv" , geometry = FALSE , keep_geo_vars = FALSE)

acsvars14 <- rbind(ak14, al14, ar14, az14, ca14, co14, ct14, dc14, de14, fl14,
                   ga14, hi14, ia14, id14, il14, in14, ks14, ky14, la14, ma14,
                   md14, me14, mi14, mn14, mo14, ms14, mt14, nc14, nd14, ne14,
                   nh14, nj14, nm14, nv14, ny14, oh14, ok14, or14, pa14,
                   ri14, sc14, sd14, tn14, tx14, ut14, va14, vt14, wa14, wi14,wy14,wv14)

  #### ACS cont. ####
    acsvars15 <- map_dfr(stateabr, function(stcd){
      get_acs(year = 2015, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education),
              state = stcd, geometry = FALSE , keep_geo_vars = FALSE) 
    })
    acsvars16 <- map_dfr(stateabr, function(stcd){
      get_acs(year = 2016, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education),
              state = stcd, geometry = FALSE , keep_geo_vars = FALSE)
    })
    acsvars17 <- map_dfr(stateabr, function(stcd){
      get_acs(year = 2017, survey="acs5", geography = "tract", variable = c(sexage, married, race, income, education),
              state = stcd, geometry = FALSE , keep_geo_vars = FALSE)
    })
    
  ## Gotta rename to keep it sane!
    names(acsvars17) <- c("GEOID","NAME", "Variable","estimate17", "moe17")
    names(acsvars16) <- c("GEOID","NAME", "Variable","estimate16", "moe16")
    names(acsvars15) <- c("GEOID","NAME", "Variable","estimate15", "moe15")
    names(acsvars14) <- c("GEOID","NAME", "Variable","estimate14", "moe14")
    names(acsvars13) <- c("GEOID","NAME", "Variable","estimate13", "moe13")
    
  ## Join them all together!
    st1 <- left_join(acsvars17, acsvars16, by = c("GEOID", "Variable"))
    st2 <- left_join(st1, acsvars15, by = c("GEOID", "Variable"))
    st3 <- left_join(st2, acsvars14, by = c("GEOID", "Variable"))
    st4 <- left_join(st3, acsvars13, by = c("GEOID", "Variable"))

  ## Save that bad boi
    write.csv(st4, file = "/share/cfi-nathan/Ian/fraud_data/frb_acs_ian10.csv")




########################################################################################
############ CENSUS DATA  ##############
### See Data/censuspulling.R - for development
  ## So you can't just pull the block level data by state. You have to pull be county. 
  ### STATE FUNCTION
    getdec.statecounty <- function(statecode){ 
     
      # 1. Pull the counties for the state
        stct <- get_decennial(geography = "county" , variables = "P001001" , year=2010, state = statecode) 
        stct$geo <- as.character(stct$GEOID)
      
      # 2. Get a list of county codes in that state
        ccode <- substr(stct$geo,3,5)
      
      # 3. Redefine the sate function to have the correct state 
        getdec.state <- function(countycode){ 
          b_10 <- get_decennial(geography = "block", 
                                variables = "P001001", 
                                year      = 2010,
                                state     = statecode,
                                county    = countycode, 
                                geometry  =  FALSE)
          print(countycode)
          return(b_10)
          
        }
        
      ## 4. Get the blocks for each county
        wy <- map_dfr(ccode, function(x){
          getdec.state(x)
          #Sys.sleep(10) ## This is useful if you are worries about over crowding the api. 
        })
        return(wy)
    }
  


#### THIS IS SUPER FINIKY SO WATCH OUT. ####
  ### So here is what is going on (resonably tested hypothesis)
  # The census api gets over crowded and times out. So running it after 5:30 is 
  # typically the best bet. I'm going to keep running things like this because I'm almost done
  # but I bet you could use the funciton I created. --- UPDATE YOU TOTALLY CAN
  # You'll just have to try each state until it work the coallate at the end. 
    ak <- getdec.statecounty("ak") 
    al <- getdec.statecounty("al") 
    ar <- getdec.statecounty("ar") 
    az <- getdec.statecounty("az") 
    ca <- getdec.statecounty("ca") 
    co <- getdec.statecounty("co") 
    ct <- getdec.statecounty("ct") 
    dc <- getdec.statecounty("dc") 
    de <- getdec.statecounty("de") 
    fl <- getdec.statecounty("fl")
    ga <- getdec.statecounty("ga")
    hi <- getdec.statecounty("hi") 
    ia <- getdec.statecounty("ia")
    id <- getdec.statecounty("id") 
    ins <- getdec.statecounty("in") #in is a function and can't be a data name
    il <- getdec.statecounty("il") 
    ks <- getdec.statecounty("ks") 
    ky <- getdec.statecounty("ky") 
    la <- getdec.statecounty("la") 
    ma <- getdec.statecounty("ma") 
    md <- getdec.statecounty("md") 
    me <- getdec.statecounty("me") 
    nd <- getdec.statecounty("nd")  
    mi <- getdec.statecounty("mi") 
    mn <- getdec.statecounty("mn") 
    mo <- getdec.statecounty("mo") 
    ms <- getdec.statecounty("ms") 
    mt <- getdec.statecounty("mt") 
    nc <- getdec.statecounty("nc") 
    ne <- getdec.statecounty("ne") 
    nj <- getdec.statecounty("nj")  
    nh <- getdec.statecounty("nh") 
    nm <- getdec.statecounty("nm") 
    nv <- getdec.statecounty("nv") 
    ny <- getdec.statecounty("ny") 
    oh <- getdec.statecounty("oh") 
    ok <- getdec.statecounty("ok") 
    or <- getdec.statecounty("or") 
    pa <- getdec.statecounty("pa") 
    ri <- getdec.statecounty("ri") 
    sc <- getdec.statecounty("sc") 
    sd <- getdec.statecounty("sd") 
    tn <- getdec.statecounty("tn") 
    tx <- getdec.statecounty("tx") 
    ut <- getdec.statecounty("ut") 
    va <- getdec.statecounty("va") 
    vt <- getdec.statecounty("vt") 
    wa <- getdec.statecounty("wa") 
    wi <- getdec.statecounty("wi") 
    wv <- getdec.statecounty("wv") 
    wy <- getdec.statecounty("wy") 
    
    ### Bind the States Together!
      blocks.c <- rbind(ak, al, ar , co, ct, dc, hi, id, ins , la, ma,
                        md, me, mi, mn, mo, ms, mt, nc, nd , 
                        tx, ne, az , ca, de , fl , ga , ia , il, ks , ky, 
                        nj,nh, nm, nv, ny, oh, ok, or, pa,
                        ri, sc, sd, tn, ut, va, vt, wa, wi, wv, wy)
    
    ## Drop vriables
      census10.pop <- blocks.c[,c(1,4)]
      census10.pop$GEOID <- str_pad(census10.pop$GEOID , 15 , pad = 0)
      names(census10.pop) <- c("GEOID" , "TotPop")   
    
    # Get rid of this guy who keep crashing R
      blocks.c <- 1

#### STORE CENSUS DATA ####
  ## I run this on Spark so that I can merge with the RAC data more easily. But you just have to save
    # and put it somewhere. 

## to edgenode   
#write.csv(census10.pop, file="/home/c1imm01/nathan/census10pop.csv")
