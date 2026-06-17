# IBIS: Individual Birding Impact Score

IBIS, the **Individual Birding Impact Score**, is a marginal-contribution index for collective birding events such as eBird Global Big Day.

For a given day or period, IBIS measures how many taxa would be absent from the collective eBird list if a given observer's records were removed.

In words:

> An observer's IBIS is the number of taxa that were reported by that observer and by no other independent birding unit during the selected period and region.

The index is intended to highlight complementary birding effort: observers who add taxa that would otherwise be missing from the collective list.

## Shared checklists

Shared eBird checklists require special treatment. Several observers may be part of the same group, but not every observer necessarily reports every taxon.

IBIS therefore uses two steps:
  
  1. A shared checklist group is treated as one independent **birding unit** when deciding whether a taxon was unique.
2. Credit is assigned only to the individual observers who personally reported that taxon.

Thus, if a shared group is the only birding unit to report a species, only the observers in that group who actually reported the species receive IBIS credit for it.

## Example output

To illustrate the output of the function, this repository includes example CSV files in the `examples` folder.

The file `ibis_positive_IL_May2026.csv` shows observer-level IBIS results for Israel Global Big Day May 2026, including only observers with positive IBIS. 

This file is one of the outputs of `calculate_ibis()`. The original eBird data files are not included in this repository.

## Installation

This repository currently provides an R function rather than a full R package.

Clone or download the repository, then source the function:
  
  ```r
source("R/calculate_ibis.R")
```

Required R packages:
  
  ```r
install.packages(c("readr", "dplyr", "tidyr", "stringr"))
```

## Basic use

```r
library(readr)
library(dplyr)

source("calculate_ibis.R")

ebd <- read_tsv(
  "path/to/ebd_file.txt",
  show_col_types = FALSE,
  guess_max = 100000
)

ibis_results <- calculate_ibis(
  ebd = ebd,
  date = "2026-04-09"
)

ibis_results$ibis_by_observer
ibis_results$observer_marginal_taxa
```

For large eBird files, it is recommended to filter the file before reading it fully into R. The [`auk`](https://cornelllabofornithology.github.io/auk/) package is designed for this purpose and can filter large eBird Basic Dataset files by date before import.

For example:

```r
library(auk)
library(readr)

ebd_file <- "path/to/ebd_file.txt"
filtered_file <- "ebd_global_big_day.txt"

auk_ebd(ebd_file) %>%
  auk_date(date = "2026-04-09") %>%
  auk_filter(file = filtered_file, overwrite = TRUE)

ebd <- read_tsv(
  filtered_file,
  show_col_types = FALSE,
  guess_max = 100000
)

ibis_results <- calculate_ibis(
  ebd = ebd,
  date = NULL
)
```

Here `date = NULL` is used in `calculate_ibis()` because the file has already been filtered to the desired date by `auk`.
## Output

The function returns a list with four objects:
  
  * `ibis_by_observer`: one row per observer, including the IBIS score and the list of marginal taxa.
* `observer_marginal_taxa`: long-format table of observer-taxon marginal contributions.
* `filtered_ebd`: the eBird records used after filtering.
* `unique_taxa_by_unit`: taxa that were reported by only one independent birding unit.

## Choosing the taxon column

By default, IBIS uses eBird common names:
  
  ```r
taxon_var = "COMMON NAME"
```

To use scientific names instead:
  
  ```r
ibis_results <- calculate_ibis(
  ebd = ebd,
  date = "2026-04-09",
  taxon_var = "SCIENTIFIC NAME"
)
```

By default, the function keeps only records with:
  
  ```r
CATEGORY == "species"
```

To include all eBird taxon categories, use:
  
  ```r
ibis_results <- calculate_ibis(
  ebd = ebd,
  date = "2026-04-09",
  species_only = FALSE
)
```

## Choosing states or regions

By default, all regions in the input data are used:
  
  ```r
region = "all"
```

To restrict the analysis to one state or region:
  
  ```r
ibis_results <- calculate_ibis(
  ebd = ebd,
  date = "2026-04-09",
  region = "Haifa",
  region_var = "STATE"
)
```

To use several states or regions:
  
  ```r
ibis_results <- calculate_ibis(
  ebd = ebd,
  date = "2026-04-09",
  region = c("Haifa", "Tel-Aviv"),
  region_var = "STATE"
)
```

The appropriate region column may vary by eBird file. Use:
  
  ```r
names(ebd)
```

to inspect the available columns.

## Filtering by hotspot, region, or polygon before calculating IBIS

The function is designed to work on any already-filtered eBird data frame. This makes it flexible.

eBird files include variables that can be used to filter observations before calculating IBIS, including regional identifiers, hotspot/locality identifiers, longitude, and latitude.

For example, to analyze one hotspot:
  
  ```r
hotspot_ebd <- ebd %>%
  filter(`LOCALITY ID` == "L62761474")

ibis_results <- calculate_ibis(
  ebd = hotspot_ebd
)
```


To analyze a self-selected geographic area, filter by longitude and latitude before running the function:
  
  ```r
area_ebd <- ebd %>%
  filter(
    LONGITUDE >= 34.7,
    LONGITUDE <= 35.0,
    LATITUDE >= 31.6,
    LATITUDE <= 31.9
  )

ibis_results <- calculate_ibis(
  ebd = area_ebd,
  date = "2026-04-09"
)
```

For precise polygon filtering, users can use spatial packages such as `sf` to select records inside a polygon before applying `calculate_ibis()`.

## Exotic and introduced taxa

By default, `calculate_ibis()` includes native taxa and naturalized taxa only.

In eBird, the column `EXOTIC CODE` indicates whether a taxon is native or introduced:

| `EXOTIC CODE` | Meaning |
|---|---|
| blank or missing | Native |
| `N` | Naturalized |
| `P` | Provisional |
| `X` | Escapee |

The default setting is Native + Naturalized:

```r
exotic_codes = c("", "N")
