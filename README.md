``` r
if (!requireNamespace("pacman")) install.packages("pacman")
```

    ## Loading required namespace: pacman

``` r
pacman::p_load(readr, dplyr, lubridate, RSQLite)
source("R/simulate_noise.R")
source("R/create_tag_db.R")
source("R/tag_finder.R")
```

First pass at noise simulation and false positives
--------------------------------------------------

Very much a work in progress. But I seem to have `find_tags_unifile`
running. However, I don’t think that its defaults match what is
currently run on the Motus server (`find_tags_motus`?) so I’ve attempted
to fix that.

### Generate some noise

This works essentially by generating random time stamps over a period of
user-specified `duration` (hours) at a user-specified `noise_rate`
(noise pulses per second). One of the noisiest sites I’m aware of
generates noise at about 80 pulses per second, so I’ll use about 1/2 of
that as a start. Like Denis’s previous work, I by default assume all of
these pulses will pass the tagfinder’s frequency offset filter. That can
be tweaked with the `fix_noise_freq` argument. The function currently
generates an output `csv` that is ready to pass to `find_tags_unifile`
via the `tag_finder` function down the road.

``` r
# Simulate an hour of noise at 40 pulses/second
simulate_noise(duration = 1, noise_rate = 40, seed = 4242)
```

    ## Generated 144000 pulses over 1 hour of simulated time.

### Known tag database

I simply generated a composite `sqlite` file of \~ 260 registered tags
from projects 4 and 140. I could not get `find_tags_unifile` to work
with a `csv` of tag info, despite matching the field requirements as
outlined in `R/find_tags_unifile.cpp`. But the `sqlite` worked and was
easy enough to generate. By default it is output to
`Data/tag_db.sqlite`.

``` r
create_tag_db(sqlite_dir = "Data/tag_databases/")
```

    ## Created Data/tag_db.sqlite

### Running the tagfinder from R

Running `find_tags_unifile` with its defaults is as straightforward as
making a `system` call specifying only the known tag database and the
simulated SensorGnome noise data, capturing the output, and reading the
resulting `csv`.

``` r
command <- paste("find_tags_unifile", "Data/tag_db.sqlite", "Data/simulated_sg_noise.csv")
tf <- system(command, intern = TRUE)
tf <- readr::read_csv(tf)
nrow(tf)
```

    ## [1] 10296

``` r
head(tf)
```

    ## # A tibble: 6 x 13
    ##     ant     ts fullID  freq freq.sd   sig sig.sd noise run.id pos.in.run    slop
    ##   <dbl>  <dbl> <chr>  <dbl>   <dbl> <dbl>  <dbl> <dbl>  <dbl>      <dbl>   <dbl>
    ## 1     1 1.59e9 USFWS~     4       0   -40 0.0243   -50      6          1 0.001  
    ## 2     1 1.59e9 USFWS~     4       0   -40 0.0243   -50     18          1 0.002  
    ## 3     1 1.59e9 SCDNR~     4       0   -40 0.0243   -50     21          1 0.00175
    ## 4     1 1.59e9 SCDNR~     4       0   -40 0.0243   -50     55          1 0.00345
    ## 5     1 1.59e9 USFWS~     4       0   -40 0.0243   -50     62          1 0.00145
    ## 6     1 1.59e9 SCDNR~     4       0   -40 0.0243   -50     65          1 0.0015 
    ## # ... with 2 more variables: burst.slop <dbl>, ant.freq <dbl>

In looking through the [tagfinder
repo](https://github.com/MotusWTS/find_tags), it appears that
`find_tags_unifile` was compiled with slightly different defaults than
the current(?) `find_tags_motus` running on the Motus server. So I
wrapped `find_tags_unifile` to expose the main tag finder parameters of
interest, and attempt to set them to match the defaults of
`find_tags_motus`. The most noticeable default change is changing
`pulses_to_confirm` from 4 (default in `find_tags_unifile`) to 8
(`find_tags_motus`). This require a run length of at least 2 for the
false positive to be logged. The function that does this is
`tag_finder`.

``` r
tf_motus <- tag_finder("Data/tag_db.sqlite", "Data/simulated_sg_noise.csv")
nrow(tf_motus)
```

    ## [1] 110

For funsies, let’s simulate 4 hours of very noisy data and see what
comes out by default…

``` r
simulate_noise(4, noise_rate = 100, seed = 2020, out = "Data/very_noisy.csv")
```

    ## Generated 1440000 pulses over 4 hours of simulated time.

``` r
system.time(tf_noisy <- tag_finder("Data/tag_db.sqlite", "Data/very_noisy.csv"))
```

    ##    user  system elapsed 
    ##    2.73   25.61  182.29

``` r
nrow(tf_noisy)
```

    ## [1] 84081

``` r
tf_noisy_g <- group_by(tf_noisy, fullID, run.id) %>%
  summarize(ts = min(ts),
            runLen = max(pos.in.run))
```

    ## `summarise()` regrouping output by 'fullID' (override with `.groups` argument)

``` r
table(tf_noisy_g$runLen)
```

    ## 
    ##     2     3     4 
    ## 41060   639    11
