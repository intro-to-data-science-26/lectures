#!/bin/sh
cd /Users/s.munzert/Documents/github/intro-to-data-science-25/lectures/02-functions/examples/02-automation-shell-rscript
set -eux
Rscript 00-packages.R
Rscript 01-download-data.R
Rscript 02-process.data.R
Rscript 03-plot.R