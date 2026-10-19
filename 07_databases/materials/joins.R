# ------------------------------------------------------------------
# Relational databases and SQL: joins and talking to databases from R
# Code from lecture 07 (07-databases.Rmd), collected in one script
# ------------------------------------------------------------------

library(tidyverse)
library(nycflights13)
library(DBI)
library(RSQLite)


# 1. Relational data in R ------------------------------------------

# nycflights13 bundles five related tables: flights, airlines,
# airports, planes, and weather.

# airlines: look up the full carrier name from its abbreviated code
head(airlines, 10)

# airports: information about each airport, identified by faa code
head(airports, 10)

# planes: information about each plane, identified by tailnum
head(planes, 10)

# weather: weather at each NYC airport for each hour
head(weather, 10)

# flights: one row per flight
nrow(flights)
head(flights, 10)

# How the tables connect:
#   flights -> planes   via tailnum
#   flights -> airlines via carrier
#   flights -> airports via origin and dest
#   flights -> weather  via origin, year, month, day, hour


# 2. Joins in R ----------------------------------------------------

# The join family in dplyr (consistent with SQL vocabulary):
#   inner_join(), left_join(), right_join(), full_join(),
#   semi_join(), anti_join()

# Left join without specifying keys: dplyr guesses the columns that
# share a name and reports them:
#   Joining with `by = join_by(year, tailnum)`
left_join(flights, planes) |>
  select(year, month, day, dep_time, arr_time, carrier, flight, tailnum, type, model)

# Problem: "year" means year of flight in one table and year of
# construction in the other. Be explicit about the joining column
# and rename the ambiguous one:
left_join(
  flights,
  planes |> rename(year_built = year), # not strictly necessary, but helpful
  by = "tailnum"                        # be specific about the joining column
) |>
  select(year, month, day, dep_time, arr_time, carrier, flight, tailnum, year_built, type, model) |>
  head(3)

# Same thing with the newer join_by() syntax. It also allows keys with
# different names, e.g. join_by(tailnum == tail_number).
left_join(
  flights,
  planes |> rename(year_built = year),
  by = join_by(tailnum)
) |>
  select(year, month, day, dep_time, arr_time, carrier, flight, tailnum, year_built, type, model) |>
  head(3)

# If you specify the key but don't rename, dplyr disambiguates with
# .x and .y suffixes. Make sure you know which is which.
left_join(
  flights,
  planes,
  by = "tailnum"
) |>
  select(contains("year"), month, day, dep_time, arr_time, carrier, flight, tailnum, type, model) |>
  head(3)


# 3. Duplicate keys ------------------------------------------------

# One-to-many: one table has duplicate keys, the other doesn't.
# Each flight matches exactly one plane; each plane matches many flights.
flights |>
  select(flight, tailnum) |>
  left_join(planes |> select(tailnum, model), by = "tailnum") |>
  head(5)

# Many-to-many: both tables have duplicate keys. The result is the
# Cartesian product of all matches. dplyr (>= 1.1.0) warns about this:
x <- tibble(key = c(1, 2, 2, 1), val_x = c("x1", "x2", "x3", "x4"))
y <- tibble(key = c(1, 2, 2, 3), val_y = c("y1", "y2", "y3", "y4"))
left_join(x, y, by = "key")

# If the many-to-many relationship is intended, say so to silence the
# warning:
left_join(x, y, by = "key", relationship = "many-to-many")


# 4. Connecting to a database --------------------------------------

# Set up an SQLite database that lives in memory. The first argument
# to dbConnect() is always the backend: RSQLite::SQLite(),
# RMariaDB::MariaDB(), RPostgres::Postgres(), bigrquery::bigquery(), ...
con <- dbConnect(RSQLite::SQLite(), dbname = ":memory:")
con

# In real life, the database usually lives on a server and you have
# to authenticate. This could look as follows (not run):
# con <- DBI::dbConnect(RSQLite::SQLite(),
#                       host = "mydatabase.host.com",
#                       user = "simon",
#                       password = "mypassword")


# 5. Filling the database ------------------------------------------

# Upload a local data frame into the database. Specific to our toy
# example; usually you won't build up the database yourself.
dplyr::copy_to(
  dest = con,
  df = nycflights13::flights,
  name = "flights"
)

# With indexes for fast processing by day, carrier, plane, and
# destination (not run; the table already exists):
# dplyr::copy_to(
#   dest = con,
#   df = nycflights13::flights,
#   name = "flights",
#   temporary = FALSE,
#   indexes = list(
#     c("year", "month", "day"),
#     "carrier",
#     "tailnum",
#     "dest"
#   )
# )

dbListTables(con)


# 6. Querying the database with dplyr ------------------------------

# A reference to the remote table. Nothing is pulled into R yet.
flights_db <- tbl(con, "flights")
flights_db

# dplyr syntax is translated into SQL and executed in the database
flights_db |> select(year:day, dep_delay, arr_delay) |> head(3)

# dplyr is lazy: assigning a query to an object does not run it
tailnum_delay_db <- flights_db |>
  group_by(tailnum) |>
  summarise(
    delay = mean(arr_delay),
    n = n()
  ) |>
  arrange(desc(delay)) |>
  filter(n > 100)

# Downsides of laziness: no row count without running the query,
# and no tail()
nrow(tailnum_delay_db)
try(tail(tailnum_delay_db))

# Pull the result into a local data frame with collect()
tailnum_delay <- tailnum_delay_db |> collect()
tailnum_delay


# 7. Using SQL directly in R ---------------------------------------

# Show the SQL that dbplyr generated for the query above
tailnum_delay_db |> show_query()

# Or write SQL yourself and send it to the DBMS
sql_query <- "SELECT * FROM flights WHERE dep_delay > 240.0 LIMIT 5"
dbGetQuery(con, sql_query)

# Close the connection when you're done
DBI::dbDisconnect(con)
