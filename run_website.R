#### This is a control file ####

## this file creates the navigation menu and writes it out
## to the _site.yml file which controls how Rmarkdown renders the site
## it also calls render_site() after the yaml file is written

## load packages and setup
source("package_setup.R", echo=FALSE)

projects <- read_excel("~/OneDrive/WileyDossier/CV_Full.xlsx", sheet = "Projects")
projects <- as.data.table(projects)[nzchar(Summary) & !is.na(Summary)]
projects[, Type := factor(Type, levels = c("Trial", "Daily", "Other"))]
projects <- projects[order(Type, -Status, -Started)]

projects[, ProjectSummary := sprintf(
  "<h3 id=%s>%s | %d - %s |</h3> \n\n %s \n",
  Name, Name, Started, ifelse(Status == "Completed", as.character(Ended), "current"),
  Summary)]

nav.trials <- paste(projects[Primary == 1 & Type == "Trial", sprintf(
'        - text: "%s"
          href: projects.html#%s',
Name, Name)], collapse = "\n")
nav.daily <- paste(projects[Primary == 1 & Type == "Daily", sprintf(
'        - text: "%s"
          href: projects.html#%s',
Name, Name)], collapse = "\n")
nav.other <- paste(projects[Primary == 1 & Type == "Other", sprintf(
'        - text: "%s"
          href: projects.html#%s',
Name, Name)], collapse = "\n")

nav <- sprintf(
'
name: "Behavioural Medicine Lab Website"
exclude: ["*.*~"]
output_dir: "."
navbar:
  title: <span class="fa fa-home"></span> Home
  right:
    - icon: fa-cogs
      text: "Projects"
      href: projects.html
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
    - icon: fa-id-badge
      text: "Team"
      href: team.html
    - icon: fa-graduation-cap
      text: "Alumni"
      href: alumni.html
    - icon: fa-users
      text: "Consumers & Community"
      href: consumer_community.html
    - icon: fa-file-alt
      text: "Wiley CV"
      href: cv.html
    - icon: fa-heart
      text: "Ethics & Values"
      href: ethics_values.html
output:
  html_document:
    include:
      after_body: footer.html

',
nav.trials, nav.daily, nav.other)

cat(nav, file = "_site.yml")

rmarkdown::render_site()

