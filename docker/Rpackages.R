options(repos = c("CRAN" = "https://cloud.r-project.org/"))
install.packages("parallel")
options(Ncpus = parallel::detectCores()-1)
install.packages(c("ggplot2","patchwork","viridis","data.table","lubridate","stringr", "jsonlite", "zoo", "knitr"))
