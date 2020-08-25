% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/as_notebook.R
\name{as_notebook}
\alias{as_notebook}
\title{Render vignettes as .ipynb notebooks}
\usage{
as_notebook(rmd_paths, namespace, name, update = FALSE)
}
\arguments{
\item{rmd_paths}{\code{character()} paths to to Rmd files.}

\item{namespace}{\code{character(1)} AnVIL namespace (billing project)
to be used.}

\item{name}{\code{character(1)} AnVIL workspace name.}

\item{update}{\code{logical(1)} Update (over-write any similarly named
notebooks) an existing workspace? The default (FALSE) creates
notebooks locally, e.g., for previewing via \verb{jupyter notebook *ipynb}.}
}
\value{
\code{as_notebook()} returns the paths to the local (if \code{update = FALSE}) or the workspace notebooks.
}
\description{
\code{as_notebook()} renders .Rmd vignettes as .ipynb
notebooks, and updates the notebooks in an AnVIL workspace.
}
\details{
\code{.Rmd} Vignettes are processed to \code{.md} using
\code{rmarkdown::render(..., md_document())}, and then translated to
\code{.ipynb} using python software called \code{notedown}; notedown is
available at https://github.com/aaren/notedown.\preformatted{The translation is not perfect, for instance code chunks marked
as `eval = FALSE` are not marked as such in the python notebook.
}
}