# ---- Load libraries ----
# geographr is in development and can be installed from GitHub:
# - https://github.com/britishredcrosssociety/geographr

# If a package to load is not installed, it will be installed automatically
# and then loaded
loadPackages = T

if(loadPackages){
  packagesToLoad =
    c(
      "shiny",
      "dplyr",
      "tidyr",
      "leaflet",
      "sf",
      "IMD",
      "geographr"
    )
  for( package in packagesToLoad ) {
    if(!require(package, character.only=TRUE)){
      install.packages(package,dependencies = TRUE)
      require(package, character.only=TRUE)
    }
  }
}



# ---- Prepare data ----
# Join the English Local Authortiy District IMD data set (exported from IMD) to
# the corresponding boundary (shape) file (exported from geograhr)

# Used 2019 data set for boundaries due to this being the corresponding and latest IMD data available
imd_with_boundaries <- right_join(boundaries_ltla19,
                                  imd_england_lad,
                                  by = c("ltla19_code" ="lad_code"))

# ---- UI ----
ui <-
  fluidPage(
    
    # - Set CSS -
    includeCSS("www/styles.css"),
    
    # - Title -
    fluidRow(
      align = "left",
      titlePanel("IMD Explorer")
    ),
    
    # - Select Box -
    fluidRow(
      column(
        width = 12,
        align = "center",
        uiOutput('selectbox')
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
        h2(textOutput("ltla19_name")),
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
    # Selecting Adur as the first LA to be shown in the table
    selected_polygon <- reactiveVal("E07000223")
    
    observeEvent(input$map_shape_click,{
      selected_polygon(input$map_shape_click$id)
    })
    
    
    observeEvent(input$selectbox,{
      var <- imd_with_boundaries %>% 
        filter(ltla19_name == input$selectbox) %>% 
        pull(ltla19_code)
      selected_polygon(var)
    },
    ignoreInit = T)
    
    
    # - Map -
    output$map <-
      renderLeaflet({
        # Selecting the colour palette for the map and reversing the colours (light = low score, dark = high score)
        pal <- colorNumeric("viridis", imd_with_boundaries$Score, reverse = T)
        leaflet() |>
          setView(lat = 52.75, lng = -2.0, zoom = 6) |>
          addProviderTiles(providers$CartoDB.Positron) |>
          addPolygons(
            data = imd_with_boundaries,
            layerId = ~ltla19_code,
            weight = 0.7,
            opacity = 0.5,
            color = ~pal(Score),
            dashArray = "0.1",
            fillOpacity = 0.4,
            highlight = highlightOptions(
              weight = 5,
              color = "#666",
              dashArray = "",
              fillOpacity = 0.7,
              bringToFront = TRUE),
            # Add a label to the map for each LA containing name and IMD score
            label = ~paste0(
              "", imd_with_boundaries$ltla19_name, ", ",
              "IMD score: ", imd_with_boundaries$Score,"")) |>
          # Add a legend to the map
          addLegend(
            position = "bottomright",
            pal = pal,
            values = imd_with_boundaries$Score,
            title = "IMD score")
      })
    
    # Select LA name to be shown above table in output
    output$ltla19_name <- renderText(
      paste0(
        imd_with_boundaries %>% 
          filter(ltla19_code == selected_polygon()) %>% 
          pull(ltla19_name)
        )
      )
    
    # - Table -
    output$imdTable <-
      renderTable({
        imd_england_lad %>%
          # renaming variables in the table to not contain an underscore
          rename_with(~ gsub("_", " ", .x, fixed=T)) %>%
          filter(`lad code` == selected_polygon()) %>%
          pivot_longer(
            cols = !`lad code`,
            names_to = "Variable",
            values_to = "Value"
          ) %>%
          select(-`lad code`)
      })
    
    
    # - Select Box -
    output$selectbox <-
      renderUI({
        selectInput(
          inputId = "selectbox",
          label = "Please select a local authority",
          choices = sort(imd_with_boundaries$ltla19_name),
          selected =  imd_with_boundaries %>% filter(ltla19_code == selected_polygon()) %>% pull(ltla19_name)
        )
      })
    
    
  }



# ---- Run App ----
shinyApp(ui = ui, server = server)

