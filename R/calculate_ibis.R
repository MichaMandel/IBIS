#' Calculate IBIS: Individual Birding Impact Score
#'
#' IBIS is the number of taxa that would be absent from a collective eBird list
#' if a given observer's records were removed.
#'
#' @param ebd A data frame containing eBird Basic Dataset records,
#'   using original eBird column names.
#' @param date Optional date or vector of dates, in "YYYY-MM-DD" format.
#'   If NULL, all dates in `ebd` are used.
#' @param taxon_var eBird column to use as the taxon identifier.
#'   Default is "COMMON NAME". Use "SCIENTIFIC NAME" for scientific names.
#' @param region Optional state/region filter. Default is "all".
#'   Can be a single value or a vector. Uses the column specified by
#'   `region_var`.
#' @param region_var eBird column used for state/region filtering.
#'   Default is "STATE".
#' @param species_only Logical. If TRUE, keeps only records with
#'   CATEGORY == "species". Default is TRUE.
#'
#' @return A list with:
#'   \describe{
#'     \item{ibis_by_observer}{Observer-level IBIS scores.}
#'     \item{observer_marginal_taxa}{Long-format observer-taxon marginal contributions.}
#'     \item{filtered_ebd}{The eBird records used after filtering.}
#'     \item{unique_taxa_by_unit}{Taxa unique to one independent birding unit.}
#'   }
#'
#' @importFrom dplyr %>% filter mutate distinct count left_join semi_join
#'   group_by summarise arrange n_distinct if_else
#' @importFrom tidyr replace_na
#'
#' @export
calculate_ibis <- function(
    ebd,
    date = NULL,
    taxon_var = "COMMON NAME",
    region = "all",
    region_var = "STATE",
    species_only = TRUE
) {
  required_cols <- c(
    "OBSERVATION DATE",
    "CATEGORY",
    "GROUP IDENTIFIER",
    "OBSERVER ID",
    taxon_var
  )
  
  missing_cols <- setdiff(required_cols, names(ebd))
  
  if (length(missing_cols) > 0) {
    stop(
      "The following required columns are missing from `ebd`: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }
  
  if (!identical(region, "all") && !(region_var %in% names(ebd))) {
    stop(
      "The region column `", region_var, "` was not found in `ebd`.",
      call. = FALSE
    )
  }
  
  filtered_ebd <- ebd
  
  if (!is.null(date)) {
    filtered_ebd <- filtered_ebd %>%
      filter(`OBSERVATION DATE` %in% date)
  }
  
  if (!identical(region, "all")) {
    filtered_ebd <- filtered_ebd %>%
      filter(.data[[region_var]] %in% region)
  }
  
  if (species_only) {
    filtered_ebd <- filtered_ebd %>%
      filter(CATEGORY == "species")
  }
  
  dat_units <- filtered_ebd %>%
    mutate(
      birding_unit = if_else(
        is.na(`GROUP IDENTIFIER`) | `GROUP IDENTIFIER` == "",
        paste0("solo_", `OBSERVER ID`),
        paste0("group_", `GROUP IDENTIFIER`)
      ),
      taxon = .data[[taxon_var]]
    ) %>%
    filter(!is.na(taxon), taxon != "")
  
  taxon_unit_counts <- dat_units %>%
    distinct(taxon, birding_unit) %>%
    count(taxon, name = "n_birding_units")
  
  unique_taxa_by_unit <- dat_units %>%
    distinct(taxon, birding_unit) %>%
    left_join(taxon_unit_counts, by = "taxon") %>%
    filter(n_birding_units == 1)
  
  observer_marginal_taxa <- dat_units %>%
    distinct(`OBSERVER ID`, taxon, birding_unit) %>%
    semi_join(unique_taxa_by_unit, by = c("taxon", "birding_unit")) %>%
    arrange(`OBSERVER ID`, taxon)
  
  ibis_by_observer <- observer_marginal_taxa %>%
    group_by(`OBSERVER ID`) %>%
    summarise(
      IBIS = n_distinct(taxon),
      marginal_taxa = paste(sort(unique(taxon)), collapse = "; "),
      .groups = "drop"
    )
  
  all_observers <- filtered_ebd %>%
    distinct(`OBSERVER ID`)
  
  ibis_by_observer <- all_observers %>%
    left_join(ibis_by_observer, by = "OBSERVER ID") %>%
    mutate(
      IBIS = tidyr::replace_na(IBIS, 0L),
      marginal_taxa = tidyr::replace_na(marginal_taxa, "")
    ) %>%
    arrange(desc(IBIS), `OBSERVER ID`)
  
  list(
    ibis_by_observer = ibis_by_observer,
    observer_marginal_taxa = observer_marginal_taxa,
    filtered_ebd = filtered_ebd,
    unique_taxa_by_unit = unique_taxa_by_unit
  )
}
