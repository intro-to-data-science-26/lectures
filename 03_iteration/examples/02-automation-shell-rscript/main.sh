#!/bin/sh
cd "/Users/s.munzert/Documents/github/intro-to-data-science-25/lectures/03-iteration/examples/02-automation-shell-rscript"
set -eux
Rscript -e 'outputs <- c("lotr_raw.tsv", "lotr_clean.tsv", list.files(pattern = "*.png$")); file.remove(outputs)'
curl -L http://bit.ly/lotr_raw-tsv > lotr_raw.tsv
Rscript 02-process-data.R
Rscript 03-plot.R