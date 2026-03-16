#' @rdname AnVILPublish-utils
#'
#' @title Create an AnVIL Workspace
#'
#' @description Call the `Terra()` API to create a new AnVIL workspace. This is
#'   a helper function for `as_workspace()`, but can be used directly if you
#'   want to create a workspace without populating it with content from an R
#'   package. This is typically used by developers who want to create a
#'   workspace and then run other functions to populate it with content, e.g.,
#'   importing data into the workspace.
#'
#' @inheritParams as_workspace
#'
#' @importFrom jsonlite unbox
#'
#' @returns `create_workspace()` returns `TRUE` invisibly if the workspace was
#'   created successfully; otherwise, an error is raised.
#'
#' @examplesIf interactive()
#' create_workspace("my-namespace", "my-workspace")
#'
#' @export
create_workspace <-
    function(namespace, name)
{
    createWorkspace <- .get_terra()$createWorkspace
    response <- createWorkspace(
        namespace = namespace, name = name,
        attributes = list(
            description = unbox("New workspace")
        )
    )
    if (status_code(response) >= 400L)
        .stop(response, namespace, name, "create workspace failed")

    invisible(TRUE)
}

