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

# ---- Prepare data ----
# Join the English Local Authortiy District IMD data set (exported from IMD) to 
# the corresponding boundary (shape) file (exported from geograhr)

load("boundaries_lad.rda")

imd_with_boundaries <-
  boundaries_lad |>
  right_join(imd_england_lad)

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
          label = NULL,
          choices = sort(imd_with_boundaries$lad_name),
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
        h4(textOutput("lad_name")),
        width = 6,
        align = "center",
        tableOutput("imdTable")
      )
    )
  )

# ---- Server ----
server <-
  function(input, output, session) {
    
    # - Track selections -
    # Track which map polygons the user has clicked on
    
    # initialise a reactive value which will be 
    # modified when the map is clicked or the dropdown menu is used
    reactive_input <- reactiveValues()
    
    # get id and name of LAD when map is clicked
    observeEvent(input$map_shape_click, {
      reactive_input$id <- input$map_shape_click$id
      reactive_input$name <- imd_with_boundaries$lad_name[match(input$map_shape_click$id, imd_with_boundaries$lad_code)]}
    )
    # get id and name of LAD when dropdown menu is clicked
    observeEvent(input$selectbox, {
      reactive_input$id <- imd_with_boundaries$lad_code[match(input$selectbox, imd_with_boundaries$lad_name)]
      reactive_input$name <- input$selectbox}
    )
    
    # Get text (LAD name) for table header
    output$lad_name <- renderText(paste0(reactive_input$name))
    
    # - Map -
    output$map <-
      renderLeaflet({
        leaflet() |>
          setView(lat = 52.75, lng = -2.0, zoom = 6) |>
          addProviderTiles(providers$CartoDB.Positron) |>
          addPolygons(
            data = imd_with_boundaries,
            layerId = ~lad_code,
            weight = 0.7,
            opacity = 0.5,
            # color = "#bf4aee",
            dashArray = "0.1",
            fillOpacity = 0.4,
            highlight = highlightOptions(
              weight = 5,
              color = "#666",
              dashArray = "",
              fillOpacity = 0.7,
              bringToFront = TRUE
            ),
            label = imd_with_boundaries$lad_name
          )
      })
    
    # - Table -
    output$imdTable <-
      renderTable(
        imd_england_lad |>
          filter(lad_code == reactive_input$id) |>
          pivot_longer(
            cols = !lad_code,
            names_to = "Variable",
            values_to = "Value"
          ) |>
          select(-lad_code)
      )
  }

# ---- Run App ----
shinyApp(ui = ui, server = server)