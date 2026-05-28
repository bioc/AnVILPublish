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

    ## ignore headings starting with '(PART)'
    ## (FIXME: is this just a convention?)
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
    sub("\\.[Rr]md$", ".ipynb", rmd_paths)
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
#'   (`.qmd`) vignettes as Juptyer (`.ipynb`) notebooks. The
#'   vignettes and notebooks are updated in an AnVIL workspace.
#'
#' @details See the vignette
#'     "Publishing R / Bioconductor Packages To AnVIL Workspaces" for
#'     details on the conversion process; best results are obtained
#'     when the `quarto` command line interface (CLI) is available.
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
#' @param quarto `character(1)` Method to convert vignettes to
#'     `.ipynb`. Either `"render"` (runs `quarto render --to ipynb`)
#'     or `"convert"` (runs `quarto convert`). Note that the `quarto`
#'     CLI must be installed.
#'
#' @param dry.run `logical(1)` When `TRUE`, notebooks are created
#'     locally but no files are copied to the workspace. Use this to
#'     preview the conversion without modifying the workspace.
#'
#' @return `as_notebook()` returns the paths to the local
#'     (if `update = FALSE` or `dry.run = TRUE`) or the
#'     workspace notebooks.
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
            if (dry.run)
                message(
                    "dry.run = TRUE: ",
                    "The 'quarto' CLI is not available; ",
                    "notebooks will not be rendered as .ipynb files"
                )
            else
                stop(
                    "The system installation of the 'quarto' CLI via",
                    " `Sys.which('quarto')` was not found;",
                    " install Quarto from https://quarto.org/docs/get-started/"
                )
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
