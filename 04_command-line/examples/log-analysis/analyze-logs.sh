#!/bin/sh
# Quick forensic look at a web server access log.
# Usage: ./analyze-logs.sh [logfile]   (defaults to access.log)

LOG="${1:-access.log}"

echo "=== Traffic report for $LOG ==="
echo "Total requests:  $(wc -l < "$LOG" | tr -d ' ')"
echo "Not found (404): $(grep -c ' 404 ' "$LOG")"
echo "Errors (500):    $(grep -c ' 500 ' "$LOG")"

echo ""
echo "--- Top 5 pages ---"
cut -d' ' -f7 "$LOG" | sort | uniq -c | sort -nr | head -5

echo ""
echo "--- Top 5 visitors (by IP) ---"
cut -d' ' -f1 "$LOG" | sort | uniq -c | sort -nr | head -5

echo ""
echo "--- Server errors by day and hour ---"
grep ' 500 ' "$LOG" | cut -d' ' -f4 | cut -d: -f1-2 | sort | uniq -c

echo ""
echo "--- Requests per day ---"
for day in $(cut -d: -f1 "$LOG" | cut -d'[' -f2 | sort -u)
do
  echo "$day: $(grep -c "$day" "$LOG") requests"
done
