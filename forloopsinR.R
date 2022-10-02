((100-100*(0.87284))*2)/(3.70027)
100* exp(0.046*3)
(100*exp(0.03*1)*exp(0.05*1)*exp(0.058*1))
 testing 123


dtimes = c("2002-06-09 12:45:40","2003-01-29 09:30:40",
                       "2002-09-04 16:45:40","2002-11-13 20:00:40",
                       "2002-07-07 17:30:40")

df.dt <- as.data.frame(dtimes)
library(dplyr)
df.dt2 <- mutate(df.dt, prevdt=lag(dtimes , order_by = dtimes)) 
class(df.dt2$dtimes2)
df.dt2$dtimes2 <- as.Date(df.dt2$dtimes)
df.dt2 <- mutate(df.dt2, prevdt2=lag(dtimes2 , order_by = dtimes2)) 
df.dt2 <- mutate(df.dt2, prevdt2=lead(dtimes2 , order_by = dtimes2)) 

lead(1:10, 1)
lead(1:10, 2)

lag(1:10, 1)
lead(1:10, 1)

x <- runif(5)
cbind(ahead = lead(x), x, behind = lag(x))

# Use order_by if data not already ordered
df <- data.frame(year = 2000:2005, value = (0:5) ^ 2)
scrambled <- df[sample(nrow(df)), ]

wrong <- mutate(scrambled, prev = lag(value))
arrange(wrong, year)

right <- mutate(scrambled, prev = lag(value, order_by = year))
arrange(right, year)


## THIS USES LODESPULL.R butt any data would work
## REFL: https://r4ds.had.co.nz/iteration.html
# mean of each 
df <- test
output <- vector("double", ncol(df))
for (i in seq_along(df)) {
  output[[i]] <- mean(df[[i]])
}
output

## COMPONENTS OF ABOVE
seq_along(df)  ## So I guess this is just the variable list...
seq_along(df$S000) ## ROWS 
varlist <- c("SA01", "SA02")
varlist.num <- names(df) %in% varlist %>% which() ## Get the column numbers 

## TRY AGAIN
output <- vector("double", length = length(varlist.num))
for (i in varlist.num) {   ### THE seq_along will just take the first two columns 
  output[[i]] <- mean(df[[i]])
}
output ### ALMOST but lets move on...


### 21.3.1 MODIFYING an Existing Object
df <- tibble(
  a = rnorm(10),
  b = rnorm(10),
  c = rnorm(10),
  d = rnorm(10)
)
head(df)
rescale01 <- function(x) {
  rng <- range(x, na.rm = TRUE)
  (x - rng[1]) / (rng[2] - rng[1])
}

df$a <- rescale01(df$a)
df$b <- rescale01(df$b)
df$c <- rescale01(df$c)
df$d <- rescale01(df$d)
head(df)

for (i in seq_along(df)) {
  df[[i]] <- rescale01(df[[i]])
}

### OKAY SO I LOVE THIS SO FAR
  ## what if I only want to rescale a and b 
head(df)
for (i in c(1,4)) {
  df[[i]] <- rescale01(df[[i]])
}
    # OKAY SO THAT WORKED AMAZINGLY 
  ## Specify names? 
varnames <- c("a", "d") 
# This doesn't work..
for (i in (names(df) %in% varnames)) {
  df[[i]] <- rescale01(df[[i]])
}
## THIS DOES WORK 
varnum <- names(df) %in% varnames %>% which()
for (i in varnum) {
  df[[i]] <- rescale01(df[[i]])
}

## LETS SEE IF WE CAN APPLY WHAT WE LEARNED

# Make function:
test.bkp <- test
badvals <- function(var,start,end){
  var <- ifelse(var %in% start, end , var)  
}
  # Test it out 
    test$SA01.b <- badvals(test$SA01, 0 , NA)
# Make varlist
badcmas <- c("SA03", "SI03")
  badcmas.num <- names(test) %in% badcmas %>% which()
for ( i in badcmas.num) {
  test[[i]] <- badvals(test[[i]],0,NA)
}

## Edit function
  badvals2 <- function(var,start,end){
    if (is.null(start)) {
      var <- ifelse(is.na(var), end , var)  
    } else 
      var <- ifelse(var %in% start, end , var)  
  }
  test$SA03 <- badvals2(test$SA03,0,NA)
  
  
## SUM
  test$SISUM <- test$SI01 + test$SI02 + test$SI03 + test$SA02
    test$s4 <- apply(test[,c(5,10,11,12)],1,sum)
    head(test)
    mean
    
  
### I'm going to play with lapply for a second...
  lapply(badcmas, function(vars) {
    badvals(test$vars,0,NA)
  })








