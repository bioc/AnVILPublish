.name_from_path <-
    function(path)
{
    package <- basename(path)
    directory <- dirname(path)
    descr <- tryCatch({
        packageDescription(package, directory, c("Package", "Type"))
    }, warning = function(w) {
        stop("no DESCRIPTION found at '", path, "'", call. = FALSE)
    })

    type <- ifelse(is.na(descr$Type), "Package", descr$Type)
    paste0(type, "-", descr$Package)
}

#' @importFrom utils packageDescription citation
#'
#' @importFrom stats setNames
.package_description <-
    function(path)
{
    package <- basename(path)
    directory <- dirname(path)
    descr <- packageDescription(package, directory)

    if (is.null(descr[["Author"]])) {
        parsed = tools:::.expand_package_description_db_R_fields(unlist(descr))
        descr[["Author"]] <- parsed[["Author"]]
        descr[["Maintainer"]] <- parsed[["Maintainer"]]
    }
    descr[["Authors"]] <- lapply(
        strsplit(descr[["Author"]], "\n")[[1]],
        function(x) setNames(sub(",$", "", trimws(x)), "Author")
    )
    citn <- withCallingHandlers({
        citation(package, directory)
    }, warning = function(...) {
        ## silence warnings, from no 'date' field?
        invokeRestart("muffleWarning")
    })
    if (is.null(citn$year))
        citn$year <- format(Sys.Date(), "%Y")

    descr[["Citation"]] <- format(citn, "text")

    descr
}

.package_dependencies <-
    function(path)
{
    package <- basename(path)
    directory <- dirname(path)
    descr <- packageDescription(package, directory)

    pkgs <- c(descr$Depends, descr$Imports, descr$Suggests, descr$LinkingTo)
    if (is.null(pkgs)) {
        descr[["NotebookPackages"]] <- character()
        return(descr["NotebookPackages"])
    }
    pkgs <- unlist(strsplit(pkgs, "[[:space:]]*,[[:space:]]+"))

    pattern <- "^R([[:space:]]*\\(.*\\))?$"
    pkgs <- pkgs[grep(pattern, pkgs, invert = TRUE)]
    pkgs <- sub(" .*", "", pkgs)

    txt <- paste0('"', pkgs, '"', collapse=", ")
    txt <- paste(strwrap(txt, indent = 4, exdent = 4), collapse="\n")
    descr[["NotebookPackages"]] <- paste("\n", txt, "\n")

    descr["NotebookPackages"]
}


#' @importFrom rmarkdown yaml_front_matter
.rmd_vignette_authors <-
    function(authors)
{
    if (is.character(authors)) {
        ## author: Iman Author, etc
        list(setNames(authors, "name"))
    } else {
        ## author:
        ## -  name: ...
        authors
    }
}

.rmd_vignette_description <-
    function(path, type)
{
    rmd <- .vignette_paths(path)
    yaml <- lapply(rmd, yaml_front_matter)
    titles <- .notebook_titles(rmd)
    yaml <- Map(function(x, title, rmd) {
        x$title <- unname(title)
        if (type %in% c("ipynb", "both"))
            x$ipynb <- sub("\\.[Rr]md", ".ipynb", basename(rmd))
        if (type %in% c("rmd", "both"))
            x$rmd <- basename(rmd)
        x$vignette_authors <- .rmd_vignette_authors(x$author)
        x
    }, yaml, titles, rmd)
    vignette_description <- list(Vignettes = yaml)

    vignette_description
}

#' @importFrom jsonlite unbox
.set_dashboard <-
    function(dashboard, namespace, name)
{
    setAttributes <- .get_terra()$setAttributes
    response <- setAttributes(
        namespace, name,
        list(description = unbox(dashboard))
    )
    if (status_code(response) >= 400L)
        .stop(response, namespace, name, "set dashboard failed")

    return(invisible(TRUE))
}

#' @importFrom AnVILGCP avstorage avtable_import
#'
#' @importFrom whisker whisker.render
#'
#' @importFrom readr read_csv
.set_table <-
    function(table_path, namespace, name)
{
    data <- list(
        bucket = avstorage(namespace, name)
    )

    txt <- readLines(table_path)
    fl <- tempfile()
    writeLines(whisker.render(txt, data), fl)
    tbl <- readr::read_csv(fl)
    response <- avtable_import(tbl, namespace = namespace, name = name)
    TRUE
}

.set_tables <-
    function(path, namespace, name)
{
    table_path <- file.path(path, "inst", "tables")
    table_paths <- dir(table_path, full.names = TRUE)

    if (!length(table_paths)) # early exit -- no tables for update
        return(TRUE)

    result <- vapply(
        table_paths, .set_table, logical(1),
        namespace, name
    )
    all(result)
}

#' Render R packages as AnVIL workspaces
#'
#' `as_workspace()` renders a package source tree (e.g., from a
#'   git checkout) as an AnVIL workspace.
#'
#' @details Information from the `DESCRIPTION` file and Rmd YAML are
#'     used to populate the 'DASHBOARD' tab.  See `?as_notebook()` for
#'     details on how vignettes are processed to notebooks.
#'
#' @inheritParams as_notebook
#'
#' @param path `character(1)` path to the location of the package
#'     source code.
#'
#' @param create `logical(1)` Create a new project?
#'
#' @param update `logical(1)` Update (over-write the existing
#'     DASHBOARD and any similarly named notebooks) an existing
#'     workspace?  If neither `create` nor `update` is TRUE, the code
#'     to create a workspace is run but no output generated; this can
#'     be useful during debugging.
#'
#' @param use_readme `logical(1)` Defaults to `FALSE`; if `TRUE` the
#'     content of README.md in package top-level folder is used with
#'     the package `DESCRIPTION` version and provenance metadata for
#'     rendering in the workspace 'DASHBOARD'.
#'
#' @param dry.run `logical(1)` When `TRUE`, all local processing
#'     (dashboard rendering, notebook conversion) is performed but no
#'     changes are pushed to the workspace. Overrides `create` and
#'     `update`. Use this to preview results without modifying AnVIL.
#'
#' @return `as_workspace()` returns the URL of the updated workspace,
#'     invisibly.
#'
#' @importFrom whisker whisker.render
#' @importFrom BiocBaseUtils isScalarLogical
#'
#' @examplesIf interactive()
#' as_workspace(
#'     path = "../AnVILPublish",
#'     namespace = "landmarkanvil2",
#'     name = "Bioconductor-Package-AnVILHCAR",
#'     dry.run = TRUE
#' )
#' @export
as_workspace <-
    function(path, namespace, name = NULL, create = FALSE, update = FALSE,
             use_readme = FALSE, type = c('ipynb', 'rmd', 'both'),
             quarto = c('render', 'convert'), dry.run = FALSE)
{
    type <- match.arg(type)
    quarto <- match.arg(quarto)
    stopifnot(
        isScalarCharacter(path), dir.exists(path),
        isScalarCharacter(namespace),
        isScalarCharacter(name) || is.null(name),
        isScalarLogical(create),
        isScalarLogical(update),
        isScalarLogical(use_readme),
        !use_readme || file.exists(file.path(path, "README.md")),
        isScalarLogical(dry.run)
    )
    path <- normalizePath(path)

    if (is.null(name))
        name <- paste0("Bioconductor-", .name_from_path(path))

    ## create / update workspace
    if (dry.run) {
        message("dry.run = TRUE: workspace '", name, "' would be created or updated")
    } else if (create) {
        create_workspace(namespace, name)
    } else if (!update) {
        message("use 'update = TRUE' to make changes to the workspace")
    }

    ## populate dashboard from package and vignette metadata
    description <- .package_description(path)
    vignette_description <- .rmd_vignette_description(path, type)
    processing <- list(
        ProcessDate = Sys.time(),
        RVersion = paste0(R.version$major, ".", R.version$minor),
        BioconductorVersion = BiocManager::version()
    )
    data <- c(description, vignette_description, processing)
    data$namespace <- namespace
    data$name <- name

    tmpl <- .template("dashboard.tmpl")
    dashboard <- whisker.render(tmpl, data)

    if (use_readme) {
        rmepath <- file.path(path, "README.md")
        rme <- paste(readLines(rmepath), collapse="\n")
        dashboard <- paste(dashboard, rme, collapse="\n")
    }

    if (!dry.run) {
        !(create || update) || .set_dashboard(dashboard, namespace, name)
        !(create || update) || .set_tables(path, namespace, name)
    }

    ## create setup notebook
    setup <- .package_dependencies(path)
    data <- c(data, setup)
    tmpl <- .template("setup-notebook.tmpl")
    setup_notebook <- whisker.render(tmpl, data)
    tmpdir <- tempfile()
    dir.create(tmpdir)
    rmd_setup_file <- paste0("00-", name, ".Rmd")
    rmd_setup_path <- file.path(tmpdir, rmd_setup_file)
    writeLines(setup_notebook, rmd_setup_path)

    ## build vignettes and add to workspace
    rmd_paths <- c(.vignette_paths(path), rmd_setup_path)
    as_notebook(
        rmd_paths, namespace, name,
        update = !dry.run && (update || create),
        type, quarto, dry.run = dry.run
    )

    wkspc <-
        paste0("https://anvil.terra.bio/#workspaces/", namespace, "/", name)
    invisible(wkspc)
}

