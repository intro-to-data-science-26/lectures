# ------------------------------------------------------------------
# Model building with a running example: flight delays
# Introduction to Data Science, session 08 (Modeling)
#
# Illustrates: systematic vs. stochastic model components,
#              formula syntax, interactions, variable transformations
# Data: nycflights13::flights
# ------------------------------------------------------------------

library(tidyverse)
library(nycflights13)

# ---- 1. The data ------------------------------------------------

# We work with a random sample of 5,000 flights with complete delay data
# to keep plots readable and models fast.
set.seed(42)
fl <- flights |>
  drop_na(arr_delay, dep_delay) |>
  slice_sample(n = 5000)

glimpse(fl)

# Our outcome: arrival delay (in minutes).
ggplot(fl, aes(arr_delay)) +
  geom_histogram(binwidth = 10) +
  coord_cartesian(xlim = c(-60, 300)) +
  labs(x = "Arrival delay (mins)", y = "Flights") +
  theme_minimal()

# ---- 2. Systematic + stochastic components ----------------------

# Y = f(x) + e. The line is f(x), the vertical scatter around it is e.
ggplot(fl, aes(dep_delay, arr_delay)) +
  geom_point(alpha = .15) +
  geom_smooth(method = "lm", se = FALSE, color = "#cc0065") +
  labs(x = "Departure delay (mins)", y = "Arrival delay (mins)") +
  theme_minimal()

m1 <- lm(arr_delay ~ dep_delay, data = fl)
coef(m1)       # the estimated systematic part: b0 + b1 * dep_delay
sd(resid(m1))  # the size of the stochastic part

# The residuals ARE the stochastic component. Are they well behaved?
fl |>
  mutate(.fitted = fitted(m1), .resid = resid(m1)) |>
  ggplot(aes(.fitted, .resid)) +
  geom_point(alpha = .15) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(x = "Fitted values", y = "Residuals") +
  theme_minimal()

# ---- 3. Formula syntax ------------------------------------------

# Formulas are objects of class "formula"; they can be stored and reused.
fmla <- arr_delay ~ dep_delay + distance
class(fmla)
lm(fmla, data = fl)

# Building a formula from strings is handy when generating many models.
fmla2 <- as.formula(paste("arr_delay ~", paste(c("dep_delay", "distance", "origin"), collapse = " + ")))
fmla2

# Operators:
lm(arr_delay ~ dep_delay + distance, data = fl)        # several predictors
lm(arr_delay ~ dep_delay - 1, data = fl)               # drop the intercept
lm(arr_delay ~ ., data = select(fl, arr_delay, dep_delay, distance, air_time))  # all other columns

# ---- 4. Interactions --------------------------------------------

# Does the effect of departure delay differ by origin airport?
m_add <- lm(arr_delay ~ dep_delay + origin, data = fl)  # same slope, different intercepts
m_int <- lm(arr_delay ~ dep_delay * origin, data = fl)  # slope may differ by origin
# `a * b` expands to `a + b + a:b`; `a:b` alone gives only the product term.

broom::tidy(m_int)

ggplot(fl, aes(dep_delay, arr_delay, color = origin)) +
  geom_point(alpha = .1) +
  geom_smooth(method = "lm", se = FALSE) +
  coord_cartesian(xlim = c(-20, 200), ylim = c(-60, 250)) +
  labs(x = "Departure delay (mins)", y = "Arrival delay (mins)") +
  theme_minimal()

# Compare the fit of the two models
anova(m_add, m_int)

# ---- 5. Variable transformations --------------------------------

# Formulas do not evaluate arithmetic: `distance^2` is NOT the square.
# Wrap arithmetic in I() ("as is"), or use functions like log().
m_lin  <- lm(arr_delay ~ dep_delay + distance, data = fl)
m_quad <- lm(arr_delay ~ dep_delay + distance + I(distance^2), data = fl)
m_log  <- lm(arr_delay ~ dep_delay + log(distance), data = fl)

# Alternative: compute the variable beforehand
fl <- fl |> mutate(distance2 = distance^2)
lm(arr_delay ~ dep_delay + distance + distance2, data = fl)

# Visualize what the three specifications imply for a flight that left on time
newdat <- expand_grid(dep_delay = 0, distance = seq(100, 2600, by = 50))
preds <- bind_rows(
  linear    = mutate(newdat, pred = predict(m_lin,  newdat)),
  quadratic = mutate(newdat, pred = predict(m_quad, newdat)),
  log       = mutate(newdat, pred = predict(m_log,  newdat)),
  .id = "specification"
)

ggplot(preds, aes(distance, pred, color = specification)) +
  geom_line(linewidth = 1) +
  labs(x = "Distance (miles)", y = "Predicted arrival delay (mins)\nfor an on-time departure") +
  theme_minimal()

# Which one fits best? (More on evaluating models in the tidymodels part.)
sapply(list(linear = m_lin, quadratic = m_quad, log = m_log), AIC)
