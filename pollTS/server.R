library(shiny)
library(ggplot2)
library(rvest)

# dat <- read.table("dat.txt", sep = "\t", header = TRUE)
# dat <- read.table("allDat.txt", sep = "\t", header = TRUE)
# dat <- dat[dat$Component %in% c("PM10","NO2") & dat$name == "Aston_Hill",]
# dat <- read.table("sub.txt", sep = "\t", header = TRUE)

ffA <- html("http://uk-air.defra.gov.uk/data/toeea/nrt/")
anodes<-ffA %>% html_nodes("a") %>% html_text() 

file <- anodes[length(anodes)]
thelastHour <- read.table(paste0("http://uk-air.defra.gov.uk/data/toeea/nrt/",file), skip = 7, header = TRUE, sep = ";", na.strings = "-999")

whenlastHour <- names(thelastHour)[9+which(colMeans(thelastHour[,10:33], na.rm = TRUE) == -111)]
whenlastHour <- whenlastHour[-1]


yesterday <- 
  read.table(paste0("http://uk-air.defra.gov.uk/data/toeea/nrt/","GB-",
                               substring(Sys.Date()-1,1,4),substring(Sys.Date()-1,6,7),
                               substring(Sys.Date()-1,9,10),"24",".dat"), skip = 7, header = TRUE, sep = ";", na.strings = "-999")

yesterday <- yesterday[,c(c("code","name","type","area","Latitude","Longitude","Altitude","Component","date"),
                      names(yesterday)[10:33][names(yesterday)[10:33] %in% whenlastHour],c("quality_assurance","quality_control"))] 


lastMelt <- melt(data = thelastHour, id.vars = c("code","name","Component","type","area"),
                 measure.vars =  grep("59" ,names(thelastHour), value = TRUE))
lastMelt$hour <- as.numeric(substr(lastMelt$variable, 2, 3))


yestMelt <- melt(data = yesterday, id.vars = c("code","name","Component","type","area"),
                 measure.vars =  grep("59" ,names(yesterday), value = TRUE))
yestMelt$hour <- 24 - as.numeric(substr(yestMelt$variable, 2, 3))
yestMelt <- yestMelt[order(yestMelt$hour),]

finDat <- rbind(yestMelt, lastMelt)

colComp <- data.frame(Component = c( "O3","NO2","NOx","SO2","CO","PM10,PM2.5"),
                    coll = c(2,1,4,3,6,7))
  
# Define server logic for random distribution application
shinyServer(function(input, output) {
   
  # Generate a plot of the data. Also uses the inputs to build the 
  # plot label. Note that the dependencies on both the inputs and
  # the 'data' reactive expression are both tracked, and all expressions 
  # are called in the sequence implied by the dependency graph
  output$plot <- renderPlot({
    dat <- finDat[finDat$name == input$selStat,]
    comp <- input$comp
#    plot(dat[,c("hour","value")], col = "white", pch = 16, ylim = c(0,max(dat$value, na.rm = TRUE)))
    qplot(hour,value,data = dat[dat$Component %in% comp,], col = Component)
    
    #     lines(dat[dat$Component %in% comp,c("hour","value")], 
    #          col = colComp$coll[colComp$Component %in% comp], pch =16)
  })
  
  # Generate a summary of the data
  output$summary <- renderPrint({
    comp <- input$comp
    summary(dat[dat$Component %in% comp,c("hour","value")])
  })
  
  # Generate an HTML table view of the data
#   output$table <- renderTable({
#     data.frame(x=data())
#   })
})
