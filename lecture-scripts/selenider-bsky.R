library(tidyverse)
library(rvest)
library(xml2)
library(selenider)


# 1) Launch visible Chrome via Chromote (modern API)
session <- selenider_session(
  "chromote",
  timeout = 10,
  options = chromote_options(headless = FALSE)
)

# 2) Go to Bluesky
open_url("https://bsky.app")

# 3) Try to close a modal/popup by clicking a Close button (if present)
#    - First, wait briefly for a likely "Close" control, then click if it exists.
try({
  btn <- s("button[aria-label*='Close' i]")
  if (elem_wait_until(is_present(btn), timeout = 3)) elem_click(btn)
}, silent = TRUE)

#    Fallback: hard-remove common modal containers & restore scrolling
#    (useful if the UI uses a nonstandard close button)
execute_js_expr("
  document.querySelectorAll(
    '[role=\"dialog\"], [aria-modal=\"true\"], [data-reach-dialog-content], .modal, .ReactModalPortal'
  ).forEach(el => el.remove());
  document.body.style.overflow = 'auto';
")

# 4) Scroll down to trigger dynamic loading
for (i in 1:12) {
  scroll_by(top = 2000)       # new global scroller in selenider 0.4.x
  Sys.sleep(runif(1, 0.4, 0.9))
}

# 5) Click a visible account link
#    Bluesky profile links start with /profile/ (handle or DID), so this is stable.
s("a[href^='/profile/']") |>
  elem_scroll_to() |>
  elem_click()

# Wait until we’re on a profile URL (simple polling on current_url())
for (i in 1:10) {
  if (grepl("/profile/", current_url())) break
  Sys.sleep(0.25)
}

# 6) “Download page”: save current rendered HTML and a screenshot
html <- get_page_source()
write_html(html, "bsky_profile.html")
writeLines(html_text2(html), "bsky_profile.html")
take_screenshot("bsky_profile.png")

# 7) Done (closes the active session)
close_session()
