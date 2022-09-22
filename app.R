# ---- Load libraries ----
# geographr is in development and can be installed from GitHub: 
# - https://github.com/britishredcrosssociety/geographr
library(shiny)
library(dplyr)
library(tidyr)
library(leaflet)
library(sf)
library(IMD)
library(geographr)
library(httr)
library(readxl)
library(tidyverse)

# changed table to boundaries_ltla19
# ---- Prepare data ----
# Join the English Local Authortiy District IMD data set (exported from IMD) to 
# the corresponding boundary (shape) file (exported from geographr)


df <-data.frame(imd_with_boundaries <- imd_england_lad %>% right_join( boundaries_ltla19, 
                                                                       by=c('lad_code'='ltla19_code') ) ) 

colnames(df) <- c("lad_code","Score","Proportion","Extent","Income_Score","Income_Proportion","Employment_Score","Employment_Proportion","Education_Score","Education_Proportion","Health_Score","Health_Proportion","Crime_Score","Crime_Proportion","Housing_and_Access_Score","Housing_and_Access_Proportion","Environment_Score","Environment_Proportion","co19","co20")
todrop <- df$lad_code
names(todrop) <- df$co19
lad_name <- imd_with_boundaries$ltla19_name
lad_code <- imd_with_boundaries$ltla19_code

# ---- UI ----
ui <-
  fluidPage(
    
    # - Set CSS -
    includeCSS("www/styles.css"),
    
    # - Title -
    fluidRow(
      align = "center",
      titlePanel("IMD Explorer")
    ),
    
    # - Select Box -
    fluidRow(
      column(
        width = 12,
        align = "center",
        selectizeInput(
          "selectbox",
          todrop,
          multiple=FALSE,
          label = NULL,
          choices = todrop,
          options = list(
            placeholder = "Select a Local Authority",
            onInitialize = I('function() { this.setValue(""); }')
          )
        )
      )
    ),
    
    # - Map & Plot -
    fluidRow(
      
      # - Map -
      column(
        width = 6,
        align = "center",
        leafletOutput("map", height = 600)
      ),
      
      # - Table -
      column(
        width = 6,
        align = "center",
        tableOutput("Table")
      )
    )
  )

# ----Server----
server <-
  function(input, output, session) 
  {
    
    # - Track selections -
    # Track which map polygons the user has clicked on
    selected_polygon <- reactiveVal("E06000001")
    # Track which select id the user has clicked on
    selected_id <- reactiveVal("E06000001")
    
    # function to call in observe
    
    input_some_selection <- reactive({
      input$selectbox
    })
    
    # Reactive function "input_some_selection" is called in observe event of select
    
    observeEvent(input_some_selection(),{
      input$selectbox |>
        selected_id()
    })
    
    # Observe event of Map click
    
    observeEvent(input$map_shape_click,{
      input$map_shape_click$id |>
        selected_polygon() 
    })
    
    
    # - Map -
    output$map <-
      renderLeaflet({
        leaflet()  %>% 
          setView(lat = 52.75, lng = -2.0, zoom = 6) |>
          addProviderTiles(providers$CartoDB.Positron) |>
          addPolygons(data = boundaries_ltla19,
                      layerId = ~ltla19_code,
                      weight = 0.7,
                      opacity = 0.5,
                      dashArray = "0.1",
                      fillOpacity = 0.4,
                      highlight = highlightOptions(
                        weight = 5,
                        color = "#666",
                        dashArray = "",
                        fillOpacity = 0.7,
                        bringToFront = TRUE
                      ) ,
                      label = imd_with_boundaries$ltla19_name
          )
      })
    
    #- Table -
    output$Table <-
      renderTable({
        imd_england_lad |>
          filter((lad_code == selected_id()) | (lad_code==selected_polygon())) |>
          pivot_longer(
            cols = !lad_code,
            names_to = "Variable",
            values_to = "Value"
          ) |>
          select(-lad_code) 
        
      })
    
    
    
  }

# ---- Run App ----
shinyApp(ui = ui,  server = server )

