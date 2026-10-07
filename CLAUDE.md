# CLAUDE.md — Behavioural Medicine Lab website

Quarto website for the lab (https://bml.science). This repo is **public** on GitHub
(`behavioralmedicinelab/behavioralmedicinelab.github.io`); GitHub Pages serves `docs/`.

## Source of truth: `~/wiley_cv` (read-only)

- All CV, people, project and grant data comes from `~/wiley_cv/CV_Full.xlsx`, read live at
  render time via `cvpath` in `package_setup.R`. `~/wiley_cv/CLAUDE.md` documents every sheet
  and column; read it before using a sheet.
- **Never edit anything in `~/wiley_cv`**, including its regeneration scripts and outputs.
  Treat it as read-only. If its data is wrong or missing, tell Joshua; he fixes it there.
- Citations and R-package downloads come from the workbook's `Citations` and `SoftwareStats`
  sheets, which `~/wiley_cv/metrics/` refreshes. The site never contacts Google Scholar or
  CRAN itself. When showing these numbers, state the source and as-of date.
- The citation-comparison and package-stats analysis scripts that used to be in this repo now
  live in `~/wiley_cv/metrics/`.
- The home page's research themes come from `~/wiley_cv/track_record/2026-10-lab-themes/`
  (its `README.md` is the handoff), but only through a frozen snapshot in this repo: see
  "Research themes snapshot" below.

## Building

- `Rscript run_website.R` from the repo root. It writes `_quarto.yml` from the template inside
  it (the Projects menu comes from the Projects sheet), then renders everything into `docs/`.
- `run_website.R` is the source of truth for `_quarto.yml`: make config changes in its
  template, never by hand in `_quarto.yml`. That includes the navbar, footer, theme list and
  title banner (see "Theme and page conventions").
- A single page renders with `quarto render <page>.qmd` (it uses the current `_quarto.yml`).
- Only root-level `*.qmd` files are rendered (`project.render`), so Markdown notes such as this
  file are never published.
- Commit `docs/` with `git add -A docs`: Quarto renames files in `docs/site_libs/` between
  versions, and a partial commit leaves the live site pointing at missing CSS/JS.

## Conventions

- Shared helpers live in `package_setup.R`: `projectAnchor()` (heading ids for projects),
  `readPeople()` (the People sheet without `Exclude` rows), `getCitations(source)` (Citations
  sheet, with as-of date), `getDownloads()` (SoftwareStats sheet), `currentPosition()`,
  `ciGrantTotalAUD()`, `belowRound()` for ">N" figures and `fmtNum()` for thousands separators.
  For pages whose R chunks write markdown: `mdEscape()` (plain text made safe for markdown),
  `attrEscape()` (a value for a `{key="..."}` attribute), `pngSize()`, `parseReference()`
  (author, year, title, journal and DOI from a Publications `Reference`), `latestPublications(n)`
  (the newest Empirical/Review/Protocol rows, parsed, with a label such as "New paper"),
  `labCounts()` (current members, completed doctoral theses, Honours graduates and the first
  completion year, from `readPeople()`), and the research-snapshot helpers `readResearch()`,
  `themeShort`, `paperAuthor()`, `paperDoi()`, `paperFigure()`, `paperFigureMd()` and
  `paperCredit()` (see "Research themes snapshot").
- Wherever citations appear (home page, CV chart), show both Google Scholar and Scopus.
- Funding (totals and the CV grants list) counts only grants where Joshua is a chief
  investigator (`ciRoles`: CIA, CI, CIC, CID), never AI, Supervisor or Trainee.
- Figures for funding, students and publications must never overclaim: always round down
  (e.g. $25.98M is ">$25 million"). Use `belowRound()` or exact counts, never `round()`.
- Headings that contain a `{{< fa ... >}}` shortcode need an explicit `{#id}`; otherwise Quarto
  generates a long hashed id and existing links break.
- Keep photos at full resolution. Don't downsize or recompress them, even when a page shows
  them smaller (Joshua's preference).
- `files/24hr_comp.html` and `files/emotion_dynamics.html` are standalone pages Joshua links to
  directly. They are deliberately not linked from the site (so not copied into `docs/`); leave
  them alone.

## Theme and page conventions ("Night and Day")

The look follows Claude Design's "Direction C - Night and Day" mockup (the brief is in
`Private/`, which is gitignored and never published): navy "night" bands (navbar, title
banners, heroes, the stats band, footer), a warm "day" page (#f5f3ee), white cards with
hairline borders, Libre Caslon Text for headings and display text, Manrope for everything
else (both from Google Fonts), teal accents (#3dd6b5 on navy, #0f7a68 on light).

- **All CSS lives in `styles/*.scss`**, Quarto SCSS theme layers listed under
  `format.html.theme` in `run_website.R`'s template:
  - `styles/bml.scss`: colour tokens (`$bml-night`, `$bml-day`, `$bml-ink`, `$bml-teal`,
    `$bml-teal-dark`, ...), Bootstrap/Quarto variables, typography, navbar, footer, title
    banner, and the shared class vocabulary. **The class list, with what each is for, is the
    comment block at the top of this file**; read it before styling a page.
  - `styles/bml-research.scss`: the research page (`research.qmd`): intro and theme index,
    theme sections, flat featured-study plates, the "More from this theme" rail, text
    cards, the navy "How we work" band; also the figure link (`.bml-figlink`) the home plate
    uses. Its class list is the comment at its top. It also lines the page's title banner
    up with its bands' 1168px column (`body-classes: bml-page-research`).
  - `styles/bml-home.scss`: the home page (`index.qmd`, `body-classes: bml-home`): hero and
    plate sizes, doors, theme cards, the track-record band, latest papers, team teaser, bio and
    Connect card, plus a few small helpers (`.bml-links`, `.bml-above`, `.bml-phone-extra`,
    `.bml-phone-only`) listed at its top.
  - `styles/bml-team.scss`: the team page (`team.qmd`, `body-classes: bml-team`): hero and
    photo plate, the members band (heading and filter pills on one line), member and lab head
    cards, alumni rows, the closing "Want to join us?" band. Class list at its top.
  - A redesigned page's own rules go in its file (or a new `styles/bml-<page>.scss` added to
    the theme list), using the tokens from `bml.scss`. Each file needs both
    `/*-- scss:defaults --*/` and `/*-- scss:rules --*/` markers.
- **No CSS in pages.** No `<style>` blocks and no `style="..."` attributes in `.qmd` files or
  in the markdown/HTML their R chunks emit. Use classes.
- **Markdown first.** Build pages from Pandoc/Quarto markdown: fenced divs
  (`::: {.bml-card}`), bracketed spans (`[Future students]{.bml-eyebrow}`), links and images
  with attributes (`[Read the paper](https://doi.org/...){.bml-btn}`,
  `![](x.png){fig-alt="..."}`), Quarto's CSS grid (`::: {.grid}` with
  `::: {.g-col-12 .g-col-md-4}`), `.column-screen` / `.column-page`, tabsets
  (`::: {.panel-tabset .bml-tabs}` draws them as pills), callouts. R chunks with
  `#| output: asis` `cat()` markdown, not HTML. Raw HTML only where markdown cannot express
  something (e.g. the map `<iframe>` on `consumer_community.qmd`), kept tiny, with a comment
  saying why. Bootstrap's `.stretched-link` on a card's main link makes the whole card
  clickable (a second link stays clickable with `.bml-above`). Pandoc wraps a heading and
  everything after it, up to the end of the enclosing div, in a `<section>`; so in a flex or
  grid layout put a heading (with its eyebrow) in its own small div, e.g.
  `::: {.bml-section-title}`. When an eyebrow sits above a heading, put the anchor id on the
  enclosing div (`::: {#stress .column-screen .bml-band}`) so a jump shows the eyebrow too. A
  tabset's classes are copied onto its `.tab-content` too, and Quarto puts an empty
  `.tabset-margin-container` div just before it, so select `.panel-tabset.<class>` and
  mind that extra sibling in grid layouts. Inline R (`` `r counts$current` ``) works inside
  spans and divs.
- **Navbar** (template): logo `images/bml-mark.svg` (teal ring and dot; also the favicon) +
  "Behavioural Medicine Lab"; Research, Projects (menu generated from the Projects sheet),
  Team, Community, Values, and "Take part" (text `[Take part]{.bml-nav-cta}`, drawn as an
  outlined teal pill) linking to `consumer_community.qmd#take-part`. The CV is linked from the
  footer, not the navbar. Quarto marks the current page; the Projects menu needs
  `body-classes: bml-page-projects` in `projects.qmd`. The hamburger sits on the right
  (`toggle-position: right`).
- **Footer** (template `page-footer`, laid out by the footer rules in `bml.scss`):
  Acknowledgement of Country ("We acknowledge and pay respects to the Elders and Traditional
  Owners of the land on which we work."; Monash University's footer wording, adapted by Joshua
  to end "on which we work"; keep it word for word), then Explore / Get involved /
  Contact columns, then "Behavioural Medicine Lab &middot; School of Psychological Sciences"
  and "&copy; 2019&ndash;<year>" (year computed in `run_website.R`). Its markdown is Pandoc's,
  so fenced divs and spans work there.
- **Title banners**: `title-block-banner: true` site-wide gives every page with a `title:` a
  navy banner with a large serif title.
- **Hero pages** (home, and any page that needs computed content at the top): drop `title:`
  for `pagetitle:` (with a title Quarto draws the banner, and it promotes a level-1 `#`
  heading into the banner), and open the page with
  `::: {.column-screen .bml-band .bml-night .bml-hero}` (or `.bml-straddle` for a plate
  across the night/day line). Mark the headline as the page heading with
  `::: {.bml-display role="heading" aria-level="1"}`. A page that ends with a `.bml-band`
  meets the footer with no gap.
- **Stable anchors**: `consumer_community.qmd`'s "About Involvement in Research" heading is
  `{#take-part}` (navbar and footer link to it); the footer's "Study with us" links to
  `team.qmd#join`; keep the CV section ids, project anchors, `#connect` and the research
  theme ids.
- **Accessibility**: text contrast at least 4.5:1 (the tokens are chosen for this; muted
  grey `#5a6570` is the lightest text on day, `#8d9ba7` on night), visible focus outlines
  (teal on navy, dark teal on light), alt text on every image (`fig-alt`), and the phone menu
  must keep working. No page may scroll sideways on a phone (the menu button sits on the
  right and would be pushed off screen): `bml.scss` lets long URLs and DOIs in paragraphs and
  list items wrap, and big numbers shrink on narrow screens; check `scrollWidth` at 320px too.
  The navbar is tightened between 992px and 1199px so it fits on one line. A navy card on the
  day page gets a dark-teal focus ring (the ring is drawn on day). Link text in an
  `aria-label` must start with the visible text (WCAG 2.5.3). Check pages at 1440px and 390px
  wide with headless Chrome (its minimum window is 500px, so load phone views in a 390px
  iframe).

## Home, Research and Team pages

- **Home (`index.qmd`)**, top to bottom: navy hero (`.bml-straddle .bml-hero`) with the serif
  headline and the featured "plate" (one theme exemplar: figure and credit, the theme's short name as
  the eyebrow, plain-language finding, citation, "Read the paper"; `heroId` picks the
  theme, else the first with a figure) across the night/day line; "Where would you like to
  start?" (three door cards: Take part, Study with us, Research/Publications/Software; the
  thesis and Honours counts come from `labCounts()`, the student-led line from the
  Publications sheet's `FirstLast`/`StudentFirst`); "Our Research" (`#found`; a card per theme, the
  plate's theme first: figure and credit, "INSOMNIA & FATIGUE" eyebrow (no numbers), finding,
  the citation "Surname et al. (Year)" and "Read more", which makes the whole card a
  link to the exemplar paper's DOI; each card keeps its theme's id; phones show three, then "All five
  themes"); the navy "How we work" band (R package chips and the lab head's track record,
  every figure rounded down, with the as-of note); "Latest from the lab" (`latestPublications(4)`: the newest Empirical/Review/Protocol rows where Joshua is first or last author or the first author is one of his primary supervisees, matched by `primaryFirstAuthor()`;
  each card linked to its DOI; a reference that can't be parsed is shown whole); the team
  teaser (2024 photo, member count from `labCounts()`); then Joshua's short bio (no numbers: the stats band
  above has them) (`#joshua-f.-wiley`, the live site's old auto id; keep it) with the Connect card (`#connect`).
- **Research (`research.qmd`)**: title banner, then the intro and a theme index (no numbers); a
  section per theme with id `#stress`, `#sleep`, `#insomnia`, `#timeuse`, `#psyonc` (the theme
  anchors): short-name eyebrow, title and blurb, the featured study as a flat plate, then
  "More from this theme" cards; then the navy "How we work" band (methods, R packages, CRAN
  downloads from `getDownloads()`). It reads only the research snapshot (below).
- **Team (`team.qmd`)**, a hero page (no title; `aliases: alumni.html` keeps the old URL):
  navy hero (`.bml-straddle .bml-hero .bml-team-hero`) with "Meet the lab" and three counts
  from `labCounts()` (current members, completed PhD/DPsych theses, Honours graduates; inline
  R in the markdown), then the group photos as a tabset of years
  (`::: {.panel-tabset ... .bml-photos}`, one captioned image per tab, newest first; the
  photos are cropped to a fixed box by CSS only, never resized; tabs after the first load
  lazily); "Current members" (`#current-members`), a tabset of roles drawn as pills (All,
  then only the groups that have someone: Postdocs, Staff, Doctoral, Masters, Honours,
  Visitors), each tab a grid with the navy lab head card first (`JWiley_square.jpg`, position
  from `currentPosition()` plus the current honorary roles from the Positions sheet; the whole
  card links to the CV page, `cv.qmd`) then a card per member (initials, name with a teal `*` when
  `Primary == 1`, role, "Joined <year>"), and the "* Joshua Wiley is primary supervisor."
  note; "Alumni" (`#alumni`): one row per completion year, newest first (name, role, and
  "thesis ↗" to `ThesisLink` when it is a URL; no stars), completed rows without an `Ended`
  year in a final "Other" row (and a render-log note); the navy "Want to join us?" band
  (`#join`) with an "Ask about opportunities" pill (`mailto:`) before the footer. All of it is
  markdown the R chunks `cat()`; names go through `mdEscape()`.

## Research themes snapshot

- `research.qmd` and the home page's plate and theme cards read the themes through
  `readResearch()`, which adds each theme's number ("01", in snapshot order) and short label
  (`themeShort` in `package_setup.R`, e.g. "Insomnia & fatigue"; a new theme without one
  uses its title).
- The themes come from a **frozen snapshot**: the pages read only `research/research.json`
  and `research/figures/`, never `~/wiley_cv/track_record/2026-10-lab-themes/`. Changes there
  reach the site only when the snapshot is refreshed.
- `Rscript sync_research.R` (from the repo root) refreshes it. **Run it only when Joshua asks.**
  `run_website.R` and the pages never call it. It reads `themes.json`, `site_copy.json`,
  `hero_picks.json`, `profiles/` and `figures/candidates/` there (read-only) and writes:
  - `research/research.json`: only what the pages show (intro; theme titles, blurbs and counts;
    exemplar and representative papers with title, year, journal, DOI, first author, trainee
    flag, design label, card text, figure ID and credit; methods; software; generated date and
    source path). Internal fields (theme descriptions, member lists, `not_featured`, other
    profile fields) stay out, because this repo is public. Journal subtitles are trimmed
    ("Health Psychology: Official Journal of ..." becomes "Health Psychology").
  - `research/figures/<figure ID>.png`: the picked figures, copied byte for byte (never resize
    or recompress them). Figures no longer picked are deleted.
  Then rebuild with `run_website.R` and check the pages.
- Don't edit `research/` by hand or change which papers are featured; those choices are
  Joshua's, made in the wiley_cv analysis.
- The figures reach `docs/` through `resources:` in `research.qmd`'s front matter (the home
  page's images are found by Quarto as well). `research.json` is only read at render time and
  is not published.
- Styles are in `styles/bml-research.scss` (research page) and `styles/bml-home.scss` (home).
  Themes are told apart by number ("03 INSOMNIA & FATIGUE"), not by colour.
- Every reproduced figure has a credit line: "Figure N reproduced from Surname et al. (Year),
  *Journal*." Papers whose pick is `null` get a text card instead: a representative's shows
  its profile `summary` (plain-language finding), and an exemplar's shows its profile
  `key_finding`, because its summary is already the featured card's headline (as in the
  mockup). A trial protocol's text card is labelled "Study plan", any other "Key finding".

## People and privacy

- The Team page (`team.qmd`) names everyone in the People sheet, with role and year joined
  (current) or year completed (alumni) only, plus a "thesis ↗" link on alumni whose
  `ThesisLink` holds a URL (left out when the column or value is missing). `Consent` covers bios only, which are no longer published, so it does
  not restrict names.
- Always read People through `readPeople()`. Rows with `Exclude == 1` are kept in the workbook
  as records only. They must not be listed anywhere on the site or counted in any total (team
  page, CV student lists, supervision counts).
- `Status == "Withdrew"` rows are hidden per role, not per person: the same person's
  completed roles still appear.
- Never publish `Bio` or the internal People columns (Gender, International, Scholarship,
  Outcome, Notes, Consent). The CV's student lists use initials only.
- No per-paper tags anywhere (study design, "Trainee-led", "Led by a lab trainee"): Joshua
  removed them on 2026-10-07. Themes are never numbered ("01", "Plate 03").
- Theme display order and title overrides live in `themeOrder` / `themeTitle` in
  `package_setup.R` (Insomnia, Psychosocial cancer care, Sleep, Stress, 24-hour time use).
  Never show per-theme or per-method paper counts, years active or "since <year>" counts:
  Joshua keeps those private because they go stale.
