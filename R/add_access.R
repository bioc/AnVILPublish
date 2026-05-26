.BIOCONDUCTOR_USER <- "Bioconductor_User@firecloud.org"

.update_workspace_acl <-
    function(namespace, name)
{
    updateWorkspaceACL <- .get_terra()$updateWorkspaceACL
    properties <- list(list(
        accessLevel = "READER",
        canCompute = FALSE,
        canShare = TRUE,
        email = .BIOCONDUCTOR_USER
    ))
    response <- updateWorkspaceACL(
        namespace, name,
        body = properties
    )
    if (status_code(response) >= 400L)
        .stop(response, namespace, name, "update workspace permissions failed")
}

#' @rdname add_access
#'
#' @title Add Bioconductor_User group to workspace access
#'
#' @description `add_access()` adds the
#'     `Bioconductor_User` group to a workspace with `READER`
#'     permissions. Users gain access to the workspace (and others) by
#'     being added to the Bioconductor_User group.
#'
#' @param namespace character(1) namespace (billing account) under
#'     which the workspace belongs.
#'
#' @param name character(1) name of the workspace to add access
#'     credentials.
#'
#' @return `add_access()` returns TRUE, invisibly.
#'
#' @importFrom BiocBaseUtils isScalarCharacter
#'
#' @examplesIf interactive()
#' add_access("landmarkanvil2", "Bioconductor-Package-AnVILHCAR")
#' @export
add_access <-
    function(namespace, name)
{
    stopifnot(
        isScalarCharacter(namespace),
        isScalarCharacter(name)
    )
    .update_workspace_acl(namespace, name)
    return(invisible(TRUE))
}
