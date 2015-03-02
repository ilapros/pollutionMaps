library(shiny)

# Define UI for random distribution application 
shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel("Air quality data"),
  
  # Sidebar with controls to select the random distribution type
  # and number of observations to generate. Note the use of the br()
  # element to introduce extra vertical spacing
  sidebarPanel(
    selectInput("selStat", "Select a Station:", 
                choices=sort(unique(dat$name))),
    checkboxGroupInput("comp", "Component:",
                       sort(unique(finDat$Component)))
    ),
  mainPanel(
    tabsetPanel(
      tabPanel("Plot", plotOutput("plot")), 
      tabPanel("Summary", verbatimTextOutput("summary")))
    )
  )
)
