#### misc
library(fontawesome)
library(knitr)
library(quarto)
library(JWileymisc)

#### data
library(readxl)
library(data.table)

#### graphs
library(ggplot2)
library(plotly)
library(ggpubr)

if (Sys.info()[["sysname"]] == "Linux") {
    basedir <- "/mnt/c/Users/jwile/OneDrive"
    cvpath <- file.path(basedir, "WileyDossier/CV_Full.xlsx")
} else if (Sys.info()[["sysname"]] == "Darwin") {
    basedir <- "/Users/wileyj/wiley_cv"
    cvpath <- file.path(basedir, "CV_Full.xlsx")
} else {
    basedir <- Sys.getenv("OneDriveConsumer")
    cvpath <- file.path(basedir, "WileyDossier/CV_Full.xlsx")
}

#### helpers shared across pages ####

## The lab's contact address. Every email link on the site (pages and the
## footer in run_website.R) is built from it with mailtoUrl().
labEmail <- "joshua.wiley@monash.edu"

## A mailto: link to labEmail, with a subject line when given:
## mailtoUrl("Honours enquiry") opens an email titled "[BML] Honours enquiry",
## so incoming mail can be filtered by audience.
mailtoUrl <- function(subject = NULL) {
  if (is.null(subject) || !nzchar(subject)) return(paste0("mailto:", labEmail))
  paste0("mailto:", labEmail, "?subject=",
         utils::URLencode(paste("[BML]", subject), reserved = TRUE))
}

## HTML id for a project's heading on projects.qmd. Project names can contain
## spaces or "/", which break an unquoted id or a URL fragment.
projectAnchor <- function(name) gsub("[^A-Za-z0-9-]+", "-", trimws(name))

## Whole number with thousands separators, e.g. 970000 -> "970,000" (format()
## would switch to scientific notation from 1e6).
fmtNum <- function(x) formatC(x, format = "d", big.mark = ",")

## Largest multiple of `unit` strictly below `x`, for ">N" statements. Always
## rounds down so the site never claims more than the data: 25.98 -> 25,
## 26.88 -> 26, and exactly 26 -> 25 (">26" would be false).
belowRound <- function(x, unit) unit * (ceiling(x / unit) - 1)

## Current academic position, e.g. "Associate Professor" (Positions sheet is
## newest first; honorary roles are skipped).
currentPosition <- function() {
  pos <- as.data.table(read_excel(cvpath, sheet = "Positions"))
  pos[Ended == "Current" & !grepl("Honorary", Position), Position][1]
}

## Grant roles where JFW is a chief investigator. Funding figures and the CV's
## grants list count only these (not AI, Supervisor or Trainee).
ciRoles <- c("CIA", "CI", "CIC", "CID")

## Total AUD of grants where JFW is a chief investigator.
## The few small USD grants are left out rather than converted.
ciGrantTotalAUD <- function() {
  grants <- as.data.table(read_excel(cvpath, sheet = "Grants"))
  grants[Role %in% ciRoles & Currency == "AUD",
         sum(Total, na.rm = TRUE)]
}

## People sheet rows the site may list or count. Rows with Exclude == 1 stay in
## the workbook as records only, so they are dropped here; the column may be
## missing in older workbooks. Withdrawn rows are left to the caller.
readPeople <- function() {
  people <- as.data.table(read_excel(cvpath, sheet = "People"))
  if ("Exclude" %in% names(people)) people <- people[is.na(Exclude) | Exclude != 1]
  people
}

## Citations for JFW from the workbook's Citations sheet, which ~/wiley_cv
## refreshes (metrics/); the site never contacts Google Scholar itself.
## Returns list(byYear = data.frame(year, cites), total, asOf, source), or NULL
## if the sheet or source is missing. The total prefers TotalCitations, which
## is higher than the yearly sum (Scholar's yearly series starts in 2014).
getCitations <- function(source = "Google Scholar") {
  ct <- tryCatch(as.data.table(read_excel(cvpath, sheet = "Citations")),
                 error = function(e) NULL)
  if (is.null(ct)) return(NULL)
  ct <- ct[Source == source]
  byYear <- ct[Metric == "Citations" & !is.na(Year) & !is.na(Value),
               .(year = Year, cites = Value)][order(year)]
  if (nrow(byYear) == 0) return(NULL)
  total <- ct[Metric == "TotalCitations", Value][1]
  if (is.na(total)) total <- sum(byYear$cites)
  list(byYear = as.data.frame(byYear), total = total,
       asOf = as.Date(ct$AsOf[1]), source = source)
}

## Total R package downloads from the workbook's SoftwareStats sheet, which
## ~/wiley_cv refreshes (metrics/). Counts come from Posit's CRAN mirror only,
## so they are a floor. Returns list(total, packages, asOf), or NULL if the
## sheet has no download data.
getDownloads <- function() {
  ss <- tryCatch(as.data.table(read_excel(cvpath, sheet = "SoftwareStats")),
                 error = function(e) NULL)
  if (is.null(ss)) return(NULL)
  ss <- ss[Metric == "Downloads" & !is.na(Value)]
  if (nrow(ss) == 0) return(NULL)
  to <- as.Date(ss$To)
  list(total = sum(ss$Value), packages = uniqueN(ss$Package),
       asOf = if (all(is.na(to))) as.Date(NA) else max(to, na.rm = TRUE))
}

#### helpers for pages that write markdown from R chunks ####

## Plain text made safe for the Pandoc markdown an `output: asis` chunk cat()s
## (names, titles, findings): backslash-escapes the characters markdown would
## read as formatting, links, maths or citations, e.g. "*", "[", "$", "@".
mdEscape <- function(x) gsub("([][\\\\`*_{}<>#|~^$@])", "\\\\\\1", x)

## Pixel size of a PNG, read from its header, so a page can give an <img> its
## width and height and the browser reserves the space before it loads.
pngSize <- function(path) {
  b <- as.integer(readBin(path, "raw", 24))
  c(width = sum(b[17:20] * 256^(3:0)), height = sum(b[21:24] * 256^(3:0)))
}

## Parts of an APA 7 reference as written in the Publications sheet's
## Reference column (markdown; see ~/wiley_cv/CLAUDE.md), e.g.
##   \*Do, T. T., ... **Wiley, J. F.** (2026). Title. *JAMA Network Open, 9*(8),
##   e2630320. https://doi.org/10.1001/...
## Returns list(author = "Do et al.", year, title (markdown, final full stop
## dropped), journal, doi (a URL)); any part it can't find is NA.
parseReference <- function(ref) {
  out <- list(author = NA_character_, year = NA_integer_, title = NA_character_,
              journal = NA_character_, doi = NA_character_)
  ref <- trimws(ref)
  if (is.na(ref) || !nzchar(ref)) return(out)
  m <- regmatches(ref, regexec("^(.*?)\\s*\\((\\d{4})[a-z]?\\)\\.\\s+(.*)$", ref))[[1]]
  if (length(m) == 4) {
    authors <- gsub("\\\\\\*|\\*\\*", "", m[2])          # trainee "\*" and bold
    first <- trimws(sub(",.*$", "", authors))
    if (nzchar(first)) out$author <- paste0(first, if (grepl("&|\\.\\.\\.", authors)) " et al.")
    out$year <- as.integer(m[3])
    ## title: up to the sentence end before the italic journal
    t <- regmatches(m[4], regexec("^(.+?[.?!])\\s+\\*([^*]+)\\*", m[4]))[[1]]
    if (length(t) == 3) {
      out$title <- sub("\\.$", "", trimws(t[2]))
      out$journal <- trimws(sub(",\\s*\\d[^,]*$", "", sub(",\\s*$", "", t[3])))
    }
  }
  doi <- regmatches(ref, regexpr("https?://doi\\.org/\\S+", ref))
  if (length(doi) == 1) out$doi <- sub("[.,;]+$", "", doi)
  out
}

## First author of an APA reference: surname and all initials, e.g.
## "\\*Tung, N. Y. C., ..." -> list(surname = "Tung", initials = c("N", "Y", "C")).
firstAuthorName <- function(ref) {
  authors <- gsub("\\\\\\*|\\*\\*", "", sub("\\s*\\(\\d{4}[a-z]?\\)\\..*$", "", ref))
  m <- regmatches(authors, regexec("^\\s*([^,]+),\\s*((?:[A-Za-z]\\.?[ -]*)+)", authors, perl = TRUE))[[1]]
  if (length(m) != 3) return(list(surname = NA_character_, initials = character(0)))
  list(surname = trimws(m[2]), initials = toupper(regmatches(m[3], gregexpr("[A-Za-z]", m[3]))[[1]]))
}

## TRUE for references whose first author is someone Joshua is (or was) primary
## supervisor for (People rows with Primary == 1, Exclude rows dropped). Matched
## on surname plus any shared initial, so a published English initial still
## matches ("Tung, N. Y. C." is Yan Chi Tung) while two people with the same
## surname stay apart (Rebecca vs Tania Wallace).
primaryFirstAuthor <- function(refs) {
  primary <- readPeople()[Primary == 1]
  givenInitials <- lapply(primary$GivenName, function(g) {
    toupper(substr(Filter(nzchar, unlist(strsplit(gsub("[().]", " ", g), "[ -]+"))), 1, 1))
  })
  vapply(refs, function(r) {
    a <- firstAuthorName(r)
    if (is.na(a$surname)) return(FALSE)
    same <- which(tolower(primary$FamilyName) == tolower(a$surname))
    any(vapply(same, function(i) any(a$initials %in% givenInitials[[i]]), TRUE))
  }, TRUE, USE.NAMES = FALSE)
}

## The newest research papers the lab leads: the first `n` Empirical, Review or
## Protocol rows of the Publications sheet (newest year first; the sheet is
## newest first within a year) where Joshua is first or last author
## (FirstLast) or the first author is one of his primary supervisees, parsed
## with parseReference(). Kind is the label shown on the page: "New paper",
## "Review", "Trial protocol" or "Study protocol".
latestPublications <- function(n = 4, types = c("Empirical", "Review", "Protocol")) {
  pubs <- as.data.table(read_excel(cvpath, sheet = "Publications"))
  pubs[, Row := .I]
  pubs <- pubs[Type %in% types][order(-Year, Row)]
  pubs <- pubs[FirstLast %in% 1 | primaryFirstAuthor(Reference)][seq_len(min(n, .N))]
  parts <- rbindlist(lapply(pubs$Reference, function(r) as.data.table(parseReference(r))))
  pubs <- cbind(pubs[, .(Year, Type, Reference)],
                parts[, .(Author = author, Title = title, Journal = journal, DOI = doi)])
  pubs[, Kind := fcase(
    Type == "Review", "Review",
    Type == "Protocol" & grepl("trial", Title, ignore.case = TRUE), "Trial protocol",
    Type == "Protocol", "Study protocol",
    default = "New paper")]
  pubs[]
}

## Counts for page copy from readPeople() (Exclude rows dropped; withdrawn roles
## are not counted): current members (people, not roles), completed doctoral theses (PhD and
## DPsych; Visiting PhD students are not counted), Honours graduates, and the
## first year anyone completed a role in the lab.
labCounts <- function(people = readPeople()) {
  people <- people[Status != "Withdrew"]
  done <- people[Status == "Completed"]
  list(current = uniqueN(people[Status == "Current", paste(GivenName, FamilyName)]),
       theses = done[grepl("^(PhD|DPsych)", Type), .N],
       honours = done[Type == "Honours", .N],
       since = if (any(!is.na(done$Ended))) min(done$Ended, na.rm = TRUE) else NA)
}

#### research themes snapshot (index.qmd, research.qmd) ####

## The themes come from a frozen snapshot made by sync_research.R (see
## CLAUDE.md): pages read only research/research.json and research/figures/,
## never the wiley_cv analysis. readResearch() puts the themes in the site's
## display order, applies the site's title overrides, and adds the short label
## the eyebrows use ("INSOMNIA & FATIGUE"); a theme missing from themeShort uses
## its title, and one missing from themeOrder goes last.
## Order and title chosen by Joshua (2026-10-07); the snapshot keeps the
## analysis's own order and names.
themeOrder <- c("INSOMNIA", "PSYONC", "SLEEP", "STRESS", "TIMEUSE")
themeTitle <- c(PSYONC = "Psychosocial cancer care")
themeShort <- c(STRESS = "Stress & emotions", SLEEP = "Everyday sleep",
                INSOMNIA = "Insomnia & fatigue", TIMEUSE = "24-hour time use",
                PSYONC = "Psychosocial cancer care")

readResearch <- function(path = "research/research.json") {
  research <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  ids <- vapply(research$themes, `[[`, "", "id")
  research$themes <- research$themes[order(match(ids, themeOrder, nomatch = length(themeOrder) + 1))]
  for (i in seq_along(research$themes)) {
    id <- research$themes[[i]]$id
    if (id %in% names(themeTitle)) research$themes[[i]]$title <- themeTitle[[id]]
    research$themes[[i]]$short <-
      if (id %in% names(themeShort)) themeShort[[id]] else research$themes[[i]]$title
  }
  research
}

## a snapshot paper's "Le et al.", DOI link and figure file (NULL if none)
paperAuthor <- function(p) paste(sub(",.*$", "", p$first_author), "et al.")
paperDoi <- function(p) paste0("https://doi.org/", p$doi)
paperFigure <- function(p) if (!is.null(p$figure)) sprintf("research/figures/%s.png", p$figure)

## a value for a Pandoc attribute, e.g. fig-alt="..."
attrEscape <- function(x) gsub('(["\\\\])', "\\\\\\1", x)

## Markdown for a paper's picked figure (shown as is: it includes its printed
## caption), with its width and height so the page doesn't jump while it
## loads, and linked to the full-size image unless `link = FALSE` (e.g. inside
## a card that is itself a link). Every reproduced figure needs its credit
## line, paperCredit(), next to it.
paperFigureMd <- function(p, lazy = TRUE, link = TRUE) {
  src <- paperFigure(p)
  size <- pngSize(src)
  alt <- sprintf("%s from %s (%s): %s", sub(" reproduced.*$", "", p$credit),
                 paperAuthor(p), p$year, p$title)
  img <- sprintf('![](%s){fig-alt="%s" width="%d" height="%d"%s}',
                 src, attrEscape(alt), size[["width"]], size[["height"]],
                 if (lazy) ' loading="lazy"' else "")
  if (!link) return(img)
  sprintf('[%s](%s){.bml-figlink title="Open the full-size figure"}', img, src)
}

## "Figure 2 reproduced from Le et al. (2026), *Journal*."
paperCredit <- function(p) {
  sprintf("[%s, *%s*.]{.bml-credit}", mdEscape(p$credit), mdEscape(p$journal))
}
