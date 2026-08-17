
library(tidyverse)
library(rvest)


# Step 1: Parse the page

url_p <- read_html("https://en.wikipedia.org/wiki/List_of_women_philosophers")
# url <- "https://en.wikipedia.org/w/index.php?title=List_of_women_philosophers&oldid=1041210397"
# url_p <- read_html(url)


# Step 2: Develop an XPath expression (or multiple) that select the information of interest and apply it

elements_set <- html_elements(url_p, xpath = "//li/a[1]")


elements_set <- html_elements(url_p, xpath = "//ul/li/a[1]")
elements_set <- html_elements(url_p, xpath = "//h2[text()='Alphabetically']//following::li/a[1]")

  
# Step 3: Extract information and clean it up

phil_names <- elements_set %>% html_text2()
phil_names[c(1:2, 101:102)]


# Step 4: Clean up (here: select the subset of links we care about)

names_iffer <-
  seq_along(phil_names) >=  seq_along(phil_names)[str_detect(phil_names, "Felicia Nimue Ackerman")] &
  seq_along(phil_names) <=   seq_along(phil_names)[str_detect(phil_names, "Alenka Zupančič")]
philosopher_names_clean <- phil_names[names_iffer]
length(philosopher_names_clean)
philosopher_names_clean[1:5]


# extract links
phil_links <- elements_set %>% html_attr("href")
phil_links_clean <- phil_links[names_iffer]
phil_links_full <- paste0("https://en.wikipedia.org", phil_links_clean)
download.file(phil_links_full[1:2], destfile = basename(phil_links_full[1:2]))



# NYT SelectorGadget example

url_p <- read_html("https://www.nytimes.com")
# xpath: paste the expression from Selectorgadget!
# note: we use single quotation marks here (' instead of ") to wrap around the expression!
xpath <- '//*[contains(concat( " ", @class, " " ), concat( " ", "indicate-hover", " " ))]'
headlines <- html_elements(url_p, xpath = xpath) 
headlines <- html_elements(url_p, css = '.indicate-hover') 

headlines_raw <- html_text(headlines)
length(headlines_raw)
head(headlines_raw)


url_p <- read_html("materials/nytimes-com-2021-09-29.html")
xpath <- '//*[contains(concat( " ", @class, " " ), concat( " ", "erslblw0", " " ))]//*[contains(concat( " ", @class, " " ), concat( " ", "e1lsht870", " " ))]'
headlines <- html_elements(url_p, xpath = xpath) # we use single quotation marks here to wrap around the expression!
headlines_raw <- html_text(headlines)
length(headlines_raw)
head(headlines_raw)


# biermap24.de

url_p <- read_html("https://www.biermap24.de/brauereiliste.php")
tables_list <- html_table(url_p)
breweries_df <- bind_rows(tables_list)




## biermap24.de

url_p <- read_html("https://www.biermap24.de/brauereiliste.php")
tables_parsed <- html_table(url_p)
breweries_df <- bind_rows(tables_parsed)

# Spaceflights example

url <- "https://en.wikipedia.org/wiki/List_of_human_spaceflights"
url_p <- read_html(url)
tables <- html_table(url_p, header = TRUE)
spaceflights <- tables[[1]]
spaceflights



url <- "https://en.wikipedia.org/w/index.php?title=List_of_human_spaceflights&oldid=778165808"
url_p <- read_html(url)
tables <- html_table(url_p, header = TRUE)
spaceflights <- tables[[1]]
spaceflights

