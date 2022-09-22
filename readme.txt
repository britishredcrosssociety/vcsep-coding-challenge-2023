Bug one: The app fails to run. shiny::runApp("app.R") returns an error to the R console.-- FIXED
Bug two: Once the app is running, the IMD table on the right (see screenshot above) does not display. -- FIXED
Feature: Connect the select box at the top of the page to the IMD table. The expected behaviour is that the user can select a Local Authority District from the map or the select box, and the IMD table should update. The user should be able to flick between the map and the select box without having to restart the app. Note: you will need to use Shiny's reactive programming model to implement this feature. -- CONNECTED

The IMD table connected from the select box loads without a page refresh.
