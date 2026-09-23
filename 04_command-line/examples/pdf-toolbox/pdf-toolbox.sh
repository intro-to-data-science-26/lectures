#!/bin/sh
# Combine and manipulate PDFs from the command line.
# Uses the poppler utilities (macOS: brew install poppler; Ubuntu: apt install poppler-utils).
# Usage: ./pdf-toolbox.sh

# 1. Combine: merge all parts (in filename order) into one document
pdfunite parts/*.pdf combined-report.pdf
echo "combined $(ls parts/*.pdf | wc -l | tr -d ' ') files into combined-report.pdf"

# 2. Inspect: how many pages does the result have?
pdfinfo combined-report.pdf | grep Pages

# 3. Split: extract each page as its own PDF
mkdir -p single-pages
pdfseparate combined-report.pdf single-pages/page-%d.pdf
echo "split into: $(ls single-pages)"

# 4. Extract a page range (e.g., pages 3-4 only)
pdfseparate -f 3 -l 4 combined-report.pdf single-pages/middle-%d.pdf
echo "extracted pages 3-4"

# 5. Count words: convert to text ("-" = to stdout), pipe into wc
echo "combined-report.pdf has $(pdftotext combined-report.pdf - | wc -w | tr -d ' ') words"

# 6. Word counts for a whole folder of PDFs, longest first
echo "words per part:"
for f in parts/*.pdf
do
  echo "  $(pdftotext "$f" - | wc -w | tr -d ' ') $f"
done | sort -nr

# Also useful from the same toolbox: pdftoppm (PDF -> images), and
# grep-ing through papers: pdftotext paper.pdf - | grep -i "causal"

