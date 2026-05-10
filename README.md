# Stellar Data Explorer 🌟

An interactive R Shiny application built to explore the physical relationship between a star's surface temperature, its absolute magnitude (brightness), and its spectral classification. 

This dashboard is designed as an educational tool, allowing users to dynamically filter stellar populations, visualize distributions, and run fundamental statistical tests to analyze variances across different types of stars.

## Features
* **Dynamic Data Filtering:** Subset the dataset globally by spectral class and surface temperature (Kelvin).
* **Interactive Visualizations:**
  * **Hertzsprung-Russell (H-R) Diagram (Scatter Plot):** Plots Temperature vs. Magnitude (with standard astronomical log scaling and reversed axes).
  * **Distributions:** Histograms and Boxplots to analyze variable spread.
  * **Population Counts:** Bar charts displaying dataset composition.
* **Statistical Testing:**
  * **ANOVA:** Tests for variance across all selected spectral classes.
  * **Two-Sample T-Test:** Compares means between two distinct user-selected groups.
  * **Mann-Whitney U-Test:** Non-parametric testing for robust difference analysis.
* **Raw Data View:** Transparent access to the underlying reactive dataset.

## Requirements
To run this application locally, you will need R installed along with the following packages:
* `shiny`
* `dslabs`
* `ggplot2`
* `dplyr`

You can install these dependencies by running the following command in your R console:
```R
install.packages(c("shiny", "dslabs", "ggplot2", "dplyr"))
