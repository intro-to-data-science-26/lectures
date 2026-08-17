#!/usr/local/bin/Rscript
library(tidyverse)
library(magrittr)
library(httr)
setwd("/Users/s.munzert/Documents/github/intro-to-data-science-25/lectures/03-iteration/examples/cronR")
url <- "http://www.spiegel.de/schlagzeilen/"
url_out <- GET(url, add_headers(from = "eddie@datacollection.com"))
datetime <- str_replace_all(Sys.time(), "[ :]", "-")
content(url_out, as = "text") %>% write(file = str_c("spiegelHeadlines/spon-", datetime, ".html"))
