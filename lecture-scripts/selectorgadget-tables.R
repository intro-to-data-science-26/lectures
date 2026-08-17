library(rvest)

url <- "https://en.wikipedia.org/wiki/List_of_philosophers_of_science"
xpath <- '//*[(@id = "mw-content-text")]//li//a'
css <- '#mw-content-text a'

html <- read_html(url)
philosophers <- html_elements(html, xpath = xpath)
philosophers <- html_elements(html, css = css)

html_text(philosophers)



url <- "https://en.wikipedia.org/wiki/List_of_human_spaceflights"
browseURL(url)
spaceflights <- read_html(url)
tables <- html_table(spaceflights)

tab3 <- tables[[3]]
