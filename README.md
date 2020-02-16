
<!-- README.md is generated from README.Rmd. Please edit that file -->

# parable

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

The goal of parable is to enable the user to use `fable` in parallel.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("markfairbanks/parable")
```

Note that `parable` uses a custom version of `fabletools`, which can be
installed here:

``` r
# install.packages("devtools")
devtools::install_github("markfairbanks/fabletools")
```

## Functions

`parable` has 3 core functions:

  - `parallel_model()`
  - `parallel_forecast()`
  - `parallel_accuracy()`

Each function is used just like the functions from `fable`, but a
`future::plan` must be set.

We start with an example tsibble with 50 time-series.

``` r
pacman::p_load(tidyverse, parable, janitor, lubridate,
               tsibble, fable, fabletools, feasts, tsibbledata)

aus_ts <- tsibbledata::aus_retail %>%
  rename_all(janitor::make_clean_names) %>%
  update_tsibble(key = series_id, index = month) %>%
  select(-state, -industry) %>%
  filter(year(month) >= 2010) %>%
  group_by_key() %>%
  filter(group_indices() <= 50) %>%
  ungroup()

aus_ts
#> # A tsibble: 5,400 x 3 [1M]
#> # Key:       series_id [50]
#>    series_id    month turnover
#>    <chr>        <mth>    <dbl>
#>  1 A3349335T 2010 Jan    2054.
#>  2 A3349335T 2010 Feb    1817.
#>  3 A3349335T 2010 Mar    2018.
#>  4 A3349335T 2010 Apr    1951.
#>  5 A3349335T 2010 May    1989.
#>  6 A3349335T 2010 Jun    1888.
#>  7 A3349335T 2010 Jul    2036.
#>  8 A3349335T 2010 Aug    2013.
#>  9 A3349335T 2010 Sep    1984.
#> 10 A3349335T 2010 Oct    2076.
#> # … with 5,390 more rows
```

The below chunk shows how to use `parable`, with `tictoc` used to show
timings of the `parallel_model()` step:

``` r
pacman::p_load(future, future.apply)

plan(multiprocess, workers = 5)

tictoc::tic()

parable_mbl <- aus_ts %>%
  parallel_model(ets = ETS(turnover))

tictoc::toc()
#> 13.909 sec elapsed
```

And timings for the `parallel_forecast()` step:

``` r
tictoc::tic()

parable_fbl <- parable_mbl %>%
  parallel_forecast(h = 12)

tictoc::toc()
#> 5.439 sec elapsed
```

In comparison to normal `fable`, we can see the time improvements:

``` r
tictoc::tic()

fable_mbl <- aus_ts %>%
  model(ets = ETS(turnover))

tictoc::toc()
#> 48.257 sec elapsed
```

``` r
tictoc::tic()

parable_fbl <- fable_mbl %>%
  forecast(h = 12)

tictoc::toc()
#> 0.201 sec elapsed
```
