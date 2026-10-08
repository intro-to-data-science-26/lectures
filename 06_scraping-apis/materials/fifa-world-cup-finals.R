# ------------------------------------------------------------------
# Live coding: scraping an HTML table from Wikipedia
# Example: List of FIFA World Cup finals
# https://en.wikipedia.org/wiki/List_of_FIFA_World_Cup_finals
# ------------------------------------------------------------------

library(tidyverse)
library(rvest)

# 1. Parse the page ------------------------------------------------

# Live version of the page:
url <- "https://en.wikipedia.org/wiki/List_of_FIFA_World_Cup_finals"

# Pinned revision (October 2026). Wikipedia pages change, this link won't.
# Use it if the live page looks different from the slides.
# url <- "https://en.wikipedia.org/w/index.php?title=List_of_FIFA_World_Cup_finals&oldid=1378907506"

url_p <- read_html(url)


# 2. Find the right table ------------------------------------------

# How many tables are there on the page?
url_p |> html_elements("table") |> length()

# The data tables on Wikipedia carry the class "wikitable". Still more than one:
url_p |> html_elements("table.wikitable") |> length()

# Quick overview: dimensions of each wikitable
url_p |>
  html_elements("table.wikitable") |>
  html_table() |>
  map(dim)

# Option A: just pick by position (the first wikitable is a one-row legend)
tables <- url_p |> html_elements("table.wikitable") |> html_table()
finals_raw <- tables[[2]]

# Option B (more robust): select the table by its caption via XPath
finals_raw <- url_p |>
  html_element(xpath = "//table[caption[contains(., 'List of FIFA World Cup finals')]]") |>
  html_table()

finals_raw


# 3. Clean up ------------------------------------------------------

# What's messy?
# - "Score" contains an en dash, a dagger (extra time), an asterisk
#   (penalty shoot-out) and footnote markers such as [c]
#   (We write the dagger as "\u2020" so that the script also works on
#   systems whose locale is not UTF-8.)
# - "Attendance" has thousands separators
# - "Ref." is useless
# - column names with punctuation

finals <- finals_raw |>
  select(-Ref.) |>
  rename_with(tolower) |>
  rename(runners_up = `runners-up`) |>
  mutate(
    extra_time  = str_detect(score, "\u2020"),
    penalties   = str_detect(score, "\\*"),
    score_clean = score |> str_remove_all("\\[.*?\\]|\u2020|\\*"),
    goals_winner    = score_clean |> str_extract("^\\d+") |> parse_number(),
    goals_runner_up = score_clean |> str_extract("\\d+$") |> parse_number(),
    attendance  = parse_number(attendance)
  )

finals
glimpse(finals)


# 4. Use the data --------------------------------------------------

# Who won most often?
finals |> count(winners, sort = TRUE)

# Titles won and finals lost per team
finals |>
  pivot_longer(c(winners, runners_up), names_to = "result", values_to = "team") |>
  count(team, result) |>
  pivot_wider(names_from = result, values_from = n, values_fill = 0) |>
  arrange(desc(winners))

# Average attendance per decade
finals |>
  mutate(decade = year %/% 10 * 10) |>
  group_by(decade) |>
  summarize(mean_attendance = mean(attendance), n = n())

# Finals decided in extra time or on penalties
finals |> filter(extra_time | penalties) |> select(year, winners, score, runners_up)


# 5. What html_table() throws away ---------------------------------

# html_table() only keeps the text. Links (and images) are lost.
# If we want the links to the team pages, we go back to the HTML.
finals_table <- url_p |>
  html_element(xpath = "//table[caption[contains(., 'List of FIFA World Cup finals')]]")

finals_table |>
  html_elements("tbody tr td:nth-child(2) a") |>   # winners column
  html_attr("href") |>
  head()
