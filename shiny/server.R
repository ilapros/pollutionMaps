library(shiny)

# dat <- read.table("dat.txt", sep = "\t", header = TRUE)
# dat <- read.table("allDat.txt", sep = "\t", header = TRUE)


# Define server logic for random distribution application
shinyServer(function(input, output) {
  
  
  # Generate a plot of the data. Also uses the inputs to build the 
  # plot label. Note that the dependencies on both the inputs and
  # the 'data' reactive expression are both tracked, and all expressions 
  # are called in the sequence implied by the dependency graph
  output$plot <- renderPlot({
    comp <- input$comp
    plot(dat[,c("hour","value")], col = "grey70", pch =16)
    points(dat[dat$Component == comp,c("hour","value")], 
           col = ifelse(comp == "PM10",2,4), pch =16)
  })
  
  # Generate a summary of the data
  output$summary <- renderPrint({
    comp <- input$comp
    summary(dat[dat$Component == comp,c("hour","value")])
  })
  
  # Generate an HTML table view of the data
#   output$table <- renderTable({
#     data.frame(x=data())
#   })
})
