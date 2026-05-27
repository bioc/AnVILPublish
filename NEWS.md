# AnVILPublish 1.24.0

## New Features

- (v. 1.23.1) Add `dry.run` argument to `add_access()`, `as_notebook()`,
  and `as_workspace()` to allow local processing and previewing
  without making remote changes in AnVIL.

- (v. 1.23.3) Add `AnVILBase` to `Suggests`.

## Significant User-Visible Changes

- (v. 1.23.1) Remove legacy support for python `notedown` conversion.
  A system installation of Quarto is now required to convert `.Rmd` to
  `.ipynb` notebooks, and a clear error is thrown if it is not found.

- (v. 1.23.1) Add `quarto-cli` to `SystemRequirements` in DESCRIPTION.

- (v. 1.23.1) Add `URL` and `BugReports` fields to DESCRIPTION.

- (v. 1.23.1) Add funding (`fnd`) role and grant number to package authors.

## Bug Fixes

- (v. 1.23.1) Handle lowercase `.rmd` extensions in `as_notebook()`.

# AnVILPublish 1.22.0

## New Features

- (v. 1.21.1) Export `create_workspace()` for creating a new AnVIL workspace
  without necessarily populating it from an R package.

# AnVILPublish 1.20.0

## Significant User-Visible Changes

- (v. 1.19.0) Update to use `GCPtools` for `gcloud` checks.

# AnVILPublish 1.18.0

- No significant changes.

# AnVILPublish 1.16.0

## Significant User-Visible Changes

- (v. 1.15.0) Use `AnVILGCP` for storage and copying functions,
  replacing `AnVIL` usage.

## Documentation

- (v. 1.15.0) Use `README.Rmd` script for `README.md`.

- (v. 1.15.2) Update `AnVILPublishIntro.Rmd` and `README.md`.

# AnVILPublish 1.14.0

## New Features

- (v. 1.13.2) Move `BiocManager` to `Imports` as it is used in code.

- (v. 1.13.1) Use `BiocBaseUtils` for internal utility functions.

## Documentation

- (v. 1.13.0) Add a note to the vignette clarifying that only Google Cloud
  Platform workspaces are supported.

# AnVILPublish 1.12.0

## Bug Fixes

- (v. 1.11.3) Link Rmd (and / or ipynb) vignettes to dashboard

# AnVILPublish 1.10.0

- (v. 1.11.1) Remove support for `notedown` Python module conversion.

# AnVILPublish 1.8.0

## New Features

- (v. 1.7.1) Support publication output '.Rmd'

- (v. 1.7.2) Support 'Quarto' for Rmd to ipynb conversion

- (v. 1.7.3) Support 'Qmd' files.

## User Visible Changes

- (v. 1.7.4) Update workspace publication -- put 'Description'
  directly under title so it appears in WORKSPACE summary; add current
  'Date' to citation if not already defined.

## Bug Fixes

- (v. 1.7.4) Workspace dashboard and startup link to notebooks in
  'analysis' rather than 'notebook' location; clean up vignette author
  list.

# AnVILPublish 1.4.0

## New Features

- (v. 1.3.2) Support _bookdown.yml -- name and order vignettes

# AnVILPublish 1.2.0

## New Features

- Include README.md on Workspace landing page (thanks Vince Carey).

## Bug Fixes

- `as_workspace()` correctly passes an unboxed 'description' attribute
  when setting the dashboard.

# AnVILPublish 0.0.10

- Add 'best practices' and rationale for Rmarkdown-to-jupyter notebook
  conversion.

# AnVILPublish 0.0.9

- Create a notebook `'00-<<workspace name>>'` to install package /
  book dependencies specified in the original source.
- Don't link to vignettes from the DASHBOARD, since the namespace
  changes in cloned workspaces.
- `as_workspace(..., create = FALSE, update=FALSE)` now evaluates
  code, silently.

# AnVILPublish 0.0.8

- Support collections of Rmd files that are not packages, e.g.,
  bookdown sites.
- Add R / Bioconductor version to dashboard

# AnVILPublish 0.0.7

- Revise Rmd-to-ipynb work flow

  - Don't evaluate code chunks (avoids including output in notebook,
    and side-effects because rmarkdown::render does not start a
    separate process)
  - Insert metadata to use the R kernel. jupytext can do this more
    elegantly, but does from .md renders code chunks and pre-formatted
    rather than evaluation cells, and from .Rmd does not process
    markdown well enough, e.g., not suppporting [foo][]-style links
    when the definition is elsewhere in the document.

# AnVILPublish 0.0.6

- Added a `NEWS.md` file to track changes to the package.
- Extensive interface renaming

  - `as_workspace()` (formerly `package_source_as_workspace()`)
  - `as_notebook()` (formerly `vignettes_to_notebooks()`)
  - `add_access()` (formerly `bioconductor_user_access()`)
