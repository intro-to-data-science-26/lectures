# Live demo: Who is hammering my website?

A practical use case for the shell: analyzing a web server access log with
nothing but the commands from this session. The file `access.log` contains
~3,000 requests to a (fictional) personal academic website over three days
(Sep 21–23, 2026), in the standard Apache/nginx log format:

```
IP - - [date:time] "GET /path HTTP/1.1" status size "user agent"
```

Two things are hidden in the data for the audience to discover:
1. one IP address is scraping the site aggressively, and
2. the server threw errors during a one-hour outage.

Run the commands below one by one (from this directory). The whole pipeline
is also bundled in `analyze-logs.sh`.

## 1. First look: how big is this thing?

```bash
wc -l access.log
head -3 access.log
```

Too big to read by hand (`less access.log` to scroll; `q` to quit) — so let's ask questions instead.

## 2. Are there failed requests?

HTTP status 200 = OK, 404 = not found, 500 = server error. The status code
is surrounded by spaces after the quoted request:

```bash
grep -c ' 404 ' access.log
grep -c ' 500 ' access.log
```

500s are bad — our server is failing. Let's look at a few:

```bash
grep ' 500 ' access.log | head -5
```

## 3. Which pages are requested most?

The request path is the 7th space-separated field. `cut` it out, then use
the classic count-occurrences idiom `sort | uniq -c | sort -nr`:

```bash
cut -d' ' -f7 access.log | sort | uniq -c | sort -nr | head
```

One CSV file gets more traffic than the homepage?!

## 4. Who is doing all this? Top visitors by IP

```bash
cut -d' ' -f1 access.log | sort | uniq -c | sort -nr | head
```

One IP made ~1,900 of our ~3,000 requests. Let's see what it's up to:

```bash
grep '^203.0.113.42' access.log | head -5
grep '^203.0.113.42' access.log | cut -d'"' -f4 | sort -u
```

The user agent gives it away: `python-requests` — a scraper, fetching the
polls CSV every ~90 seconds, day and night. (Discussion point: that's how
your own scrapers look to server admins. Be polite, cache, honor robots.txt.)

## 5. When did the server fail? Errors by day and hour

The timestamp lives in field 4 (like `[22/Sep/2026:14:23:45`); splitting it
on `:` and keeping the first two pieces gives us day and hour:

```bash
grep ' 500 ' access.log | cut -d' ' -f4 | cut -d: -f1-2 | sort | uniq -c
```

Almost all 500s cluster in one hour — Sep 22, 14:00–15:00. An outage, not
random failures. (And the stragglers? The scraper occasionally trips the
server on its own.)

## 6. Put it in writing: build a report with redirects

```bash
echo "TRAFFIC REPORT $(date)"              >  report.txt
echo "Total requests: $(wc -l < access.log)" >> report.txt
echo ""                                     >> report.txt
echo "Top 5 pages:"                         >> report.txt
cut -d' ' -f7 access.log | sort | uniq -c | sort -nr | head -5 >> report.txt
cat report.txt
```

## 7. Bonus: a for loop over the days

```bash
for day in 21 22 23
do
  echo "Sep $day: $(grep -c "$day/Sep/2026" access.log) requests"
done
```

## 8. All of it in one script

```bash
bash analyze-logs.sh
```

Or make it executable once (`chmod +x analyze-logs.sh`) and run it as
`./analyze-logs.sh`. Ten lines of shell, instant answers — no R session,
no loading 363 KB into memory. This is the kind of quick forensic look
the shell is made for (and exactly the kind of script an AI coding agent
will happily draft for you — now you can read it).

## Cleanup

```bash
rm -f report.txt
```
