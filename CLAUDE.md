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
  `labCounts()` (current members (people, not roles), completed doctoral theses, Honours
  graduates and the first completion year, from `readPeople()`), and the research-snapshot helpers `readResearch()`,
  `themeShort`, `paperAuthor()`, `paperDoi()`, `paperFigure()`, `paperFigureMd()` and
  `paperCredit()` (see "Research themes snapshot").
- Email: buttons and links say "Email us" (not "Email Josh"; Joshua's choice, 2026-10-09).
  `labEmail` in `package_setup.R` is the one copy of the contact address. Build every
  email link from it with `mailtoUrl(subject)` (e.g. `mailtoUrl("Honours enquiry")` opens an
  email titled "[BML] Honours enquiry"; no subject for general contact), in pages and in the
  footer. The address is shown as a plain link (no "_at_ _dot_").
- Joshua's name and title (his choice, 2026-10-09): "Dr Joshua Wiley" / "Dr Wiley" in general
  mentions ("led by Dr Joshua Wiley"); in official bios and wherever the text states his role
  or title, the official title from `currentPosition()` (e.g. the home bio opens "Associate
  Professor Joshua Wiley leads...", the Team lab head card is "Joshua F. Wiley" with the
  position line under it). Never "Dr" next to a stated position, and never "Dr." with a full
  stop.
- Wherever citations appear (home page, CV chart), show both Google Scholar and Scopus.
- Funding (totals and the CV grants list) counts only grants where Joshua is a chief
  investigator (`ciRoles`: CIA, CI, CIC, CID), never AI, Supervisor or Trainee.
- Figures for funding, students and publications must never overclaim: always round down
  (e.g. $25.98M is ">$25 million"). Use `belowRound()` or exact counts, never `round()`.
- Headings that contain a `{{< fa ... >}}` shortcode need an explicit `{#id}`; otherwise Quarto
  generates a long hashed id and existing links break.
- Keep photos at full resolution. Don't downsize or recompress them, even when a page shows
  them smaller (Joshua's preference). The group photos live in `images/`
  (`images/BML_Group_<year>.jpg`); `JWiley_square.jpg` is in the repo root. Photos below the
  fold get `loading="lazy"`.
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
  - `styles/bml-join.scss`: the Get involved page (`join.qmd`, `body-classes: bml-page-join`):
    hero and audience cards, the audience sections, status pills, the support box, the
    programs table. Class list at its top.
  - `styles/bml-projects.scss`: the Projects page (`projects.qmd`, `body-classes:
    bml-page-projects`, which also lights up the Projects menu): intro band and jump chips, a
    day band per group, a card per project. Class list at its top.
  - `styles/bml-values.scss`: the Values page (`ethics_values.qmd`, `body-classes:
    bml-page-values`): intro and "On this page" index, a day band per value, the research
    ideals card, the navy invitation card, the Support cards. Class list at its top.
  - `styles/bml-cv.scss`: the CV page (`cv.qmd`, `body-classes: bml-page-cv`), kept as a
    document: portrait and Academic summary, entries with dates in a left column, numbered
    reference lists, the chart tabsets, the "On this page" chips shown below 992px (the TOC
    shows from 992px). Class list at its top.
  - Projects, Research, Values and CV keep a title banner, lined up with the bands' 1168px
    column by a `body.bml-page-<page>` rule in their stylesheet.
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
  something (e.g. the `<wbr>` in the footer's email link, from `run_website.R`; the small
  script in `projects.qmd` that closes the phone menu before jumping to a project on the same
  page; the CV's count-down `<ol>` lists), kept tiny, with a comment saying why. Bootstrap's `.stretched-link` on a card's main link makes the whole card
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
  "Behavioural Medicine Lab"; Research, Projects (menu generated from the Projects sheet, its
  group labels "Trials", "Observational studies", "Daily life studies", "Other studies",
  "Projects we collaborate on" matching the Projects page headings), Team, Values, and "Get involved" (text `[Get involved]{.bml-nav-cta}`, drawn as an
  outlined teal pill, filled on its own page) linking to `join.qmd`. The CV is linked from the
  footer, not the navbar. Quarto marks the current page; the Projects menu needs
  `body-classes: bml-page-projects` in `projects.qmd`. The hamburger sits on the right
  (`toggle-position: right`).
- **Footer** (template `page-footer`, laid out by the footer rules in `bml.scss`):
  Acknowledgement of Country ("We acknowledge and pay respects to the Elders and Traditional
  Owners of the land on which we work."; Monash University's footer wording, adapted by Joshua
  to end "on which we work"; keep it word for word), then Explore / Get involved /
  Contact columns (Get involved links each section of `join.qmd`; Contact is the
  `labEmail` link), then "Behavioural Medicine Lab &middot; School of Psychological Sciences"
  and "&copy; 2019&ndash;<year>" (year computed in `run_website.R`). Its markdown is Pandoc's,
  so fenced divs and spans work there.
- **Title banners**: `title-block-banner: true` site-wide gives every page with a `title:` a
  navy banner with a large serif title.
- **Descriptions and link previews**: `site-url` and `open-graph: true` (template) give every
  page Open Graph tags. Every page sets the same one-sentence description (at most about 155
  characters) twice in its front matter: `description-meta: "..."` (the search-result
  `<meta name="description">`) and `open-graph:` / `description: "..."` (link previews).
  Don't use `description:`: on a title-banner page Quarto prints it under the title, and
  `hide-description` doesn't stop it. `image:` and `image-alt:` set the preview image (Team
  and Get involved use the 2024 group photo).
- **Back to top** (template `back-to-top-navigation: true`): Quarto's "Back to top" link,
  styled as a navy pill in `bml.scss`, appears when a long page is scrolled back up.
- **404 page** (`404.qmd`): GitHub Pages serves `docs/404.html` for any unknown address,
  nested ones included; Quarto writes its links and assets from the site root (it knows the
  root from `site-url`) and leaves it out of the sitemap. Give it no aliases.
- **Hero pages** (home, and any page that needs computed content at the top): drop `title:`
  for `pagetitle:` (with a title Quarto draws the banner, and it promotes a level-1 `#`
  heading into the banner), and open the page with
  `::: {.column-screen .bml-band .bml-night .bml-hero}` (or `.bml-straddle` for a plate
  across the night/day line). Mark the headline as the page heading with
  `::: {.bml-display role="heading" aria-level="1"}`. A page that ends with a `.bml-band`
  meets the footer with no gap, so **no page ends on a navy band** (it would run into the navy
  footer): a closing navy panel is a `.bml-card .bml-night` inside a day band (Team's "Want to
  join us?", Research's "How we work").
- **Stable anchors**: `join.qmd`'s sections `#participate`, `#partner`, `#study`,
  `#collaborate`, `#work` and its program rows `#honours`, `#mcp`, `#phd`
  (navbar, footer, home doors, flyers and emails link to them). Old addresses keep working:
  `consumer_community.html` redirects to the top of `join.html` (`aliases:` in `join.qmd`;
  Quarto's redirects can't add an anchor), and its old `#take-part` anchor is the id of the
  `#partner` heading row; `team.qmd#join` is still the Team
  page's closing band. Keep the CV section ids (e.g. `#publications`, `#software`, `#grants`),
  the project anchors (`projectAnchor(Name)`) and the Projects group ids (`#trials`,
  `#observational-studies`, `#daily-life-studies`, `#other-studies`, `#collaborations`), the
  Values ids (`#ethics`, `#diversity-and-inclusion`, `#support`), `#connect` and the research
  theme ids.
- **Accessibility**: text contrast at least 4.5:1 (the tokens are chosen for this; muted
  grey `#5a6570` is the lightest text on day, `#8d9ba7` on night), visible focus outlines
  (teal on navy, dark teal on light), alt text on every image (`fig-alt`), and the phone menu
  must keep working. No page may scroll sideways on a phone (the menu button sits on the
  right and would be pushed off screen): `bml.scss` lets long URLs and DOIs in paragraphs and
  list items wrap, and big numbers shrink on narrow screens; check `scrollWidth` at 320px too.
  The navbar is tightened between 992px and 1199px so it fits on one line, and below 400px
  the lab name shrinks so it is never clipped. Below 768px a Quarto grid's column gap is
  capped (`bml.scss`), because its 11 gaps would otherwise be wider than a 320px screen.
  The phone menu button shows its focus ring for keyboard focus only (Chrome focuses it on a
  tap). A navy card on the
  day page gets a dark-teal focus ring (the ring is drawn on day). Link text in an
  `aria-label` must start with the visible text (WCAG 2.5.3). Put a non-breaking space
  (`\ `) before a link's arrow (`[Read more\ [→]{aria-hidden="true"}](...)`) so the arrow
  never wraps alone. Check pages at 1440, 768, 390 and 320px in both Google Chrome and
  WebKit (Safari's engine): Playwright with `chromium.launch({channel: 'chrome'})` and
  `webkit.launch()` sets any viewport width. Safari only tabs to links with Option+Tab, and
  Chrome only balances headings of six lines or fewer.

## Pages

- **Home (`index.qmd`)**, top to bottom: navy hero (`.bml-straddle .bml-hero`) with the serif
  headline and the featured "plate" (one theme exemplar: figure and credit, the theme's short name as
  the eyebrow, plain-language finding, citation, "Read the paper"; `heroId` picks the
  theme, else the first with a figure) across the night/day line; "Where would you like to
  start?" (heading row with "All the ways to get involved" to `join.qmd`, then three door
  cards: people affected by cancer (Take part in a study `join.qmd#participate`, Share your
  experience `#partner`), Study with us (`#study`), Research/Publications/Software/Collaborate
  (`#collaborate`); the thesis and Honours counts come from `labCounts()`, the student-led
  line from the Publications sheet's `FirstLast`/`StudentFirst`); "Our research" (`#found`; a card per theme, the
  plate's theme first: figure and credit, "INSOMNIA & FATIGUE" eyebrow (no numbers), finding,
  the citation "Surname et al. (Year)" and "Read more", which makes the whole card a
  link to the exemplar paper's DOI; each card keeps its theme's id; phones show three, then "All five
  themes"); the navy "How we work" band (R package chips and the lab head's track record,
  every figure rounded down, with the as-of note); "Latest from the lab" (`latestPublications(4)`: the newest Empirical/Review/Protocol rows where Joshua is first or last author or the first author is one of his primary supervisees, matched by `primaryFirstAuthor()`;
  each card linked to its DOI; a reference that can't be parsed is shown whole); the team
  teaser (2024 photo, lazy-loaded; member count from `labCounts()`); then Joshua's short bio,
  which opens with his official title (no numbers: the stats band above has them;
  `#joshua-f.-wiley`, the live site's old auto id; keep it; portrait lazy-loaded) with the
  Connect card (`#connect`). Below 375px the hero headline is a little smaller so Chrome can
  balance it.
- **Research (`research.qmd`)**: title banner, then the intro and a theme index (no numbers); a
  section per theme with id `#stress`, `#sleep`, `#insomnia`, `#timeuse`, `#psyonc` (the theme
  anchors): short-name eyebrow, title and blurb, the featured study as a flat plate, then
  "More from this theme" cards (a card with a figure shows its credit line instead of a
  separate citation); then "How we work" (`#how-we-work`), a navy card on the day background
  (methods, R packages, download counts from `getDownloads()`, which come from the Posit
  CRAN mirror; don't claim the packages are on CRAN). The intro links "School of
  Psychological Sciences" and "Turner Institute for Brain and Mental Health". It reads only
  the research snapshot (below).
- **Team (`team.qmd`)**, a hero page (no title; `aliases: alumni.html` keeps the old URL):
  navy hero (`.bml-straddle .bml-hero .bml-team-hero`) with "Meet the lab" and three counts
  from `labCounts()` (current members, completed PhD/DPsych theses, Honours graduates; inline
  R in the markdown), then the group photos as a tabset of years
  (`::: {.panel-tabset ... .bml-photos}`, one captioned image per tab, newest first; the
  photos are cropped to a fixed box by CSS only, never resized; tabs after the first load
  lazily); "Current members" (`#current-members`), a tabset of roles drawn as pills (All,
  then only the groups that have someone: Postdocs, Staff, Doctoral, Masters, Honours,
  Visitors), each tab a grid with the navy lab head card first (`JWiley_square.jpg`, name
  "Joshua F. Wiley" with the position from `currentPosition()` plus the current honorary roles
  from the Positions sheet; the whole card links to the CV page, `cv.qmd`) then a card per member (initials, name with a teal `*` when
  `Primary == 1`, role, "Joined <year>"), and the "* Dr Wiley is the primary supervisor."
  note; "Alumni" (`#alumni`): one row per completion year, newest first (name, role, and
  "thesis ↗" to `ThesisLink` on doctoral rows only, so the links match the thesis tally;
  "N people" counts distinct names, so someone who finished two roles that year is listed
  twice but counted once), completed rows without an `Ended` year in a final "Other" row (and
  a render-log note); "Want to join us?" (`#join`), a navy card on the day background with a
  "Study with us" pill to `join.qmd#study` and a line ("Before you get in touch, ...")
  pointing to the research, values and Get involved pages, before the footer. All of it is
  markdown the R chunks `cat()`; names go through `mdEscape()`.
- **Get involved (`join.qmd`)**, a hero page (no title; `aliases: consumer_community.html`,
  the old Consumers & Community page, whose content now lives in `#partner`), at
  bml.science/join: navy hero (`.bml-straddle .bml-hero .bml-ways-hero`) with "Get involved"
  (no intro line) and five audience cards, which are also the jump list, with no eyebrows:
  Take part in a study ("Be a participant in our research."), Share your lived experience,
  Study with us, Collaborate, Work with us ("Not recruiting right now." as its text, no line
  under it); each a stretched link to its section, the others with a status line from the
  data (a study's `teaser`, e.g. "SleepSteps, an intervention for people with cancer, opens in
  2027. Check back soon."). The lived-experience card reads "We are looking for people with
  lived experience of cancer, including family members and carers, who want to help shape our
  research." Then one day band per audience (`.bml-path`), each with title and
  intro (no eyebrows), in that order: `#participate` (open studies; "In Australia and need
  support now?" box with Cancer Council and Lifeline; link to past results on
  `projects.qmd`), `#partner` (open partner roles, which point to the section's "Email us"
  button rather than having their own; what partners do and get; community organisations;
  Australian resources), `#study` (supervision, project themes, then a line that the School
  allocates supervisors for some programs and the programs table, with no heading: one row per
  program (`#honours`, `#mcp`, `#phd`; the PhD row covers research and clinical PhDs) with
  Length, More information (Monash's pages) and an "Email us" button ("[BML] Honours EoI",
  "Clinical masters EoI", "PhD EoI"); PhD scholarships (international vs domestic); what
  to send (PhDs: English test results too); the "Everyone is welcome" card. No dates and no
  "Last checked" line: Joshua chose to link to Monash for dates), `#collaborate` (areas,
  Community of Practice "launching soon" with a "[BML] CoP launch" email, visiting
  researchers), and `#work` (open jobs or "We're not recruiting right now.", fellowship
  hosting). Every section stays when nothing is open: it shows a fallback line instead.
- **`data/join.yml`** holds everything on that page that goes out of date: studies (status
  `recruiting` / `opening-soon` / `closed`; `teaser` for the hero card; participant details,
  ethics and trial registration appear only once filled in, and must match the HREC-approved
  wording; `signup` empty means "Check back soon" with no contact capture), partner roles,
  student project themes, programs (length, Monash `links`, email `subject`; no dates), and paid roles (each leaves the page after its closing date). Joshua
  edits it; the page reads it at render time and it is not published (but the repo is
  public). Its text fields are Markdown. A role's closing date is compared with the render
  date, so rebuild when one passes. An entry missing a field the page needs stops the build
  with a message naming it.
- **Projects (`projects.qmd`)**: title banner; an intro band (one line, "Take part in a study"
  link, jump chips); then a day band per group, in this order and with these ids: Trials
  (`#trials`), Observational studies (`#observational-studies`), Daily life studies
  (`#daily-life-studies`), Other studies (`#other-studies`), Projects we collaborate on
  (`#collaborations`, `Primary == 0`, always shown because the menu links to it). A card per
  project: the name as an h3 with `projectAnchor(Name)`, a status pill in words (Current /
  Completed) and the years ("2020–2022", "2018", "2020–present"; never "NA": a completed
  project without `Ended` shows its start year, with a render-log note), then the workbook
  Summary as written. Current projects first, then the most recently started. **Retired
  links**: `retiredUrls` in `projects.qmd` lists study websites that are down (CanCope,
  SleepCare, the REPAT page); their "Find out more at the study website" lines are dropped
  and other links to them shown as plain text at render time. Add an address there when a
  study site goes down, and tell Joshua so the workbook Summary can be cleaned up too.
- **Values (`ethics_values.qmd`)**: title banner ("Our ethics and values"); an intro band (opening statement and an
  "On this page" index); then a day band per value: Ethics (`#ethics`, with the research
  ideals card), Diversity and inclusion (`#diversity-and-inclusion`, with a navy invitation
  card and the email link) and Support (`#support`). All its text is written in this repo.
- **CV (`cv.qmd`)**: title banner; portrait beside the Academic summary; sections with
  serif sentence-case headings (ids unchanged); entries with dates in a left column. Every
  DOI is a link (`linkDois()`), and a legend explains the trainee asterisk wherever stars
  appear. Grants never show "NA"/"N/A" numbers, show one year when start equals end, and
  grants that haven't started go in an "Awarded, starting <year>" group. `cranArchived`
  lists packages no longer on CRAN (currently varian), which aren't linked to CRAN. The
  charts are plotly charts in pill tabsets, with a collapsed table of their numbers. The
  orphan chart outputs and the two links to missing project anchors are left as they are
  until Joshua decides.
- **404 (`404.qmd`, `body-classes: bml-page-404`)**: "Page not found" banner lined up with
  the 1168px column, then a day band with a line of text, four door-style cards (Home,
  Research, Team, Get involved) and the contact email (subject "[BML] Page not found").

## Research themes snapshot

- `research.qmd` and the home page's plate and theme cards read the themes through
  `readResearch()`, which adds each theme's number ("01", in snapshot order; internal only,
  never shown) and short label
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
  Themes are told apart by their short name ("INSOMNIA & FATIGUE"), never by number or colour.
- Every reproduced figure has a credit line: "Figure N reproduced from Surname et al. (Year),
  *Journal*." Papers whose pick is `null` get a text card instead: a representative's shows
  its profile `summary` (plain-language finding), and an exemplar's shows its profile
  `key_finding`, because its summary is already the featured card's headline (as in the
  mockup). A trial protocol's text card is labelled "Study plan", any other "Key finding".

## People and privacy

- The Team page (`team.qmd`) names everyone in the People sheet, with role and year joined
  (current) or year completed (alumni) only, plus a "thesis ↗" link on doctoral alumni whose
  `ThesisLink` holds a URL (left out when the column or value is missing, and on visiting or
  other non-doctoral roles). `Consent` covers bios only, which are no longer published, so it does
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
