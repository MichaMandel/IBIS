# Example: Calculate IBIS for Global Big Day in Israel
# IBIS = Individual Birding Impact Score
#
# This script assumes that the eBird Basic Dataset file has already been
# downloaded and unzipped. The eBird data file is not included in this
# repository.

library(readr)
library(dplyr)
library(writexl)

# Load the main IBIS function
source("calculate_ibis.R")

# Path to the eBird Basic Dataset file
# Change this path to match the location of your downloaded eBird file.
ebd_file <- "ebd_IL_202605_202605_smp_relMay-2026/ebd_IL_202605_202605_smp_relMay-2026.txt"

# Read eBird data
ebd <- read_tsv(
  ebd_file,
  show_col_types = FALSE,
  guess_max = 100000
)

# Calculate IBIS for Global Big Day, Israel, May 2026
IL_MAY_2026 <- calculate_ibis(
  ebd = ebd,
  date = "2026-05-09",
  taxon_var = "COMMON NAME",
  region = "all",
  region_var = "STATE",
  species_only = TRUE,
  exotic_codes = c("", "N")
)

# Observer-level results
ibis_by_observer <- IL_MAY_2026$ibis_by_observer

# Print observers with positive IBIS
ibis_positive <- ibis_by_observer %>%
  filter(IBIS > 0) %>%
  arrange(desc(IBIS), `OBSERVER ID`)

# export to a csv file
write_csv(
  ibis_positive,
  "example_ibis_positive_IL_May2026.csv"
)
