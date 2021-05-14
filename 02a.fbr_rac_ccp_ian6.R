cat("\014")
# 02a.fbr_rac_ccp_ian6.R 
# This code is the second in the 6 part series for the Fraud Breach Project with Nathan.
#   It is preceeded by:
#     - 01.acs_censuspop_pull.R
#   It is followed by:
#     - 02b.radarprep_ian3.do
#     - 03.CCP_ACS_AGGREG_IAN8.do
# #
# # The goals of this code are numerous
#   1. Pull the RAC data(
#   2. Merge the RAC data and the Census data pulled in 01.acs_censuspop_pull.R
#   3. Identify "High Fed tracts" --- we are using >= 17.5 % federal workers/total workers
#   4. Identify control tracts that surround high fed blocks.
#   5. Plot the high fed and control blocks
#   6. Using CCP pull, identify individuals living in the specifed tracts (high fed and control) 
#       during the treatment period. 
#
### Starting Data
# 1. "/home/c1imm01/nathan/census10pop.csv"
#   - "census10.pop"
#   - This data was compiled in 01.acs_censuspop_pull.R
#   - It contains the total population from the decenial census for all blocks in the US. 
#   - In the  01.acs_censuspop_pull.R I move this data to edgenode so that I can pull it into sparkR if need be. 
#      You could definitely just transfer
#      any other way, but it is kind of a bigger file and so I feel like this is easiest!
# ### ENDING DATA 
#   1. "/home/c1imm01/nathan/jt_rac_pop2.csv"
#     - "jt.rac.pop.export"
#     - Contaings tract level data for all tracts available in LODES-RAC data, with number of federal workers and total workers, and total population
#       for 2015. 
#   2. "/home/c1imm01/nathan/c12tr_fedwork_hf20_cids5.csv"
#     - "cid_blocks"
#     - Contains all cids living in the highfed or surrounding areas
#   3. "/home/c1imm01/c12_tr_fed_work_hf.csv"
#     - "allblocks"
#     - All of the highfed and surrounding tracts
#   4. "/home/c1imm01/nathan/c12_tr175_twomile.csv"
#     - "twomile"
#   5. "/home/c1imm01/nathan/c12_tr175_onemile.csv" 
#     - "onemile"
#   6. "/home/c1imm01/nathan/c12_tr175_contiguous.csv"
#     - "contiguous"

########################################################################################
#### PREAMBLE ####
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
#library(tmap)
#library(tmaptools)
#library(shinyjs)
library(cdlTools)
Sys.setenv(HTTP_PROXY = "c1proxy.frb.org:8080")
Sys.setenv(HTTPS_PROXY = "c1proxy.frb.org:8080")
Sys.setenv(SPARK_HOME = "/usr/hdp/current/spark2-client")
Sys.setenv(SPARK_CONF_DIR= "/usr/hdp/current/spark2-client/conf/")

library(rJava)
library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))

###############  ########   CONNECTION   ########  ################
#(6G,12G,3,30,6G,50000,10G) (6g,4g,3,4,6g,50000,3g)
sparkR.start <- function(drmem, exmem, excore , exinst, memov , contime, maxsize) { 
  sparkR.session(master = "yarn", sparkConfig = list(spark.driver.memory = drmem,
                                                     spark.executor.memory= exmem,
                                                     spark.executor.cores= excore,
                                                     spark.executor.instances= exinst,
                                                     spark.executor.memoryOverhead= memov ,
                                                     spark.r.backendConnectionTimeout = contime,
                                                     spark.driver.maxResultSize = maxsize,
                                                     yarn.scheduler.fair.preemption = 'false'))
}
setLogLevel("ERROR")




########################################################################################
#### Load in census population data ####
### NOTES: So the census pop isn't *strictly* necessary for this anymore, but it is part of the code and I want to keep it
# for long term record keeping. 
  
  sparkR.start("6g","4g","3","30","6",'50000','3g') #>20
    ##loads file to hdfs
      system("hdfs dfs -put /home/c1imm01/nathan/census10pop.csv /user/c1imm01/census10pop.csv")
    ##creates dataframe from csv file in hdfs
      census10.pop <- read.df("/user/c1imm01/census10pop.csv", "csv", header="true", inferSchema="true")
      census10.pop <- collect(census10.pop)
  sparkR.stop()

########################################################################################
############ RESIDENCE AREA CHARACTERISTICS ##############
  ### We can pull the RAC LODES Data using the API but we have to pull it for each state. Seperately, and there is no RAC for WY 
  # for 2015. 
  
  ### Write the Get URL Function: Creates a URL for each state. 
  # FOR RAC we want Segment = s000 sinc this is all workers 
    getRAC <- function(state,jt) {return(paste0("https://lehd.ces.census.gov/data/lodes/LODES7/", state 
                                              ,"/rac/", state , "_rac_S000_", jt , "_2015.csv.gz"))}
  
  ### write the get rac function - Uses the URL function and pulls from the API. 
    get.rac <- function(abbr, jt){
        load.rac <- getRAC(abbr, jt)
        download.file(load.rac, destfile = "/home/c1imm01/nathan/ak_rac15.csv.gz")
        rac <- read.csv("/home/c1imm01/nathan/ak_rac15.csv.gz")
        hmm2 <-  rbind(rac)
        return(hmm2)
    }
    
  ### States to use! 
  ## 50 states + DC- WY 
    stateabr <- c("ak", "al", "ar", "az", "ca", "co", "ct", "dc", "de", "fl",
                  "ga", "hi", "ia", "id", "il", "in", "ks", "ky", "la", "ma",
                  "md", "me", "mi", "mn", "mo", "ms", "mt", "nc", "nd", "ne",
                  "nh", "nj", "nm", "nv", "ny", "oh", "ok", "or", "pa",
                  "ri", "sc", "sd", "tn", "tx", "ut", "va", "vt", "wa", "wi", "wv")
  
  ### Pull Both the Federal Workers and All workers. jt00 is all workers jt04 is federal workers.
    jt00 <- map_dfr(stateabr, function(x){
        get.rac(x,"JT00") %>% 
          dplyr::mutate(stateid = x)
      })
    
    jt04 <- map_dfr(stateabr, function(x){
        get.rac(x,"JT04") %>% 
          dplyr::mutate(stateid = x)
      })
      
  ## Just need the GEOID and the number of workers
  jt04 <- jt04[,c(1,2)]
  jt00 <- jt00[,c(1,2)]

########################################################################################
############ MERGING ##############
  # Here I merge the RAC and the census data together to create the exported rac file. 
      
    ## Format GEOID for Census population data
      census10.pop$GEOID <- str_pad(census10.pop$GEOID, 15, pad=0) 
      census10.pop <- census10.pop[,c(2,3)] # have to drop the _c0 variable?
      #10,815,977 blocks in total
    
    #### PREP RAC
      jt04$h_geocode <- str_pad(jt04$h_geocode, 15, pad=0)    
      jt00$h_geocode <- str_pad(jt00$h_geocode, 15, pad=0)    
      
    #### Merge RAC data - inner join is okay since jt04 C jt00
      jt.rac <- inner_join(jt04,jt00,by="h_geocode")
      names(jt.rac) <- c("GEOID" , "aj04", "aj00")   
      jt00 <- 1 ## Get rid of this guy who keeps crashing R
      jt04 <- 1
      
    #### Merge RAC and Census Population Data.
      jt.rac.popA <- dplyr::inner_join(jt.rac, census10.pop, by="GEOID")  
        # 632,514  observations implyig that there are some rac not in census? 
        # 641,350 - 623,514 = 17,836 ~ 2.8% of rac blocks with isn't much but I can't think of why this might be? 
      census10.pop <- 1     ## Get rid of this guy who keeps crashing R
      
    ## BRING IT UP TO TRACT LEVEL (We used to have the block level but now we collapse to tract level.)
      jt.rac.popA$tractid <- substr(jt.rac.popA$GEOID,1,11)  
      jt.rac.pop <- jt.rac.popA %>% dplyr::group_by(tractid) %>% 
          summarise(aj04 = sum(aj04), aj00 = sum(aj00), TotPop = sum(TotPop))
         ## 68,584

########################################################################################
############## Quick Analysis  #########################
    ## fed workers as % of workers 
      jt.rac.pop$pctaj04 <- 100*(jt.rac.pop$aj04 / jt.rac.pop$aj00)
        sum(as.numeric(jt.rac.pop$pctaj04 >= 10 & (jt.rac.pop$aj00 != 0))) # 3556
        sum(as.numeric(jt.rac.pop$pctaj04 >= 20 & (jt.rac.pop$aj00 != 0))) # 888
        sum(as.numeric(jt.rac.pop$pctaj04 >= 50 & (jt.rac.pop$aj00 != 0))) # 165
        sum(as.numeric(jt.rac.pop$pctaj04 >= 100 & (jt.rac.pop$aj00 != 0)))#  52
        
    ## fed workers as % of total population
      jt.rac.pop$pctpop04 <- 100*(jt.rac.pop$aj04 / jt.rac.pop$TotPop)    
        sum(as.numeric(jt.rac.pop$pctpop04 >= 10 & (jt.rac.pop$TotPop != 0))) # 681
        sum(as.numeric(jt.rac.pop$pctpop04 >= 20 & (jt.rac.pop$TotPop != 0))) # 189
        sum(as.numeric(jt.rac.pop$pctpop04 >= 50 & (jt.rac.pop$TotPop != 0))) # 59
        sum(as.numeric(jt.rac.pop$pctpop04 >= 100 & (jt.rac.pop$TotPop != 0))) #19
        
    ## workers as a % of total population 
      jt.rac.pop$pctpop00 <- 100*(jt.rac.pop$aj00 / jt.rac.pop$TotPop)
        sum(as.numeric(jt.rac.pop$pctpop00 >= 10 & (jt.rac.pop$TotPop != 0))) # 68296
        sum(as.numeric(jt.rac.pop$pctpop00 >= 20 & (jt.rac.pop$TotPop != 0))) # 67499
        sum(as.numeric(jt.rac.pop$pctpop00 >= 50 & (jt.rac.pop$TotPop != 0))) # 23893
        sum(as.numeric(jt.rac.pop$pctpop00 >= 100 & (jt.rac.pop$TotPop != 0))) # 228
        
    ## Total Population Problem - many of the tracts that are marked highfed have almost no people in them!
        summary(jt.rac.pop$pctaj04)
        jt.rac.pop %>% summary(.pctaj04) ## total pop mean = 1411
        jt.rac.pop %>% dplyr::filter(jt.rac.pop$pctpop04 > 20) %>% summary() ## total pop mean = 2
        jt.rac.pop %>% dplyr::filter(jt.rac.pop$pctaj04 > 20) %>% summary() ## Total pop mean = 75.55
        
        sum(as.numeric(jt.rac.pop$aj00 > jt.rac.pop$TotPop & (jt.rac.pop$TotPop != 0))) # 202
        totpop.t1 <- jt.rac.pop %>% dplyr::filter(jt.rac.pop$pctpop04 >= 20) 
        sum(as.numeric(totpop.t1$aj00 > totpop.t1$TotPop  & (totpop.t1$TotPop != 0))) #70
        totpop.t2 <- jt.rac.pop %>% dplyr::filter(jt.rac.pop$pctaj04 >= 20 & (jt.rac.pop$aj00 != 0)) 
        sum(as.numeric(totpop.t2$aj00 > totpop.t2$TotPop & (totpop.t2$TotPop != 0))) #17

########################################################################################
############ RAC EXPORT ##############

  ### Change for the tigris block names
    names(jt.rac.pop) <- c("GEOID",  "aj04", "aj00" , "TotPop", "pctaj04" , "pctpop04", "pctpop00" )  
  
  ## I export all RAC data not just highfed blocks so that we can use them as weights if we want!
  ## Just want to do a little leg work first!
    jt.rac.pop.export <- jt.rac.pop
    jt.rac.pop.export$stcode      <- substr(jt.rac.pop.export$GEOID,1,2)
    jt.rac.pop.export$stateabr    <- apply(jt.rac.pop.export , 1, function(row) fips(row['stcode'] , to='Abbreviation'))
    jt.rac.pop.export$countycode  <- substr(jt.rac.pop.export$GEOID,3,5)
    jt.rac.pop.export$censustract <- substr(jt.rac.pop.export$GEOID,6,11)
    #jt.rac.pop.export$censusblock <- substr(jt.rac.pop.export$GEOID,12,15)
    
  ## Write the file 
    write.csv(jt.rac.pop.export, file="/home/c1imm01/nathan/jt_rac_pop2.csv")
  
########################################################################################
############ HIGH FED ##############
  ## We have to use GEOID10 as the name here.
    names(jt.rac.pop) <- c("GEOID10",  "aj04", "aj00" , "TotPop", "pctaj04" , "pctpop04", "pctpop00" )
  
  ### HIGH FED CUT OFF 
    # We've brought it up to the tract level. We are using pctaj04 >= 17.5
    rac.highfed    <- jt.rac.pop %>% dplyr::filter(jt.rac.pop$pctaj04 >= 17.5)
    rac.highfed$stcode <- substr(rac.highfed$GEOID10,1,2)

##########################################################################################
############ GEOGRAPHIC ##############
  ### TRACTS ###
    ## Need to redefine the state list to include WY since it will have control tracts
      stateabr <- c("ak" ,"al", "ar", "az", "ca", "co", "ct", "dc", "de", "fl",
                    "ga", "ia", "id", "il", "in", "ks", "ky", "la", "ma",
                    "md", "me", "mi", "mn", "mo", "ms", "mt", "nc", "nd", "ne",
                    "nh", "nj", "nm", "nv", "ny", "oh", "ok", "or", "pa", "hi",
                    "ri", "sc", "sd", "tn", "tx", "ut", "va", "vt", "wa", "wi", "wy", "wv")
      
    ### Tract Function - to get tracts from tigris
      tractfetch <- function(statecode) {
        st.blocks <- tracts(statecode , year=2010) 
      }
    
    ## Run Function 4 all states
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
                           ,ustracts[[49]],ustracts[[50]],ustracts[[51]] )
      
  ### NEARBY FUNCTION  ###
    ## The distance from the highfed borders. And if you want to use centroids or not.
    ## If you don't use centroids, border intesections are used. 
      mapper_nostate <- function(distence, centroidz=FALSE) {
        
        # Transform the blocks to get the right CRS
          st.blocks <- ustracts2 %>%  st_transform(., 3488) %>% .[1:5]
        
        # Diplay the total number of blocks in the state
        #print(nrow(st.blocks)) - #I USED THIS TO CREATE blockids when we did it state by state. It is legecy and no longer needed. 
        
        # Only want highfed tracts
          bk.rac <- inner_join(st.blocks, rac.highfed, by="GEOID10")
        
        # Expand the borders of the highfed blocks.
        ## in meters^2 soooooo idk its like a yard or something #murica #imperialsystem
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
          print(nrow(nearvec))#I USED THIS TO CREATE blockids when we did it state by state. It is legecy and no longer needed. 
          return(nearvec)
      }
      
      
  ### Nathan wants 3 matches ###
    # We want to save each seperately so we can have identifiers in the stata code. 
    # 1. Contiguous - basically all of the border tracts. 
    # The way to do this is to buffer the highfed tracts just a little and then run an interscetion
    # for any tract boarders that interscet that buffer. 
      contiguous2 <- mapper_nostate( 100,  centroidz=FALSE)
      write.csv(contiguous2, file="/home/c1imm01/nathan/c12_tr175_contiguous.csv")  
      
    # 2. 1 mile centroids
    # draw a one mile circle from the borders and take all of the block centroids within that buffer. 
      onemile2    <- mapper_nostate( 1609, centroidz=TRUE)
      write.csv(onemile2, file="/home/c1imm01/nathan/c12_tr175_onemile.csv")    
      
    # 3. 2 mile centroids
      twomile2    <- mapper_nostate( 3218, centroidz=TRUE)
      write.csv(twomile2, file="/home/c1imm01/nathan/c12_tr175_twomile.csv")

    # Put them all together
      alltractsA <- rbind(contiguous2, onemile2, twomile2) %>% dplyr::distinct()


## IF you are concerned about the 50+ warnings here is every single one of them :). It just means that the earth is round. 
  #1: attribute variables are assumed to be spatially constant throughout all geometries
## Why did I print the blocks and nearvec? Well this gives the percent of total blocks for the state that we are pulling

## sanity Check to makesure we are getting all of the highfed blocks
  #  sanity <- inner_join(allblocksA, rac.highfed, by="GEOID10")


############################################################
############ Prepare the blocks for CCP Merge ##############
  
  ## Some merge prep  
    alltracts <- alltractsA[,c(1,2,3)] 
    names(alltracts) <- c("state", "county_code", "census_tract")
  
    alltracts$state <- str_pad(alltracts$state, 2, pad=0) 
    alltracts$county_code <- str_pad(alltracts$county_code, 3, pad=0)
    alltracts$census_tract <- str_pad(alltracts$census_tract, 6, pad=0)
    #allblocks$census_block <- str_pad(allblocks$census_block, 4,pad=0)
  
  ## State is fips in this data but abbreviation in CCP. 
    alltracts$stateabr <- apply(alltracts , 1, function(row) fips(row['state'] , to='Abbreviation'))
  
  # Save it because it takes awhile --- watch out this name is used in the ccp pull so make sure you change it there if you change it here. 
    write.csv(alltracts, file="/home/c1imm01/nathan/c12_tr_fed_work_hf.csv")

############################################################
############ PLOTS  ########################################
  ### COUNTIES   
    us.county <- counties(year=2010)
    
    ## HIGH FED
      rac.highfed2 <- rac.highfed
      rac.highfed2$GEOID10 <- substr(rac.highfed2$GEOID10,1,5)  
      
    ## High fed counties
      highfed.county <- inner_join(us.county,rac.highfed2, by="GEOID10") 
      
      # No Alaska and Hawaii cuz they r lame
        highfed.county_noak <- dplyr::filter(highfed.county, !highfed.county$STATEFP10 %in% c("02","15") )
        us.county.noak <- dplyr::filter(us.county, !us.county$STATEFP10 %in% c("02","15") )
    
    ## Control Tracts
      contcounties <- alltractsA
      
      # We want the counties that are in the data but are not highfed
        contcounties$GEOID10 <- substr(contcounties$GEOID10,1,5)  
        contcounties <- anti_join(contcounties, highfed.county , by="GEOID10")
        contcounties <- contcounties[4] %>% dplyr::distinct()
        contcounties <- inner_join(us.county, contcounties, by="GEOID10")
    
    ## Plot with Controls (Just do first line for no borders)
      # With Alaska and Hawaii
        plot(highfed.county[0], col='#98F3EB' , reset=FALSE, main="High Fed Tracts (County) >= 17.5%") 
        plot(contcounties[0], col="green", add=TRUE)
      # Without Alaska and Hawaii
        plot(highfed.county_noak[0], col='red' , reset=FALSE, main="High Fed Tracts (County) >= 17.5%") 
        plot(contcounties[0], col="green", add=TRUE)
    
    ## Plot with borders
      # With Alaska and Hawaii
        plot(highfed.county[0], col='red' , reset=FALSE, main="High Fed Tracts (County) >= 17.5%")
        plot(us.county[0], add=TRUE)
      # Without Alaska and Hawaii
        plot(us.county.noak[0], col='#98F3EB', border='white', reset=FALSE)
        plot(highfed.county_noak[0], col='red' , add=TRUE)

  
  ### Tracts
    ## HIGH FED
    rac.highfed3 <- rac.highfed
    
    ## High fed tracts
      highfed.tracts <- inner_join(ustracts2, rac.highfed3 , by="GEOID10") 
      
      # No Alaska and Hawaii
        highfed.tracts.noak <- dplyr::filter(highfed.tracts, !highfed.tracts$STATEFP10 %in% c("02","15") )
        ustracts.noak <- dplyr::filter(ustracts2, !ustracts2$STATEFP10 %in% c("02","15") )
    
    ## Control tracts
      contracts <- alltractsA
      
      # We want the tracts that are in the data but are not highfed
        contracts <- anti_join(contracts, highfed.tracts , by="GEOID10")
        contracts <- contracts[4] %>% dplyr::distinct()
      
      #Get the geographic data for those tracts
        contracts <- inner_join(ustracts2, contracts, by="GEOID10")
      
    
    ## Plot with Controls (Just do first line for no borders)
      # With Alaska and Hawaii
        plot(highfed.tracts[0], col='red' , reset=FALSE, main="High Fed Tracts >= 17.5%") 
        plot(contracts[0], col="green", add=TRUE)
      # Without Alaska and Hawaii
        plot(highfed.tracts.noak[0], col='red' , reset=FALSE, main="High Fed Tracts >= 17.5%") 
        plot(contracts[0], col="green", add=TRUE)
      
    ## Plot with borders
      # With Alaska and Hawaii
        plot(highfed.tracts[0], col='red' , reset=FALSE, main="High Fed Tracts >= 17.5%")
        plot(ustracts2[0], add=TRUE)
      # Without Alaska and Hawaii ---- WE HAVE A WINNER NATHAN FINALLY LIKES THIS ONE :)
        plot(ustracts.noak[0], col='white' , border = '#98F3EB' , reset=FALSE)
        plot(contracts[0], col="#7BB9F0",border='#7BB9F0' , add=TRUE)
        plot(highfed.tracts.noak[0], col='#0023FF' ,border='black' , add=TRUE )

  ### Plot by PCTAJ04
    alltr <- inner_join(ustracts2,jt.rac.pop, by="GEOID10")
    
    ggplot(data=alltr) + 
      geom_sf(aes(fill = pctaj04)) + 
      scale_fill_viridis_c(option = "plasma", trans="sqrt") + 
      ggtitle("Percent Federal Workers/Total Workers")






















##### LAB ROOM ##########

dc.blocks <- blocks("dc" , year=2010)       # 6507
dc.blocks00 <- blocks("dc" , year =2000)    # 5674

allblocks <- dc.blocks[,c(1,2,3,4)] %>% st_drop_geometry()
names(allblocks) <- c("state", "county_code", "census_tract", "census_block")
allblocks$state <- str_pad(allblocks$state, 2, pad=0) 
allblocks$county_code <- str_pad(allblocks$county_code, 3, pad=0)
allblocks$census_tract <- str_pad(allblocks$census_tract, 6, pad=0)
allblocks$census_block <- str_pad(allblocks$census_block, 4,pad=0)

## State is formated as AK 
allblocks$stateabr <- apply(allblocks , 1, function(row) fips(row['state'] , to='Abbreviation'))



write.csv(allblocks, file="/home/c1imm01/frb_hf20_dcblks.csv")
system("hdfs dfs -rm /user/c1imm01/frb_hf20_dcblks.csv")
system("hdfs dfs -put  /home/c1imm01/frb_hf20_dcblks.csv /user/c1imm01/frb_hf20_dcblks.csv")    
dcblocks <- read.df("/user/c1imm01/frb_hf20_dcblks.csv", "csv", header="true", inferSchema="true")
createOrReplaceTempView(dcblocks, "dcblocks")


cid_blocks <- SparkR::sql("SELECT DISTINCT a.state,a.county_code, a.census_tract, a.census_block
                          FROM orc_ccp.s_eqccp_orc a
                          INNER JOIN dcblocks b ON
                          a.state = b.stateabr AND 
                          a.county_code10 = b.county_code AND 
                          a.census_tract10 = b.census_tract AND
                          a.census_block10 = b.census_block
                          WHERE flag = 'P' 
                          AND qtr >= '2015-01-31'
                          AND qtr <= '2018-12-31' 
                          ")
nrow(cid_blocks)
head(dcblocks)


plot(nearby[0] , col = "blue" , reset = FALSE )
plot(dct[0] , add=TRUE)
plot(dc.bk.rac["pctaj04"])
summary(dc.bk.rac$pctaj04)


summary(jt.rac.pop$pctaj04)
quantile(jt.rac.pop$pctaj04, c(0.25, 0.5, 0.75, 0.9, 0.95, 0.99))
summary(dcall$pctaj04)
quantile(dcall$pctaj04, c(0.25, 0.5, 0.75, 0.9, 0.95))
summary(rac.nonzero$pctaj04)
quantile(rac.nonzero$pctaj04, c(0.25, 0.5, 0.75, 0.9, 0.95))






stateabr.x <- c("dc" , "va", "md")
dc <- tracts("dc", year=2010)
md <- tracts("md", year=2010)
va <- tracts("va", year=2010)

dcmetro <- rbind(dc,md,va)
dcmetro <- dc
dchf <- inner_join(dcmetro,rac.highfed15, by="GEOID10")
dcall <- inner_join(dcmetro,jt.rac.pop, by="GEOID10")


plot(dcall["pctaj04"])


ggplot(data=dcall) + 
  geom_sf(aes(fill = pctaj04)) + 
  scale_fill_viridis_c(option = "plasma", trans="sqrt") + 
  ggtitle("Percent Federal Workers/Total Workers - DC")

plot(dchf[0], col='red' , reset=FALSE, main="High fed Tracts >= 10% DC,MD,VA")
plot(dcmetro[0], add=TRUE)

vec.pctaj04 <- dcall$pctaj04
vec.pctaj04 <- vec.pctaj04[vec.pctaj04 >10 ]
vec.pctaj04 <- vec.pctaj04[vec.pctaj04 < 50 ]

plot(dcall$aj04, dcall$pctaj04, main="Scatter Federal Workers pct Highfed ") 
abline(h=17.5 , col='red')

hist(vec.pctaj04)



# DOING ALL BLOCKS IS JUST TOOOOO BIG NOTHING WORKS ON IT
#allblocks <- map_df(stateabr, function(x){
#  st.blocks <- blocks(x)
#})

#### TESTING WITH DC ###
## PULL BLOCKSc
dc.blocks <- tracts("dc", year=2010)

# Only want the cool variables
dc.blocks <- dc.blocks[1:5]

# Gotta reproject that bad boi so they can git buff
dct <- st_transform(dc.blocks, 3488)

# Want to get the midpoint dots 
#dct.p <- st_centroid(dct, of_largest_ploygon = TRUE) %>% st_transform(., 3488)

# Only want the fun blocks
dc.bk.rac <- inner_join(dct, rac.highfed, by="GEOID10")

# buffer those bad bois
### WATCH This is in meters, so 10,000 = 10 km
# UPDT Nathan only wants 3 now. 
dc.bk.rac.5k <- st_buffer(dc.bk.rac, dist = 3000)

# Intersection obvi
nearby <- st_intersection(dct, dc.bk.rac.5k)

# only want the ids & drop doubles 
nearvec <-  nearby[1:5] %>% st_drop_geometry() %>% dplyr::distinct() %>% dplyr::arrange(., .$GEOID10)
# It should contain the block itself but I should double check. 




## highfed by state
hf2 <- rac.highfed
hf2$one <- 1
hf2$stateabr <- apply(rac.highfed , 1, function(row) fips(row['stcode'] , to='Abbreviation'))
hf3 <- hf2[,c(9,10)]

hf4 <- hf3 %>% dplyr::group_by(hf3$stateabr) %>% summarise(sum(one))
write.csv(hf4, file="/home/c1imm01/nathan/hfb20_tracts.csv")


## Old posibilities but they are unneeded now. 
rac.highfed15  <- jt.rac.pop %>% dplyr::filter(jt.rac.pop$pctaj04 >= 16.3)
rac.highfed10  <- jt.rac.pop %>% dplyr::filter(jt.rac.pop$pctaj04 >= 10)
rac.nonzero    <- jt.rac.pop %>% dplyr::filter(jt.rac.pop$aj04 > 0)
