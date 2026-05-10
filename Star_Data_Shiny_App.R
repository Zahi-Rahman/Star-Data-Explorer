# Names: Zahi Rahman, Rishab Peddi, Arnav Kanchi
#
# APPLICATION PURPOSE:
# This app explores the dslabs stars dataset. It provides basic visual 
# summaries (scatter, histogram, boxplot, bar chart) and fundamental 
# hypothesis testing (ANOVA, T-Tests, U-Tests) to analyze the differences 
# in temperature and magnitude across stellar classifications.
#
# DATA SOURCE: dslabs package
install.packages('dslabs')
library(shiny)
library(dslabs)
library(ggplot2)
library(dplyr)

data("stars")

# User Interface Definition
ui <- fluidPage(

  titlePanel("Introductory Star Data Explorer"),

  sidebarLayout(
    sidebarPanel(
      h3("Global Data Filters"),
      # Checkbox input for filtering by spectral class
      checkboxGroupInput("spectral_class",
                         "Select Spectral Classes:",
                         choices = unique(stars$type),
                         selected = unique(stars$type)),

      # Temperature range slider for filtering dataset
      sliderInput("temp_range",
                  "Select Temperature Range (K):",
                  min = min(stars$temp),
                  max = max(stars$temp),
                  value = c(min(stars$temp), max(stars$temp)),
                  step = 500),

      hr(),

      h3("2-Group Test Settings"),
      helpText("Select two specific classes to run the T-Test and U-Test."),
      # Group selection dropdowns for pairwise comparisons
      selectInput("group1", "Compare Group 1:", choices = unique(stars$type), selected = "O"),
      selectInput("group2", "Compare Group 2:", choices = unique(stars$type), selected = "M"),

      radioButtons("test_var", "Variable to Test (Applies to all stats):",
                   choices = c("Temperature (K)" = "temp", "Absolute Magnitude" = "magnitude"))
    ),
    
    mainPanel(
      tabsetPanel(
        # About/documentation landing page
        tabPanel("README / About", 
                 br(),
                 h3("Welcome to the Stellar Data Explorer"),
                 p(strong("Created by:"), " Zahi Rahman, Rishab Peddi, Arnav Kanchi"),
                 hr(),
                 h4("Application Purpose"),
                 p("This application is designed to explore the physical relationship between a star's surface temperature, its absolute magnitude (brightness), and its spectral classification. It allows users to visualize stellar populations and run statistical tests to prove variances with different stars."),
                 h4("How to Use This Dashboard"),
                 tags$ul(
                   tags$li(strong("Global Filters:"), " Use the sidebar checkboxes and temperature slider to analyze different data. This will instantly update all visualizations, the raw data table, and the ANOVA test."),
                   tags$li(strong("Visualizations:"), " Navigate the tabs to view an H-R Diagram (special scatter plot for stars), distributions (Histogram & Boxplot), and dataset distributions (Bar Chart)."),
                   tags$li(strong("Statistical Testing:"), " Select two specific spectral classes from the '2-Group Test Settings' in the sidebar to run a Two-Sample T-Test and a Mann-Whitney U-Test.")
                 ),
                 h4("Data Source"),
                 p("All data is loaded locally from the", code("dslabs"), "R package, explicitly utilizing the", code("stars"), "dataset.")
        ),

        # Visualization tabs
        tabPanel("Scatter Plot", plotOutput("scatter_plot")),
        tabPanel("Histogram", plotOutput("hist_plot")),
        tabPanel("Boxplot", plotOutput("box_plot")),
        tabPanel("Bar Chart", plotOutput("bar_plot")),

        # Statistical testing tab with ANOVA, T-test, and U-test outputs
        tabPanel("Statistical Tests", 
                 br(),
                 h4("1. ANOVA (Analysis of Variance)"),
                 helpText("Tests for differences in means across ALL selected spectral classes from the checkboxes."),
                 verbatimTextOutput("anova_stats"),
                 
                 h4("2. Two-Sample T-Test"),
                 helpText("Tests for difference in means between Group 1 and Group 2."),
                 verbatimTextOutput("ttest_stats"),
                 
                 h4("3. Mann-Whitney U-Test (Wilcoxon)"),
                 helpText("Non-parametric test for difference between Group 1 and Group 2."),
                 verbatimTextOutput("utest_stats")),


        # Raw data table display
        tabPanel("Raw Data View", dataTableOutput("data_table"))
      )
    )
  )
)

# --- Server Logic ---
server <- function(input, output) {

  # Reactive expression for filtering data based on spectral class and temperature range
  filtered_data <- reactive({
    stars %>%
      filter(type %in% input$spectral_class,
             temp >= input$temp_range[1] & temp <= input$temp_range[2])
  })

  # Generate scatter plot (H-R diagram style) with log temp and reversed magnitude
  output$scatter_plot <- renderPlot({
    req(nrow(filtered_data()) > 0)
    ggplot(filtered_data(), aes(x = temp, y = magnitude, color = type)) +
      geom_point(size = 3) +
      scale_x_log10() +
      scale_y_reverse() +
      labs(title = "Temperature vs Magnitude", x = "Temperature (Log Scale)", y = "Magnitude") +
      theme_minimal()
  })

  # Histogram of selected variable (temp or magnitude)
  output$hist_plot <- renderPlot({
    req(nrow(filtered_data()) > 0)
    ggplot(filtered_data(), aes_string(x = input$test_var)) +
      geom_histogram(fill = "steelblue", color = "white", bins = 15) +
      labs(title = paste("Histogram of", input$test_var)) +
      theme_minimal()
  })

  # Boxplot comparing selected variable across spectral types
  output$box_plot <- renderPlot({
    req(nrow(filtered_data()) > 0)
    p <- ggplot(filtered_data(), aes_string(x = "type", y = input$test_var, fill = "type")) +
      geom_boxplot() +
      labs(title = paste("Boxplot of", input$test_var, "by Spectral Class")) +
      theme_minimal()
    if(input$test_var == "magnitude") { p <- p + scale_y_reverse() }
    return(p)
  })

  # Bar chart showing count of stars in each spectral class
  output$bar_plot <- renderPlot({
    req(nrow(filtered_data()) > 0)
    ggplot(filtered_data(), aes(x = type, fill = type)) +
      geom_bar() +
      labs(title = "Count of Stars by Spectral Class", x = "Spectral Class", y = "Count") +
      theme_minimal()
  })

  # ANOVA test to compare means across all selected spectral classes
  output$anova_stats <- renderPrint({
    df <- filtered_data()
    if(length(unique(df$type)) < 2) {
      cat("Error: Please select at least two different Spectral Classes from the checkboxes to run an ANOVA.")
      return()
    }

    formula <- as.formula(paste(input$test_var, "~ type"))
    aov_model <- aov(formula, data = df)

    # Extract F-statistic and p-value from ANOVA summary
    f_val <- summary(aov_model)[[1]][["F value"]][1]
    p_val <- summary(aov_model)[[1]][["Pr(>F)"]][1]

    # Format output (round at the final step to preserve precision)
    cat("--- ANOVA Results ---\n\n")
    cat("F-Statistic: ", round(f_val, 2), "\n")
    cat("P-Value:     ", format.pval(p_val, digits = 4, eps = 0.001), "\n\n")

    cat("Interpretation:\n")
    if(p_val < 0.05) {
      cat("There is a statistically significant difference across the selected spectral classes.\n")
    } else {
      cat("There is no significant difference across the selected spectral classes.\n")
    }
  })

  # Helper function to extract the two selected groups for pairwise testing
  get_two_groups <- reactive({
    df <- filtered_data()
    g1 <- df[[input$test_var]][df$type == input$group1]
    g2 <- df[[input$test_var]][df$type == input$group2]
    list(g1 = g1, g2 = g2)
  })

  # Two-sample t-test comparing means between the two selected groups
  output$ttest_stats <- renderPrint({
    groups <- get_two_groups()
    if(length(groups$g1) < 2 | length(groups$g2) < 2) {
      cat("Error: Not enough stars in one of the selected groups within the current temperature range.")
      return()
    }

    test_result <- t.test(groups$g1, groups$g2)

    # Format and display results (keeping precision until final display)
    cat("--- Two-Sample T-Test Results ---\n\n")
    cat("Group 1 Mean: ", round(test_result$estimate[1], 2), "\n")
    cat("Group 2 Mean: ", round(test_result$estimate[2], 2), "\n")
    cat("T-Statistic:  ", round(test_result$statistic, 2), "\n")
    cat("P-Value:      ", format.pval(test_result$p.value, digits = 4, eps = 0.001), "\n\n")

    cat("Interpretation:\n")
    if(test_result$p.value < 0.05) {
      cat("We reject the null hypothesis; the means are significantly different.\n")
    } else {
      cat("We fail to reject the null hypothesis; the means are not significantly different.\n")
    }
  })

  # Mann-Whitney U-test (non-parametric alternative to t-test)
  output$utest_stats <- renderPrint({
    groups <- get_two_groups()
    if(length(groups$g1) < 1 | length(groups$g2) < 1) {
      cat("Error: Group must have at least 1 observation within the current temperature range.")
      return()
    }

    test_result <- wilcox.test(groups$g1, groups$g2)

    # Format and display results (keeping precision until final display)
    cat("--- Mann-Whitney U-Test Results ---\n\n")
    cat("W-Statistic (U): ", round(test_result$statistic, 2), "\n")
    cat("P-Value:         ", format.pval(test_result$p.value, digits = 4, eps = 0.001), "\n\n")

    cat("Interpretation:\n")
    if(test_result$p.value < 0.05) {
      cat("The distributions of the two groups differ significantly.\n")
    } else {
      cat("There is no significant difference between the distributions of the two groups.\n")
    }
  })

  # Render the filtered data as an interactive table
  output$data_table <- renderDataTable({
    filtered_data()
  })
}

# Launch the Shiny application
shinyApp(ui = ui, server = server)