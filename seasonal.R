install.packages("seasonal")
library(seasonal)
nottem
temp <- nottem
head(temp)
str(nottem)

ap <- AirPassengers
sa_series <- seas(ap, x11="")

