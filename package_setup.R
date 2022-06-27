## ## install once only
## devtools::install_github("rstudio/renv")

## ## need renv installed, but not explicitly loaded
## library(renv)

## ## do this once only
## renv::init()

## devtools::install_github("rstudio/fontawesome")

#### misc
library(fontawesome)
library(knitr)
library(rmarkdown)
library(JWileymisc)

#### Stuff to make word cloud summaries ####
library(XML)
library(tm)
library(wordcloud)
library(RColorBrewer)
library(SnowballC)
library(pdftools)

#### data
library(readxl)
library(data.table)

#### graphs
library(ggplot2)
library(plotly)

#### benchmarking data
library(scholar)
library(packageRank)

basedir <- Sys.getenv("OneDrive")
