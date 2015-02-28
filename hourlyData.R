options(stringsAsFactors = FALSE, max.print = 200)


library(reshape2)
library(dplyr)
library(ggplot2)
library(rvest)
library(sp)
library(rgdal)

ffA <- html("http://uk-air.defra.gov.uk/data/toeea/nrt/")
anodes<-ffA %>% html_nodes("a") %>% html_text() 

file <- anodes[length(anodes)]

## actually all we need is the last file with the last measuramets
lastMeas <- read.table(paste0("http://uk-air.defra.gov.uk/data/toeea/nrt/",file), skip = 7, header = TRUE, sep = ";", na.strings = "-999")
# lastMeas[lastMeas == -999] <- NA# x11()
plot(lastMeas[,c("Longitude","Latitude")])
whichCol <- 8 + min(which(colMeans(lastMeas[,10:33]) == -111))

lastMelt <- melt(data = lastMeas, id.vars = c("code","name","Component","type","area","Altitude","Longitude","Latitude"),
                 measure.vars =  names(lastMeas)[whichCol])
findat <- dcast(lastMelt, formula = Longitude+Latitude+name+type+area+Altitude ~ Component)

# plot(lastMeas[,c("Longitude","Latitude")], col= ifelse(lastMeas$type == "background",2,1))

stSpat <- SpatialPoints(findat[,c("Longitude","Latitude")])
stSpat_df <- SpatialPointsDataFrame(stSpat, data=findat)
writeOGR(stSpat_df, "chull", layer="chull", driver="ESRI Shapefile")

write.csv(findat, file = "hourlyComps.csv", header= TRUE, row.names = FALSE, quote = FALSE)

sp_poly <- SpatialPolygons(list(Polygons(list(Polygon(coords)), ID=1)))
# set coordinate reference system with SpatialPolygons(..., proj4string=CRS(...))
# e.g. CRS("+proj=longlat +datum=WGS84")
sp_poly_df <- SpatialPolygonsDataFrame(sp_poly, data=data.frame(ID=1))




yesterday <- read.table(paste0("http://uk-air.defra.gov.uk/data/toeea/nrt/","GB-",
                                substring(Sys.Date(),1,4),substring(Sys.Date(),6,7),
                                as.character(as.numeric(substring(Sys.Date(),9,10))-1),"24",".dat"), skip = 7, header = TRUE, sep = ";", na.strings = "-999")
yesterday[yesterday == -999] <- NA
colMeans(yesterday[,10:33], na.rm = TRUE)
# x11()
plot(yesterday[,c("Longitude","Latitude")])


yestMelt <- melt(data = yesterday, id.vars = c("code","name","Component","type","area"),
                 measure.vars =  c("X00.00.00.59","X01.00.01.59","X02.00.02.59",
                                   "X03.00.03.59","X04.00.04.59","X05.00.05.59","X06.00.06.59",
                                   "X07.00.07.59","X08.00.08.59","X09.00.09.59","X10.00.10.59",    
                                   "X11.00.11.59","X12.00.12.59","X13.00.13.59","X14.00.14.59",    
                                   "X15.00.15.59","X16.00.16.59","X17.00.17.59","X18.00.18.59",    
                                   "X19.00.19.59","X20.00.20.59","X21.00.21.59","X22.00.22.59",    
                                   "X23.00.23.59"))

yestMelt$hour <- as.numeric(substr(yestMelt$variable, 2, 3))


qplot(x = hour, y = value, pch = Component,  col = type,
      geom = "point", data = yestMelt[yestMelt$Component == "NO2",])

library(ggvis)


dat <- yestMelt[yestMelt$name == "Birmingham_Tyburn" & yestMelt$Component %in% c("NO2","PM10"),] 

dat %>%
  ggvis(~hour, ~value, col = ~Component) 



dat %>%
  ggvis(~hour, ~value, fill= ~Component) %>%
  layer_points(
    fill := input_checkboxgroup(
      choices = c("NO2" = "r", "PM10" = "g"),
      label = "Point color components",
      map = function(val) {
        rgb(0.8 * "r" %in% val, 0.8 * "g" %in% val, 0.8)
      }
    )
  )

  layer_smooths(span = input_slider(0.5, 1, value = 1)) %>%
  layer_points(size := input_slider(100, 1000, value = 100))




###### read all the hourly data available  - potentially to feed it into a shiny app


d1 <- read.table(paste0("http://uk-air.defra.gov.uk/data/toeea/nrt/",
                        grep("24.dat",anodes,value = TRUE)[1]), 
                 skip = 7, header = TRUE, sep = ";", na.strings = "-999")

for(file in grep("24.dat",anodes,value = TRUE)[-1]){
  d1 <- rbind(d1,
    read.table(paste0("http://uk-air.defra.gov.uk/data/toeea/nrt/",
                          file), 
                   skip = 7, header = TRUE, sep = ";", na.strings = "-999"))
}

allDat <- melt(d1, id.vars = c("code","name","Component","type","area","date"),
     measure.vars =  c("X00.00.00.59","X01.00.01.59","X02.00.02.59",
                       "X03.00.03.59","X04.00.04.59","X05.00.05.59","X06.00.06.59",
                       "X07.00.07.59","X08.00.08.59","X09.00.09.59","X10.00.10.59",    
                       "X11.00.11.59","X12.00.12.59","X13.00.13.59","X14.00.14.59",    
                       "X15.00.15.59","X16.00.16.59","X17.00.17.59","X18.00.18.59",    
                       "X19.00.19.59","X20.00.20.59","X21.00.21.59","X22.00.22.59",    
                       "X23.00.23.59"))
allDat$hour <- as.numeric(substr(allDat$variable, 2, 3))
allDat$DateN <- as.numeric(as.Date(allDat$date))

allDat$DateN <- as.numeric(paste0(allDat$date, " ",
                              substr(allDat$variable, 2, 3),":00:00"), "%Y-%m-%d %H:%M:S", tz = "GMT")

# write.table(allDat, file = "shiny2/allDat.txt", sep = "\t", quote = FALSE, row.names = FALSE )
# write.table(allDat[allDat$Component %in% c("PM10","NO2") & allDat$name %in% c("Aston_Hill","Aberdeen"),],
#             file = "shiny2/sub.txt", sep = "\t", quote = FALSE, row.names = FALSE )





