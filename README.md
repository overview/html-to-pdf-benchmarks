Tests to compare HTML-to-PDF rendering speed.

# What we're optimizing

* 30x small.html -> small.txt + small.pdf + small.jpg
* 15x medium.html -> medium.txt + medium.pdf + medium.jpg
* 2x large.html -> large.txt + large.pdf + large.jpg

# Rules

* No networking (run offline)
* No scripts
* No companion files
* No assumptions about input files (e.g., do not force a charset)
* No multiprocessing: run on 1 CPU
* No shared state between conversions (each convert starts with a clean slate)
* Conversion happens in a separate process, which gives exit code 0

# Allowed speedups

* Daemons (like chromedriver) are allowed
* Setup code (before first convert) is allowed
* "Ugly" output is okay, as long as the text is all there. (The rules make most
  HTML pages look different from they do in the wild.)

# To implement a benchmark

Create `STRATEGY/setup`, `STRATEGY/teardown` and `STRATEGY/convert`, where
`STRATEGY` looks like `using-XXX`. (The `using-` prefix is key.)

Run the benchmarks on your computer:

`docker build .`
`docker run -it --rm $(docker build --quiet .)`

# Results

## Chromium

```
small.html: 279ms for 30 conversions (avg 9ms)
medium.html: 922ms for 15 conversions (avg 61ms)
large.html: 452287ms for 2 conversions (avg 226143ms)
using-chromium: finished in 453488ms
```

Peak RAM usage (seen via `systemd-cgtop`): **1.9GB**

Notes on Chromium:

* This converter breaks the "no shared state" rule. The Chromium daemon stays on
  for the duration of the test, accelerating startup considerably.
* This converters bends the "no multiprocessing" rule. CPU usage (seen on
  `systemd-cgtop`) rises as high as 117%.
* Output PDFs are limited to 512MB because of
  https://bugs.chromium.org/p/chromium/issues/detail?id=748956. (v8's maximum
  String length is 2GB of UTF-16; 512MB of Base64 consumes 2GB of UTF-16.) That
  size might consume an extra 4GB of RAM, since it would need to be transmitted
  over a pipe.

In brief: we bent the rules to get the best possible result, just to see what's
possible.

## SlimerJS (Firefox)

```
small.html: 742ms for 30 conversions (avg 24ms)
medium.html: 6671ms for 15 conversions (avg 444ms)
large.html: 88102ms for 2 conversions (avg 44051ms)
using-slimerjs: finished in 95515ms
```

Peak RAM usage (seen via `systemd-cgtop`): **0.9GB**

## Conclusion

Chromium is much faster for a typical HTML file. But Firefox gracefully scales
to larger documents, consuming a fraction of the RAM and CPU. Firefox completed
our test suite 4.7x more quickly than Chromium, and it's less likely to leak
information from one conversion to the next.
