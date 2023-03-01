#### This is a control file ####

## this file creates the navigation menu and writes it out
## to the _site.yml file which controls how Rmarkdown renders the site
## it also calls render_site() after the yaml file is written

## load packages and setup
source("package_setup.R", echo = FALSE)

projects <- read_excel(file.path(basedir, "WileyDossier/CV_Full.xlsx"),
                       sheet = "Projects")
projects <- as.data.table(projects)[nzchar(Summary) & !is.na(Summary)]
projects[, Type := factor(Type, levels = c("Trial", "Daily", "Other"))]
projects <- projects[order(Type, -Status, -Started)]

projects[, ProjectSummary := sprintf(
  "<h3 id=%s>%s | %d - %s |</h3> \n\n %s \n",
  Name, Name, Started, ifelse(Status == "Completed", as.character(Ended), "current"),
  Summary)]

nav.trials <- paste(projects[Primary == 1 & Type == "Trial", sprintf(
'          - text: "%s"
            href: projects.qmd#%s',
Name, Name)], collapse = "\n")
nav.daily <- paste(projects[Primary == 1 & Type == "Daily", sprintf(
'          - text: "%s"
            href: projects.qmd#%s',
Name, Name)], collapse = "\n")
nav.other <- paste(projects[Primary == 1 & Type == "Other", sprintf(
'          - text: "%s"
            href: projects.qmd#%s',
Name, Name)], collapse = "\n")

nav <- sprintf(
'project:
  type: website
  output-dir: docs

website:
  title: "Behavioural Medicine Lab"
  search: false
  navbar:
    background: primary
    right:
      - text: "{{< fa cogs >}} Projects"
        menu:
          - text: "Clinical Trials"
%s
          - text: "---------"
          - text: "Daily Life Studies"
%s
          - text: "---------"
          - text: "Other Studies"
%s
          - text: "---------"
          - text: "Collaborations"
            href: projects.html#collaborations
      - text: "{{< fa id-badge >}} Team"
        href: team.qmd
      - text: "{{< fa graduation-cap >}} Alumni"
        href: alumni.qmd
      - text: "{{< fa users >}} Consumers & Community"
        href: consumer_community.qmd
      - text: "{{< fa file-alt >}} Wiley CV"
        href: cv.qmd
      - text: "{{< fa heart >}} Ethics & Values"
        href: ethics_values.qmd
  page-footer:
    center:
    - text: "Copyright &copy; 2019 - 2023 by Behavioural Medicine Lab based in Melbourne, Australia.  All rights reserved."

format:
  html:
    theme: flatly
    toc: true
',
nav.trials, nav.daily, nav.other)

cat(nav, file = "_quarto.yml")

quarto::quarto_render()

