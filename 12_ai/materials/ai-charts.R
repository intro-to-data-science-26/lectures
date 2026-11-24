### -----------------------------
### Charts for session 12: AI adoption and job postings
### -----------------------------

library(tidyverse)

accent <- "#cc0065"
chatgpt <- as.Date("2022-11-30")

theme_sm <- function(base_size = 13) {
  theme_minimal(base_family = "Fira Sans", base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold"),
      plot.title.position = "plot",
      plot.subtitle = element_text(colour = "#555555"),
      plot.caption = element_text(colour = "#888888", hjust = 0, size = 9),
      plot.caption.position = "plot",
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      legend.position = "none",
      plot.background = element_rect(fill = "white", colour = NA)
    )
}

# 1) AI use among developers ----------------------------------------
# Stack Overflow Developer Survey, share of respondents who currently use
# AI tools. 2026: question wording changed ("AI tools or AI agents in your
# role at work"), so the last point is not strictly comparable.
# 2023: https://survey.stackoverflow.co/2023/#ai
# 2024: https://survey.stackoverflow.co/2024/ai
# 2025: https://survey.stackoverflow.co/2025/
# 2026: https://survey.stackoverflow.co/2026/ai/data#ai-usage

adoption <- tribble(
  ~year, ~share, ~comparable,
  2023,  44,     TRUE,
  2024,  62,     TRUE,
  2025,  79,     TRUE,
  2026,  83,     FALSE
)

p1 <- ggplot(adoption, aes(year, share)) +
  geom_line(linewidth = 0.8, colour = accent) +
  geom_point(aes(shape = comparable), size = 4, colour = accent, fill = "white", stroke = 1.2) +
  geom_text(aes(label = paste0(round(share), "%")), vjust = -1.3,
            family = "Fira Sans", fontface = "bold", size = 5) +
  scale_shape_manual(values = c(`TRUE` = 19, `FALSE` = 21)) +
  scale_y_continuous(limits = c(0, 100), labels = \(x) paste0(x, "%")) +
  scale_x_continuous(limits = c(2022.7, 2026.3)) +
  labs(
    title = "Developers who currently use AI tools",
    subtitle = "Stack Overflow Developer Survey, 2023 to 2026",
    caption = "Data: Stack Overflow Developer Survey. Open circle: question wording changed in 2026.",
    x = NULL, y = NULL
  ) +
  theme_sm()

ggsave("../pics/ai-adoption-developers.png", p1, device = ragg::agg_png,
       width = 9, height = 4.6, dpi = 200, bg = "white")

# 2) Job postings on Indeed -----------------------------------------
# Indeed Hiring Lab job postings index (1 Feb 2020 = 100), US, seasonally
# adjusted, via FRED: series IHLIDXUSTPSOFTDEVE and IHLIDXUS.
# https://fred.stlouisfed.org/series/IHLIDXUSTPSOFTDEVE

postings <- bind_rows(
  read_csv("IHLIDXUSTPSOFTDEVE.csv", show_col_types = FALSE) |>
    rename(date = 1, index = 2) |> mutate(series = "Software development"),
  read_csv("IHLIDXUS.csv", show_col_types = FALSE) |>
    rename(date = 1, index = 2) |> mutate(series = "All job postings")
)

labels <- postings |> slice_max(date, by = series)

p2 <- ggplot(postings, aes(date, index, colour = series)) +
  geom_hline(yintercept = 100, colour = "grey60", linewidth = 0.3) +
  geom_vline(xintercept = chatgpt, colour = "grey40", linewidth = 0.4, linetype = "dashed") +
  geom_line(linewidth = 0.8) +
  geom_text(data = labels, aes(label = series), hjust = 1, vjust = -1,
            family = "Fira Sans", fontface = "bold", size = 4) +
  annotate("text", x = chatgpt + 30, y = 235, label = "ChatGPT released",
           hjust = 0, colour = "grey30", family = "Fira Sans", size = 3.6) +
  scale_colour_manual(values = c("Software development" = accent, "All job postings" = "grey35")) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(
    title = "Job postings on Indeed, United States",
    subtitle = "Index, 1 February 2020 = 100, seasonally adjusted",
    caption = "Data: Indeed Hiring Lab via FRED (IHLIDXUSTPSOFTDEVE, IHLIDXUS).",
    x = NULL, y = NULL
  ) +
  theme_sm()

ggsave("../pics/job-postings-indeed.png", p2, device = ragg::agg_png,
       width = 9, height = 4.6, dpi = 200, bg = "white")
