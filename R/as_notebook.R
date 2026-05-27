#' @importFrom yaml read_yaml
.vignette_paths <-
    function(path)
{
    regex <- "\\.[QqRr]md$"
    vignette_path <- file.path(path, "vignettes")
    vignettes <- dir(vignette_path, pattern = regex, full.names = TRUE)
    if (!length(vignettes)) {
        ## workshops, books, etc can have Rmd in the root directory
        vignette_path <- path
        vignettes <- dir(vignette_path, pattern = regex, full.names = TRUE)
    }
    if (!length(vignettes))
        stop(
            "unable to find vignettes",
            "\n  path: '", path, "'",
            call. = FALSE
        )

    ## use `_bookdown.yml` to order vignettes, if available
    bookdown_path <- file.path(path, "_bookdown.yml")
    if (file.exists(bookdown_path)) {
        bookdown_rmds <- read_yaml(bookdown_path)$rmd_files
        vignettes[match(bookdown_rmds, basename(vignettes))]
    } else {
        sort(vignettes)
    }
}

#' @importFrom rmarkdown render md_document
.rmd_to_md <-
    function(rmd_paths)
{
    knitr::opts_chunk$set(eval = FALSE)
    vapply(rmd_paths, render, character(1), md_document(), envir = globalenv())
}

## Extract vignette title from Rmd
#' @importFrom rmarkdown yaml_front_matter
.notebook_title_from_yaml <-
    function(rmd)
{
    ## retrieve title from yaml
    front_matter <- yaml_front_matter(rmd)
    names(front_matter) <- tolower(names(front_matter))
    front_matter$title
}

#' @importFrom utils head
.notebook_title_from_heading <-
    function(rmd)
{
    ## ...or use the first level one heading as title
    lines <- readLines(rmd)
    rmd_headings <- lines[grepl("^#[[:blank:]]+", lines)]

    ## ignore headings starting with '(PART)' (FIXME: is this just a convention?)
    PART_lines <- grepl("^#[[:blank:]]+\\(PART\\)+", rmd_headings)
    title <- head(rmd_headings[!PART_lines], 1L)

    ## remove markdown tag
    sub("^#[[:blank:]]*", "", title)
}

.notebook_title_from_path <-
    function(rmd)
{
    title <- basename(rmd)
    sub("\\.[Rr]md$", "", title)
}

.notebook_titles <-
    function(rmd_paths)
{
    titles <- vapply(rmd_paths, function(rmd) {
        title <- .notebook_title_from_yaml(rmd)
        if (length(title) == 0L)
            title <- .notebook_title_from_heading(rmd)
        if (length(title) == 0L)
            title <- .notebook_title_from_path(rmd)

        title
    }, character(1))
}

#' @importFrom utils tail
.md_to_ipynb <-
    function(md_paths)
{
    stop(
        "conversion using 'notedown' is no longer supported; ",
        "ensure `Sys.which('quarto')` finds an installation of 'quarto' ",
        "software from Posit"
    )
    ipynb_paths <- sub("\\.md", ".ipynb", md_paths)
    for (i in seq_along(md_paths)) {
        system2("notedown", c(md_paths[[i]], "-o", ipynb_paths[[i]]))
        ## FIXME: more robust way to add / update top-level metadata
        txt <- readLines(ipynb_paths[[i]])
        idx <- tail(grep(' "metadata": {},', txt, fixed = TRUE), 1)
        txt[idx] <- paste0(
            ' "metadata": {',
            '  "kernelspec": {',
            '   "display_name": "R",',
            '   "language": "R",',
            '   "name": "ir"',
            '  }',
            '},'
        )
        writeLines(txt, ipynb_paths[[i]])
    }
    ipynb_paths
}

#' @importFrom AnVILGCP avstorage avcopy
.cp_to_cloud_notebooks <-
    function(notebooks, namespace, name)
{
    bucket <- avstorage(namespace, name)
    bucket_notebooks <- paste0(bucket, "/notebooks/")
    avcopy(notebooks, bucket_notebooks)
    paste0(bucket_notebooks, basename(notebooks))
}

.rmd_to_quarto <-
    function(rmd_paths, quarto)
{
    for (rmd_path in rmd_paths) {
        if (identical(quarto, "render")) {
            system2("quarto", c("render", rmd_path, "--to", "ipynb"))
        } else {
            system2("quarto", c("convert", rmd_path))
        }
    }
    sub("\\.Rmd", ".ipynb", rmd_paths)
}

.quarto_exists <-
    function()
{
    nzchar(
        Sys.which("quarto")
    )
}

#' Render vignettes as .ipynb notebooks
#'
#' `as_notebook()` renders Rmarkdown (`.Rmd`) or Quarto
#'   (`.Qmd`) vignettes as Juptyer (`.ipynb`) notebooks. The
#'   vignettes and notebooks are updated in an AnVIL workspace.
#'
#' @details See the vignette
#'     "Publishing R / Bioconductor Packages To AnVIL Workspaces" for
#'     details on the conversion process; best results are obtained
#'     when Quarto software is available.
#'
#' @param rmd_paths `character()` paths to Rmd or Qmd files.
#'
#' @param namespace `character(1)` AnVIL namespace (billing project)
#'     to be used.
#'
#' @param name `character(1)` AnVIL workspace name.
#'
#' @param update `logical(1)` Update (over-write any similarly named
#'     notebooks) an existing workspace? The default (FALSE) creates
#'     notebooks locally, e.g., for previewing via `jupyter notebook
#'     *ipynb`.
#'
#' @param type `character(1)` The type of notebook to be copied to the
#'     workspace. Must be on of `ipynb`, `rmd`, or `both`. `ipynb`
#'     copies only the Jupyter notebook. `rmd` copies Rmarkdown and
#'     Quarto vignettes. `both` copies both notebooks and vignettes.
#'
#' @param quarto `character(1)` If the program Quarto is installed,
#'     this parameter indicates whether the .Rmd files will be
#'     rendered or converted.  See vignette for more details.
#'
#' @param dry.run `logical(1)` When `TRUE`, notebooks are created
#'     locally but no files are copied to the workspace. Use this to
#'     preview the conversion without modifying the workspace.
#'
#' @return `as_notebook()` returns the paths to the local (if `update
#'     = FALSE` or `dry.run = TRUE`) or the workspace notebooks.
#'
#' @importFrom BiocBaseUtils isCharacter isScalarCharacter
#'
#' @examples
#' exampleRmd <-
#'     system.file("extdata", "example.Rmd", package = "AnVILPublish")
#' as_notebook(
#'     exampleRmd,
#'     "landmarkanvil2",
#'     "Bioconductor-Package-AnVILHCAR",
#'     dry.run = TRUE
#' )
#' @export
as_notebook <-
    function(
        rmd_paths, namespace, name, update = FALSE,
        type = c('ipynb', 'rmd', 'both'),
        quarto = c('render', 'convert'),
        dry.run = FALSE)
{
    type <- match.arg(type)
    quarto <- match.arg(quarto)
    stopifnot(
        isCharacter(rmd_paths), all(file.exists(rmd_paths)),
        isScalarCharacter(namespace),
        isScalarCharacter(name),
        isScalarLogical(update),
        isScalarLogical(dry.run)
    )

    notebooks <- character(0)
    if (type %in% c('ipynb', 'both')) {
        if (.quarto_exists()) {
            notebooks <- .rmd_to_quarto(rmd_paths, quarto)
        } else {
            mds <- .rmd_to_md(rmd_paths)
            notebooks <- .md_to_ipynb(mds)
        }
    }
    if (type %in% c('rmd', 'both')) {
        notebooks <- c(notebooks, rmd_paths)
    }

    if (dry.run) {
        message(
            "dry.run = TRUE: ",
            length(notebooks), " notebook(s) created locally; ",
            "not copied to workspace '", name, "'"
        )
        notebooks
    } else if (update) {
        .cp_to_cloud_notebooks(notebooks, namespace, name)
    } else {
        message("use 'update = TRUE' to copy notebooks to the workspace")
        notebooks
    }
}
