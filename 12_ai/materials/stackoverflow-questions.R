### -----------------------------
### Stack Overflow: new questions per month
### Data: Stack Exchange API (https://api.stackexchange.com/docs)
### -----------------------------

# The API returns the number of (non-deleted) questions created in a time
# window. We ask once per month. Anonymous use is limited to 300 requests
# per day and IP, so the result is cached in a csv file.

library(tidyverse)
library(httr2)

count_questions <- function(from, to) {
  resp <- request("https://api.stackexchange.com/2.3/questions") |>
    req_url_query(
      site = "stackoverflow",
      fromdate = as.integer(as.POSIXct(from, tz = "UTC")),
      todate = as.integer(as.POSIXct(to, tz = "UTC")) - 1,
      filter = "total"
    ) |>
    req_throttle(rate = 2) |>
    req_retry(max_tries = 3) |>
    req_perform() |>
    resp_body_json()
  resp$total
}

csv_file <- "stackoverflow-questions.csv"

if (!file.exists(csv_file)) {
  months <- seq(as.Date("2008-08-01"), as.Date("2026-10-01"), by = "month")
  so <- tibble(
    month = months,
    questions = map2_int(months, months %m+% months(1), count_questions)
  )
  write_csv(so, csv_file)
}

so <- read_csv(csv_file, show_col_types = FALSE)

# plot --------------------------

accent <- "#cc0065"
chatgpt <- as.Date("2022-11-30")

p <- ggplot(so, aes(month, questions)) +
  geom_area(fill = "grey85") +
  geom_line(linewidth = 0.6, colour = "grey25") +
  geom_vline(xintercept = chatgpt, colour = accent, linewidth = 0.5) +
  annotate("text", x = chatgpt - 60, y = 205000, label = "ChatGPT released\n(30 Nov 2022)",
           hjust = 1, vjust = 1, colour = accent, family = "Fira Sans",
           size = 3.6, lineheight = 0.95) +
  scale_y_continuous(labels = scales::label_comma(), expand = expansion(c(0, 0.05))) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y", expand = expansion(0.01)) +
  labs(
    title = "New questions on Stack Overflow, per month",
    subtitle = "August 2008 to October 2026",
    caption = "Data: Stack Exchange API, non-deleted questions.",
    x = NULL, y = NULL
  ) +
  theme_minimal(base_family = "Fira Sans", base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.title.position = "plot",
    plot.subtitle = element_text(colour = "#555555"),
    plot.caption = element_text(colour = "#888888", hjust = 0, size = 9),
    plot.caption.position = "plot",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.background = element_rect(fill = "white", colour = NA)
  )

ggsave("../pics/stackoverflow-questions.png", p, device = ragg::agg_png,
       width = 9, height = 4.6, dpi = 200, bg = "white")
