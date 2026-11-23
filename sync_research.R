#### Research themes snapshot (home and research pages) ####

## Copies a frozen, public-safe snapshot of the lab's research themes from the
## wiley_cv analysis into this repo:
##   research/research.json        what index.qmd and research.qmd show, and
##                                 nothing else (this repo is public)
##   research/figures/<ID>.png     the picked figures, copied byte for byte
##
## Run by hand from the repo root, only when Joshua asks for a refresh:
##   Rscript sync_research.R
## It is NOT called by run_website.R or the pages, so the themes only change
## when this is re-run. The source folder and the workbook are read-only: this
## script never writes there.
##
## Left out on purpose: per-theme and per-method paper counts, the years a
## theme has been active and "since <year>" counts (Joshua keeps those
## private), trainee flags, the analysis's paper IDs and its local path.

if (!file.exists("index.qmd") || !file.exists("run_website.R")) {
  stop("Run sync_research.R from the website repo root.")
}

library(jsonlite)
## cvpath and parseReference(), for the papers' short citations
source("package_setup.R", echo = FALSE)

src <- "/Users/wileyj/wiley_cv/track_record/2026-10-lab-themes"
outDir <- "research"
figDir <- file.path(outDir, "figures")

readSrc <- function(...) fromJSON(file.path(src, ...), simplifyVector = FALSE)
themes <- readSrc("themes.json")
copy <- readSrc("site_copy.json")
picks <- readSrc("hero_picks.json")
picks <- picks[!startsWith(names(picks), "_")]  # keys starting with "_" are notes

## public labels for the profiles' study designs (as in build_mockup.py)
designLabels <- c(
  "randomised controlled trial" = "Randomised trial",
  "trial protocol" = "Trial protocol",
  "secondary analysis of a trial" = "Trial analysis",
  "ema / daily diary" = "Daily diary study",
  "longitudinal cohort" = "Cohort study",
  "cross-sectional" = "Survey study",
  "qualitative" = "Qualitative",
  "mixed methods" = "Mixed methods",
  "systematic review / meta-analysis" = "Systematic review",
  "methods development / simulation" = "New method",
  "other" = "Study")

designLabel <- function(paperId) {
  design <- readSrc("profiles", paste0(paperId, ".json"))$design
  if (is.null(design) || is.na(designLabels[design])) "Study" else unname(designLabels[design])
}

## A paper's short citation: "Le et al.", or "Smith & Jones" for two authors.
## The analysis only records the first author, so the authors are counted in
## the paper's reference in the Publications sheet (matched by DOI). A paper
## not found there gets "<first author> et al." and a warning.
pubRefs <- as.character(read_excel(cvpath, sheet = "Publications")$Reference)
shortAuthor <- function(p) {
  ref <- pubRefs[grepl(tolower(p$doi), tolower(pubRefs), fixed = TRUE)]
  author <- if (length(ref) == 1) parseReference(ref)$author else NA_character_
  if (is.na(author)) {
    warning("No single Publications row for ", p$doi, "; using \"",
            sub(",.*$", "", p$first_author), " et al.\".", call. = FALSE)
    author <- paste(sub(",.*$", "", p$first_author), "et al.")
  }
  author
}

## Journal as shown on the site: drop a subtitle, e.g. "Health Psychology:
## Official Journal of the Division ..." -> "Health Psychology"
shortJournal <- function(journal) sub(":\\s.*$", "", journal)

## Figure ID for a paper, or NULL for a text card. A paper missing from
## hero_picks.json also gets a text card (with a warning).
figureFor <- function(paperId) {
  if (!paperId %in% names(picks)) {
    warning("No hero pick for ", paperId, "; it gets a text card.", call. = FALSE)
    return(NULL)
  }
  fig <- picks[[paperId]]
  if (is.null(fig)) return(NULL)
  if (!file.exists(file.path(src, "figures", "candidates", paste0(fig, ".png")))) {
    stop("Picked figure ", fig, " is missing from figures/candidates.")
  }
  if (!grepl("-[FI][0-9]+$", fig)) stop("Picked figure ", fig, " is not a Figure (F) or graphic (I).")
  fig
}

## Credit line without the journal, which the page adds in italics:
## "Figure 2 reproduced from Le et al. (2026)". An I<n> ID's number is only a
## counter, so it gets plain "Figure".
creditFor <- function(fig, p) {
  kind <- sub("^.*-([FI])([0-9]+)$", "\\1", fig)
  num <- sub("^.*-([FI])([0-9]+)$", "\\2", fig)
  sprintf("%s reproduced from %s (%s)",
          if (kind == "F") paste("Figure", num) else "Figure", shortAuthor(p), p$year)
}

## the fields the page needs for one paper; `extra` holds the card text. A
## paper with no figure gets a text card instead, showing `finding` from its
## profile: the plain-language `summary` for a representative. An exemplar's
## summary is already its headline, so its text card shows the profile's
## `key_finding` instead (as build_mockup.py does).
paperRecord <- function(p, extra, findingField = "summary") {
  fig <- figureFor(p$paper_id)
  if (is.null(fig)) {
    profile <- readSrc("profiles", paste0(p$paper_id, ".json"))
    extra$finding <- profile[[findingField]]
    if (is.null(extra$finding)) extra$finding <- profile$summary
    if (is.null(extra$finding)) stop("Profile for ", p$paper_id, " has no text for its text card.")
  }
  ## `design` is not shown as a tag; research.qmd only uses it to label a
  ## trial protocol's text card "Study plan"
  c(list(title = p$title, year = p$year,
         journal = shortJournal(p$journal), doi = p$doi,
         author = shortAuthor(p),
         design = designLabel(p$paper_id)),
    extra,
    list(figure = fig, credit = if (is.null(fig)) NULL else creditFor(fig, p)))
}

themeOut <- lapply(themes$topic_themes, function(t) {
  tc <- copy$themes[[t$id]]
  if (is.null(tc)) stop("site_copy.json has no copy for theme ", t$id)
  list(
    id = t$id, anchor = tolower(t$id), title = tc$title, blurb = tc$blurb,
    exemplar = paperRecord(t$exemplar, list(summary = t$exemplar$summary),
                           findingField = "key_finding"),
    representatives = lapply(t$representatives, function(r) {
      paperRecord(r, list(why = r$why))
    }))
})

methodsOut <- lapply(themes$methods_strand, function(m) {
  oneLiner <- copy$methods[[m$id]]
  if (is.null(oneLiner)) stop("site_copy.json has no methods line for ", m$id)
  list(id = m$id, name = m$name, one_liner = oneLiner)
})

snapshot <- list(
  generated = format(Sys.Date()),
  source_generated = themes$generated,
  intro = copy$intro,
  themes = themeOut,
  methods = methodsOut,
  software = unlist(copy$software))

dir.create(figDir, recursive = TRUE, showWarnings = FALSE)
write_json(snapshot, file.path(outDir, "research.json"),
           auto_unbox = TRUE, pretty = TRUE, null = "null")

## figures: copy the picked ones unchanged; remove any no longer picked
figs <- unique(unlist(lapply(themeOut, function(t) {
  lapply(c(list(t$exemplar), t$representatives), `[[`, "figure")
})))
for (f in figs) {
  ok <- file.copy(file.path(src, "figures", "candidates", paste0(f, ".png")),
                  file.path(figDir, paste0(f, ".png")), overwrite = TRUE, copy.date = TRUE)
  if (!ok) stop("Could not copy figure ", f)
}
stale <- setdiff(list.files(figDir), paste0(figs, ".png"))
if (length(stale) > 0) invisible(file.remove(file.path(figDir, stale)))

cat(sprintf("Wrote %s: %d themes, %d papers, %d figures%s.\n",
            file.path(outDir, "research.json"), length(themeOut),
            sum(vapply(themeOut, function(t) 1L + length(t$representatives), 1L)),
            length(figs),
            if (length(stale) > 0) sprintf(", removed %d unpicked", length(stale)) else ""))
