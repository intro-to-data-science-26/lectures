### -----------------------------
### Simon Munzert
### Tapping web APIs with R
### Example: IP geolocation with ip-api.com
### -----------------------------


## Preparations -------------------

library(tidyverse)
library(httr2)
library(jsonlite)


## Ready-made R bindings to web APIs ---------

# Overviews of existing API clients
browseURL("https://ropensci.org/packages/")
browseURL("https://cran.r-project.org/web/views/WebTechnologies.html")
browseURL("https://paulcbauer.github.io/apis_for_social_scientists_a_review/")

# Example: the IP API and the ipapi package
browseURL("https://ip-api.com/docs")
browseURL("https://github.com/hrbrmstr/ipapi")

# remotes::install_github("hrbrmstr/ipapi")
# (We call the function with ipapi:: rather than library(ipapi), because the
#  package attaches data.table, which masks a few dplyr functions.)

# Function call. Empty string = your own IP; private IPs fail gracefully
ip_df <- ipapi::geolocate(c("", "10.0.1.1", "72.33.67.89", "www.spiegel.de", "hertie-school.org"), .progress = TRUE)
ip_df |> as_tibble()


## Accessing APIs from scratch ---------

# Most web APIs speak HTTP. httr2 is the R package to build and send HTTP requests.
# Most APIs return JSON (sometimes XML). httr2 parses both; jsonlite/xml2 do the heavy lifting.

# If you want to tap an API, you have to
#   1. read the documentation: endpoints, parameters, rate limits, authentication
#   2. (register and get a key)
#   3. build and send requests from R
#   4. parse and tidy the incoming data

# For ip-api.com (see docs):
# - JSON endpoint:  http://ip-api.com/json/{query}, {query} = IP or domain; empty = your own IP
# - XML endpoint:   http://ip-api.com/xml/{query}
# - Free for non-commercial use, no key needed, 45 requests per minute (HTTP 429 beyond that)
# - Batch endpoint: POST http://ip-api.com/batch, up to 100 IPs per call


## A first request ---------

endpoint <- "http://ip-api.com/json"

# httr2 is lazy: you build a request object first ...
req <- request(endpoint)
req
req |> req_dry_run()           # shows what would be sent; sends nothing

# ... and send it explicitly
resp <- req |> req_perform()
resp

# Anatomy of the response
resp |> resp_status()          # 200 = OK
resp |> resp_headers()         # meta information
resp |> resp_content_type()    # application/json
resp |> resp_body_string()     # raw body as text
resp |> resp_body_json()       # body parsed into an R list

# Low-dimensional JSON maps onto a one-row data frame
resp |> resp_body_json() |> as_tibble()

# Shortcut: jsonlite does request + parsing in one go
fromJSON(endpoint)

# Same data as XML, if you must
request("http://ip-api.com/xml") |>
  req_perform() |>
  resp_body_xml() |>
  xml2::as_list() |>
  unlist() |>
  as_tibble_row()


## Modify the request ---------

# Query a specific IP or domain by appending it to the path
request(endpoint) |>
  req_url_path_append("72.33.67.89") |>
  req_perform() |>
  resp_body_json() |>
  as_tibble()

request(endpoint) |>
  req_url_path_append("hertie-school.org") |>
  req_perform() |>
  resp_body_json() |>
  as_tibble()
# (Surprised by the location? Many sites sit behind a content delivery
#  network such as Cloudflare. You get the CDN's server, not the Hertie's.)

# Query parameters: choose the fields you want (see docs)
request(endpoint) |>
  req_url_path_append("hertie-school.org") |>
  req_url_query(fields = "query,country,city,lat,lon,isp") |>
  req_perform() |>
  resp_body_json() |>
  as_tibble()

# Be a good citizen: identify yourself
request(endpoint) |>
  req_user_agent("IDS course (munzert@hertie-school.org)") |>
  req_dry_run()


## Build a function ---------

geolocate_ip <- function(query = "", fields = "query,country,city,lat,lon,isp") {
  request("http://ip-api.com/json") |>
    req_url_path_append(query) |>
    req_url_query(fields = fields) |>
    req_user_agent("IDS course (munzert@hertie-school.org)") |>
    req_perform() |>
    resp_body_json() |>
    as_tibble()
}

geolocate_ip()
geolocate_ip("193.17.243.1")
geolocate_ip("hertie-school.org")

# Several queries: iterate, with a short pause to respect the rate limit
domains <- c("hertie-school.org", "wikipedia.org", "spiegel.de", "nytimes.com", "bundestag.de")
geo_df <- map(domains, \(d) { Sys.sleep(0.5); geolocate_ip(d) }) |> list_rbind()
geo_df


## Batch requests with POST ---------

# The batch endpoint takes a JSON array of queries in the request body.
# Adding a body switches the method to POST automatically.
# Note: Unlike the JSON endpoint, batch only accepts IP addresses, not
# domains (try it with `domains` and look at the "status" column).
ips <- geo_df$query
batch_resp <- request("http://ip-api.com/batch") |>
  req_body_json(as.list(ips)) |>
  req_perform()

batch_resp
batch_resp |> resp_body_json(simplifyVector = TRUE) |> as_tibble()


## What happens when things go wrong ---------

# ip-api returns 200 with "status": "fail" for bad queries. Always check the body!
request("http://ip-api.com/json/not-an-ip") |> req_perform() |> resp_body_json()

# A proper HTTP error: calling a restricted API without a key. httr2 throws by default.
try(request("https://api.nytimes.com/svc/mostpopular/v2/viewed/1.json") |> req_perform())

# If you'd rather inspect the failed response than throw
resp_err <- request("https://api.nytimes.com/svc/mostpopular/v2/viewed/1.json") |>
  req_error(is_error = \(resp) FALSE) |>
  req_perform()
resp_err |> resp_status()
resp_err |> resp_body_json()

# Retry on transient errors (e.g., 429 rate limit), with exponential backoff
request(endpoint) |>
  req_retry(max_tries = 3) |>
  req_perform() |>
  resp_status()


## Map it ---------

world <- map_data("world")

ggplot() +
  geom_polygon(data = world, aes(long, lat, group = group),
               fill = "grey90", color = "white", linewidth = 0.2) +
  geom_point(data = geo_df, aes(lon, lat), color = "red", size = 3) +
  geom_text(data = geo_df, aes(lon, lat, label = query), vjust = -1, size = 3) +
  coord_quickmap() +
  theme_void()
