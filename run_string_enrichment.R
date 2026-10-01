# srun --nodes=1 --partition=brcf_bfx_project --time=72:00:00 --mem=20GB --pty bash -i
#
# singularity exec --bind /nfs:/nfs docker://umichbfxcore/proteomics_env:oculomics_cu11_v2 \
#   Rscript run_string_enrichment.R --input=/path/to/diffex/string/input --output=/path/to/report/2026-08-05
#
# Optional overrides (see string_enrichment.Rmd params for defaults):
#   --species= --fdr_threshold= --caller_identity= --api_key=
#   --poll_interval_sec= --poll_timeout_min= --force_refresh=

suppressMessages(library(rmarkdown))

args <- commandArgs(trailingOnly = TRUE)

numeric_params <- c("species", "fdr_threshold", "poll_interval_sec", "poll_timeout_min")
logical_params <- c("force_refresh")

parsed <- list()
for (a in args) {
    if (!startsWith(a, "--") || !grepl("=", a, fixed = TRUE)) {
        stop("Arguments must be of the form --key=value, got: ", a)
    }
    kv <- sub("^--", "", a)
    key <- sub("=.*$", "", kv)
    value <- sub("^[^=]*=", "", kv)
    parsed[[key]] <- value
}

if (is.null(parsed$input) || is.null(parsed$output)) {
    stop("Usage: Rscript run_string_enrichment.R --input=<diffex folder> --output=<report folder> [--param=value ...]")
}

render_params <- list(input_loc = parsed$input, output_loc = parsed$output)
for (key in setdiff(names(parsed), c("input", "output"))) {
    value <- parsed[[key]]
    if (key %in% numeric_params) value <- as.numeric(value)
    if (key %in% logical_params) value <- as.logical(value)
    render_params[[key]] <- value
}

dir.create(parsed$output, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(parsed$output, "code"), showWarnings = FALSE)

script_dir <- dirname(sub("--file=", "", grep("--file=", commandArgs(trailingOnly = FALSE), value = TRUE)))
rmd_path <- file.path(script_dir, "string_enrichment.Rmd")

rmarkdown::render(
    rmd_path,
    output_file = file.path(parsed$output, "string_enrichment_summary.html"),
    params = render_params,
    envir = new.env()
)

file.copy(rmd_path, file.path(parsed$output, "code"), overwrite = TRUE)
