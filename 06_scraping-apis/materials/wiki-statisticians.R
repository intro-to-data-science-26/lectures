### -----------------------------
### simon munzert
### build a network of statisticians
### -----------------------------

## goals

# gather list of statisticians
# fetch Wikipedia entries
# identify links
# construct connectivity matrix
# visualize network

## load packages  -----------------------

library(tidyverse)
library(rvest)
library(igraph)
library(networkD3)

## step 1: inspect page -----------------

url <- "https://en.wikipedia.org/wiki/List_of_statisticians"

# we use a static version (with oldid URL parameter) to ensure reproducibility of the findings
url <- "https://en.wikipedia.org/w/index.php?title=List_of_statisticians&oldid=1178334039"

browseURL(url)


## step 2: retrieve links ---------------

html_parsed <- read_html(url)

# helper function that turns hrefs into decoded relative paths ("/wiki/Name")
# note: depending on how the page is served, hrefs come either relative and percent-encoded ("/wiki/%C3%89tienne_Laspeyres")
# or absolute and decoded ("https://en.wikipedia.org/wiki/Étienne_Laspeyres"); we harmonize both
normalize_links <- function(x) {
  x |>
    str_remove("^https?://en\\.wikipedia\\.org") |>
    str_remove("#.*$") |>
    map_chr(URLdecode)
}

# option 1: the step-by-step way
# we identify all links in un-ordered list elements; then get rid of the invalid matches by hard-coding the first and last valid hit

links <- html_parsed |>
  html_elements(xpath = "//ul/li/a[1]") |>
  html_attr("href") |>
  discard(is.na)
first_hit <- str_which(links, "Odd_Aalen")[1]
last_hit <- str_which(links, "George_Kingsley_Zipf")[1]
links <- links[first_hit:last_hit] |>
  keep(\(x) str_detect(x, "/wiki/"))
length(links)

# option 2: the one-XPath-expression-fits-all approach
# we write and expression that finds the intersection of both expressions. This is fairly complicated because we cannot use "and" here. The following solution uses the count function:
# note: Wikipedia used to put the heading IDs into <span> elements; now they sit in the <h2> elements, so we use the wildcard * to match either

xpath_intersection <- "//*[@id='A']/following::ul/li/a[1][count(. | //*[@id='See_also']/preceding::ul/li/a[1]) = count(//*[@id='See_also']/preceding::ul/li/a[1])]"

links <- html_parsed |>
  html_elements(xpath = xpath_intersection) |>
  html_attr("href") |>
  keep(\(x) str_detect(x, "/wiki/")) |>
  discard(\(x) str_detect(x, "redlink=1")) |> # drop links to non-existing pages
  normalize_links() |>
  unique()
length(links)


##  step 3: extract names; set up fetch vectors ---------------

clean_up_names <- function(x) {
  x |>
    basename() |>
    str_replace_all("_", " ") |>
    str_remove_all(" \\(.*\\)") |>
    str_trim()
}
stat_names <- clean_up_names(links)

# create directory to store files in
store_directory <- "wikipediaStatisticians/"

# create filenames (percent-encoded to avoid trouble with special characters in file names)
filenames <- str_c(store_directory, map_chr(basename(links), URLencode), ".html")

# create source URLs
baseurl <- "https://en.wikipedia.org"
source_urls <- str_c(baseurl, map_chr(links, URLencode))


## step 4: fetch personal wiki pages ------------

dir.create(store_directory, showWarnings = FALSE)

# download files

# helper function that only downloads files that don't exist yet
download_files <- function(source, dest) {
  if (!file.exists(dest)) {
    download.file(source, dest, quiet = TRUE)
    Sys.sleep(0.5) # be polite
  }
}

# download all files
walk2(source_urls, filenames, download_files, .progress = TRUE)

# parse all HTMLs into list
htmls_list <- map(filenames, read_html, .progress = TRUE)


## step 5: identify links between statisticians -------

# for each page, collect the links in p sections (otherwise too many links collected) and check which of them point to other statisticians
connections <- htmls_list |>
  imap(\(page, i) {
    page_links <- page |>
      html_elements(xpath = "//p//a") |>
      html_attr("href") |>
      discard(is.na) |>
      normalize_links()
    tibble(from = i, to = which(links %in% page_links))
  }) |>
  list_rbind() |>
  filter(from != to)

# results
head(connections)

# make symmetrical
connections <- connections |>
  bind_rows(select(connections, from = to, to = from)) |>
  distinct()


## step 6: visualize connections ---------

# networkD3 needs zero-indexed node IDs
links_df <- connections |>
  mutate(across(c(from, to), \(x) x - 1), value = 1)
nodes_df <- tibble(name = stat_names, group = 1) |>
  mutate(degree = tabulate(connections$to, nbins = n()))

network_out <- forceNetwork(
  Links = as.data.frame(links_df), Nodes = as.data.frame(nodes_df), # networkD3 expects plain data frames
  Source = "from", Target = "to", Value = "value",
  NodeID = "name", Group = "group", Nodesize = "degree",
  radiusCalculation = JS("Math.sqrt(d.nodesize) * 2 + 3"), # node size reflects number of connections
  charge = -60, linkDistance = 40, # spread nodes out a bit more
  zoom = TRUE, fontSize = 12, fontFamily = "sans-serif", opacity = 1, opacityNoHover = 0
)

# to reduce label overlap, only the best-connected statisticians are labelled by default
# on hover, the hovered node's label is enlarged and highlighted, its neighbours are labelled, and everything else fades out
# (we replace networkD3's default hover behaviour with our own)
label_min_degree <- 5

network_out <- htmlwidgets::onRender(
  network_out,
  "function(el, x, minDegree) {
    var svg = d3.select(el).select('svg');
    var node = svg.selectAll('.node');
    var link = svg.selectAll('.link');
    var text = node.select('text');

    // lookup table of connected node pairs
    var linked = {};
    link.each(function(l) { linked[l.source.index + ',' + l.target.index] = true; });
    function isNeighbour(a, b) { return a.index === b.index || linked[a.index + ',' + b.index]; }

    // white halo behind labels keeps them readable on top of links and nodes
    text.style('paint-order', 'stroke').style('stroke', 'white')
      .style('stroke-width', '3px').style('stroke-linejoin', 'round');

    function reset() {
      node.style('opacity', 1);
      link.style('opacity', 0.4);
      text.style('opacity', function(d) { return d.nodesize >= minDegree ? 1 : 0; })
        .style('font-size', '12px').style('font-weight', 'normal').style('fill', '#333');
    }
    reset();

    node.on('mouseover', function(d) {
      d3.select(this).raise(); // bring hovered node and its label to the front
      node.style('opacity', function(o) { return isNeighbour(d, o) ? 1 : 0.15; });
      link.style('opacity', function(l) { return l.source === d || l.target === d ? 1 : 0.05; });
      text.style('opacity', function(o) { return isNeighbour(d, o) ? 1 : 0; });
      d3.select(this).select('text')
        .style('font-size', '20px').style('font-weight', 'bold').style('fill', '#c0392b');
    })
    .on('mouseout', reset);
  }",
  data = label_min_degree
)

saveNetwork(network_out, file = "connections.html")
browseURL("connections.html")


## step 7: identify top nodes in data frame ---------

connections |>
  count(to) |>
  mutate(name = stat_names[to]) |>
  arrange(desc(n)) |>
  slice_head(n = 20)
