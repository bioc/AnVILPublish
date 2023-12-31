#' @importFrom AnVIL Terra
.get_terra <- local({
    terra <- NULL
    renew <- NULL
    function() {
        if (is.null(terra) || Sys.time() > renew) {
            renew <<- Sys.time() + 3600L
            terra <<- Terra()
        }
        terra
    }
})

#' @importFrom httr status_code http_status content
.stop <-
    function(response, namespace, name, text)
{
    message <- content(response)$message
    if (is.null(message))
        message <- paste(as.character(content(response)), collapse = "\n")
    stop(
        text,
        "\nworkspace: ", namespace, "/", name,
        "\nstatus code: ", status_code(response),
        "\nhttp status: ", http_status(response)$message,
        "\nresponse content:\n", message,
        call. = FALSE
    )
}

.template <-
    function(tmpl)
{
    tmpl_path <- system.file(package="AnVILPublish", "template", tmpl)
    readLines(tmpl_path)
}
