#### Mirror the live site to joshuawiley.com ####

## joshuawiley.com is a copy of bml.science. It is served by GitHub Pages from
## docs/ on the master branch of JWiley/jwiley.github.io (cloned next to this
## repo). This script makes that copy match what bml.science serves now, i.e.
## docs/ on origin/main of this repo (not the local build), then commits and
## pushes it.
##
## Run from the repo root, after pushing a new build of this site:
##   Rscript sync_personal.R             sync, commit and push
##   Rscript sync_personal.R --no-push   sync and commit, but don't push
##   Rscript sync_personal.R --dry-run   only list what would change
##
## The copy is exact except for:
##   docs/CNAME       joshuawiley.com instead of bml.science (the CNAME at
##                    that repo's root is unused: Pages serves docs/)
##   personalExtras   standalone pages Joshua links to at joshuawiley.com;
##                    their source is files/ in this repo, and they are
##                    deliberately not in this site's docs/
## Everything else in that repo's docs/ is replaced, and files that are not
## on bml.science are deleted, so make changes here, never in that repo.
## That repo also lends its domain to Joshua's other GitHub Pages sites (R
## packages such as joshuawiley.com/brmsmargins/, teaching sites), so keep it,
## with Pages on and docs/CNAME set, even if the mirror is ever retired.

personalRepo <- Sys.getenv("PERSONAL_SITE_REPO")
if (!nzchar(personalRepo)) personalRepo <- "../jwiley.github.io"
personalRepo <- path.expand(personalRepo)
personalRemote <- "JWiley/jwiley.github.io"
personalBranch <- "master"
personalDomain <- "joshuawiley.com"
personalExtras <- c("files/24hr_comp.html", "files/emotion_dynamics.html")
## refs in full, so a local branch called origin/main can't stand in for them
labRef <- "refs/remotes/origin/main"
personalRef <- paste0("refs/remotes/origin/", personalBranch)

args <- commandArgs(trailingOnly = TRUE)
unknown <- setdiff(args, c("--dry-run", "--no-push"))
if (length(unknown)) stop("Unknown option: ", paste(unknown, collapse = " "))
dryRun <- "--dry-run" %in% args
push <- !"--no-push" %in% args

if (!file.exists("index.qmd") || !file.exists("run_website.R")) {
  stop("Run sync_personal.R from the website repo root.")
}

## run git in a repo and return its output (stdout only); stop with git's
## message if it fails
git <- function(repo, ...) {
  errFile <- tempfile()
  on.exit(unlink(errFile))
  out <- suppressWarnings(system2(
    "git", c("-C", shQuote(repo), "-c", "core.quotePath=false", ...),
    stdout = TRUE, stderr = errFile))
  status <- attr(out, "status")
  if (!is.null(status) && status != 0) {
    stop("git ", paste(c(...), collapse = " "), " failed in ", repo, ":\n",
         paste(c(out, readLines(errFile, warn = FALSE)), collapse = "\n"), call. = FALSE)
  }
  invisible(out)
}

## files under a directory, as relative paths (Finder's .DS_Store left out)
treeFiles <- function(dir) {
  if (!dir.exists(dir)) return(character())
  files <- list.files(dir, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  files[basename(files) != ".DS_Store"]
}

## TRUE where the file is the same in both folders (FALSE if missing from either)
sameFiles <- function(dirA, dirB, files) {
  same <- unname(tools::md5sum(file.path(dirA, files))) ==
    unname(tools::md5sum(file.path(dirB, files)))
  !is.na(same) & same
}

#### The personal repo: the right one, on master, nothing uncommitted ####

if (!dir.exists(file.path(personalRepo, ".git"))) {
  stop("Can't find the joshuawiley.com repo at ", personalRepo,
       " (set PERSONAL_SITE_REPO to its path).")
}
remote <- git(personalRepo, "remote", "get-url", "origin")
remotePattern <- paste0("(^|[:/])", gsub(".", "\\.", personalRemote, fixed = TRUE),
                        "(\\.git)?/?$")
if (!grepl(remotePattern, remote, ignore.case = TRUE)) {
  stop(personalRepo, " is not a clone of ", personalRemote, " (origin is ", remote, ").")
}
## how to undo an interrupted sync (quoted, so it pastes into a shell)
undoCmd <- sprintf("git -C %1$s reset -q --hard && git -C %1$s clean -fdq -- docs",
                   shQuote(personalRepo))
branch <- git(personalRepo, "branch", "--show-current")
if (!length(branch) || branch != personalBranch) {
  stop(personalRepo, " is ",
       if (length(branch) && nzchar(branch)) paste("on branch", branch) else "not on a branch",
       "; run git checkout ", personalBranch, " there first.")
}
dirty <- git(personalRepo, "status", "--porcelain", "--untracked-files=all")
dirty <- dirty[!grepl("^\\?\\? (.*/)?\\.DS_Store\"?$", dirty)]
if (length(dirty)) {
  stop(personalRepo, " has uncommitted changes; commit or discard them first. ",
       "If they are from an interrupted sync, undo them with\n  ", undoCmd, "\n",
       paste(c(head(dirty, 20), if (length(dirty) > 20) "..."), collapse = "\n"))
}

#### What bml.science serves: docs/ on origin/main ####

git(".", "fetch", "--quiet", "origin", "main")
labSha <- git(".", "rev-parse", "--short", labRef)
if (git(".", "rev-parse", "HEAD:docs") != git(".", "rev-parse", paste0(labRef, ":docs")) ||
    length(git(".", "status", "--porcelain", "--", "docs"))) {
  message("Note: your local docs/ differs from what bml.science serves. ",
          "This copies the live site (origin/main at ", labSha, "); ",
          "commit and push a new build here first if you want that copied.")
}

tmp <- tempfile("bml-sync-")  # inside R's session temp folder, removed on exit
dir.create(tmp)
tarFile <- file.path(tmp, "site.tar")
git(".", "archive", "--format=tar", "-o", shQuote(tarFile), labRef,
    "--", "docs", personalExtras)
if (untar(tarFile, exdir = tmp) != 0) {
  stop("Couldn't unpack the live site (see tar's message above); nothing copied.")
}
## every file arrived whole: names and sizes as git has them
listing <- git(".", "ls-tree", "-r", "-l", labRef, "--", "docs", personalExtras)
paths <- file.path(tmp, sub("^[^\t]*\t", "", listing))
sizes <- as.numeric(sub("^.*\\s(\\d+)\t.*$", "\\1", listing))
if (!isTRUE(all(file.size(paths) == sizes))) {
  stop("The live site didn't unpack completely; nothing copied.")
}
site <- file.path(tmp, "docs")
if (!file.exists(file.path(site, "index.html"))) {
  stop("No docs/index.html on origin/main; nothing to copy.")
}
if (!any(grepl('rel="canonical"', readLines(file.path(site, "index.html"), warn = FALSE),
               fixed = TRUE))) {
  message("Note: the live pages have no canonical link to bml.science yet ",
          "(canonical-url in run_website.R), so search engines may treat joshuawiley.com ",
          "as a separate site. Rebuild with run_website.R and push that first.")
}

## the personal differences
writeLines(personalDomain, file.path(site, "CNAME"))
for (f in personalExtras) {
  dir.create(dirname(file.path(site, f)), recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(file.path(tmp, f), file.path(site, f), overwrite = TRUE)) {
    stop("Couldn't copy ", f, "; nothing copied.")
  }
}

#### Compare with joshuawiley.com ####

git(personalRepo, "fetch", "--quiet", "origin", personalBranch)
countCommits <- function(range) as.integer(git(personalRepo, "rev-list", "--count", range))
ahead <- countCommits(paste0(personalRef, "..HEAD"))   # sync commits not on GitHub yet
behind <- countCommits(paste0("HEAD..", personalRef))  # changes on GitHub not here yet
if (ahead && behind) {
  stop(personalRepo, " and GitHub have both changed since they last matched; ",
       "run git pull there first.")
}
## only sync commits go out with a sync; anything else committed there and
## not pushed is for Joshua to push or drop first
others <- git(personalRepo, "log", "--oneline", "--no-decorate", paste0(personalRef, "..HEAD"))
others <- others[!grepl("^[0-9a-f]+ Sync with bml\\.science \\(", others)]
if (length(others)) {
  stop(personalRepo, " has commits that aren't on GitHub and aren't syncs; ",
       "push or drop them there first:\n", paste(others, collapse = "\n"))
}
personalDocs <- file.path(personalRepo, "docs")
if (behind && !dryRun) {
  git(personalRepo, "merge", "--ff-only", "--quiet", personalRef)
} else if (behind) {
  ## a dry run leaves the repo alone, so compare with GitHub's copy, as the
  ## real run will after catching up (nothing to unpack if it has no docs/)
  personalDocs <- file.path(tmp, "personal", "docs")
  dir.create(file.path(tmp, "personal"))
  if (length(git(personalRepo, "ls-tree", personalRef, "--", "docs"))) {
    personalTar <- file.path(tmp, "personal.tar")
    git(personalRepo, "archive", "--format=tar", "-o", shQuote(personalTar),
        personalRef, "--", "docs")
    if (untar(personalTar, exdir = file.path(tmp, "personal")) != 0) {
      stop("Couldn't unpack GitHub's copy of joshuawiley.com.")
    }
  }
}

newFiles <- treeFiles(site)
## what is on disk and what git has, so files git ignores and names that
## differ only in case both count
tracked <- git(personalRepo, "ls-tree", "-r", "--name-only",
               if (behind) personalRef else "HEAD", "--", "docs")
oldFiles <- union(treeFiles(personalDocs), sub("^docs/", "", tracked))
kept <- intersect(newFiles, oldFiles)
changes <- list(added = setdiff(newFiles, oldFiles),
                changed = kept[!sameFiles(site, personalDocs, kept)],
                removed = setdiff(oldFiles, newFiles))
changed <- length(unlist(changes)) > 0
for (type in names(changes)) {
  files <- changes[[type]]
  if (length(files)) {
    message(sprintf("%-8s %3d  %s%s", type, length(files),
                    paste(head(files, 6), collapse = ", "),
                    if (length(files) > 6) ", ..." else ""))
  }
}

#### Copy, commit and push ####

if (dryRun) {
  message(if (changed) {
    "Dry run: nothing copied."
  } else if (ahead) {
    sprintf("The copy in %s matches bml.science (%s), but %d commit(s) there aren't on GitHub yet; run this without --dry-run to push them.",
            personalRepo, labSha, ahead)
  } else {
    paste0("joshuawiley.com already matches bml.science (", labSha, ").")
  })
} else {
  if (changed) {
    tryCatch({
      unlink(personalDocs, recursive = TRUE)
      if (dir.exists(personalDocs)) stop("Couldn't clear ", personalDocs, ".")
      copied <- file.copy(site, personalRepo, recursive = TRUE)
      if (!copied || !setequal(treeFiles(personalDocs), newFiles) ||
          !all(sameFiles(site, personalDocs, newFiles))) {
        stop("The copy in ", personalDocs, " doesn't match bml.science.")
      }
      ## rebuild git's list of docs/ from disk, so renames that only change
      ## case are recorded (macOS ignores case); -f so the repo's ignore rules
      ## can't leave a site file out
      git(personalRepo, "rm", "-r", "-q", "--cached", "--ignore-unmatch", "--", "docs")
      git(personalRepo, "add", "-A", "-f", "--", "docs")
      staged <- sub("^docs/", "", git(personalRepo, "ls-files", "--", "docs"))
      if (length(staged) != length(newFiles) || !setequal(staged, newFiles)) {
        stop("git's list of docs/ doesn't match bml.science: ",
             paste(head(c(setdiff(newFiles, staged), setdiff(staged, newFiles)), 6),
                   collapse = ", "))
      }
      if (length(git(personalRepo, "diff", "--cached", "--name-only", "--", "docs"))) {
        git(personalRepo, "commit", "--quiet", "-m",
            shQuote(sprintf("Sync with bml.science (behavioralmedicinelab.github.io@%s)", labSha)))
        ahead <- ahead + 1
      } else {
        message("Those differences were only on disk, not in git (files git ignores, ",
                "or a name's case); tidied them, nothing to commit.")
      }
    }, error = function(e) {
      stop(conditionMessage(e), "\nNothing was committed. Undo the partial copy with\n  ",
           undoCmd, "\nthen run this again.", call. = FALSE)
    })
  }
  if (!ahead) {
    message("joshuawiley.com already matches bml.science (", labSha, ").")
  } else if (!push) {
    message(sprintf("%s has %d sync commit(s) that aren't on GitHub yet; push from there, or run this again without --no-push.",
                    personalRepo, ahead))
  } else {
    tryCatch(git(personalRepo, "push", "--quiet", "origin", personalBranch),
             error = function(e) {
               stop(conditionMessage(e), "\nThe sync is committed in ", personalRepo,
                    " but not on GitHub; run this again to push it.", call. = FALSE)
             })
    message("Pushed: joshuawiley.com now matches bml.science (", labSha, "). ",
            "GitHub Pages takes a minute or two to update.")
  }
}
