test_that("'.vignette_paths()' finds Qmd and Rmd notebooks", {
    package <- tempfile(); dir.create(package)
    vignettes <- file.path(package, "vignettes"); dir.create(vignettes)
    ## rmd only
    rmd_vignette <- tempfile(tmpdir = vignettes, fileext = ".Rmd")
    writeLines("", rmd_vignette)
    expect_identical(
        .vignette_paths(package), normalizePath(rmd_vignette)
    )
    ## rmd + qmd
    qmd_vignette <- tempfile(tmpdir = vignettes, fileext = ".Qmd")
    writeLines("", qmd_vignette)
    expect_identical(
        .vignette_paths(package),
        c(rmd_vignette, qmd_vignette) |>
            normalizePath() |>
            sort()
    )
    ## qmd only
    unlink(rmd_vignette)
    expect_identical(
        .vignette_paths(package), normalizePath(qmd_vignette)
    )
})

test_that("'.notebook_title_from_*()' work", {
    txt <- c(
        '---',
        'title: "Title from YAML"',
        '---',
        '# (PART) A part',
        '# Title as heading'
    )

    expect_identical(
        .notebook_title_from_yaml(textConnection(txt)),
        "Title from YAML"
    )
    expect_identical(
        .notebook_title_from_heading(textConnection(txt)),
        "Title as heading"
    )

    txt <- c(
        '---',
        'title: "Title as YAML only"',
        '---',
        '# (PART) A part'
    )
    expect_identical(
        .notebook_title_from_yaml(textConnection(txt)),
        "Title as YAML only"
    )
    expect_true(length(.notebook_title_from_heading(textConnection(txt))) == 0L)
                                
    txt <- "# Title as heading only"
    expect_true(length(.notebook_title_from_yaml(textConnection(txt))) == 0L)
    expect_identical(
        .notebook_title_from_heading(textConnection(txt)),
        "Title as heading only"
    )

    txt <- c(
        '---',
        'Title: "Title from capitalized YAML"',
        '---'
    )
    expect_identical(
        .notebook_title_from_yaml(textConnection(txt)),
        "Title from capitalized YAML"
    )

    txt <- c(
        '---',
        'description: "YAML without title"',
        '---',
        '#  (PART) Body without level one # heading',
        '## Level two' 
    )
    expect_true(length(.notebook_title_from_yaml(textConnection(txt))) == 0L)
    expect_true(length(.notebook_title_from_heading(textConnection(txt))) == 0L)

    ## from path
    expect_identical(.notebook_title_from_path("foo/bar.Rmd"), "bar")
    expect_identical(.notebook_title_from_path("foo/bar.rmd"), "bar")
    expect_identical(.notebook_title_from_path("foo/bar"), "bar")
})
