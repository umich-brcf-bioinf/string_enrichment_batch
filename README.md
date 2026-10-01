# STRING enrichment evaluation

This submits ranked gene lists to the STRING functional enrichment API, polls until each job finishes, downloads the results, and builds a comparison report across contrasts.  It makes a  couple of visualizations for the contrasts-some are limited to just a subset of contrasts which you can select.

## Usage

```
singularity exec --bind /nfs:/nfs docker://umichbfxcore/proteomics_env:oculomics_cu11_v2 \
  Rscript run_string_enrichment.R --input=/path/to/string/input --output=/path/to/report/2026-08-05
```

`run_string_enrichment.R` is a thin CLI wrapper: it parses `--key=value`
arguments and calls `rmarkdown::render()` on `string_enrichment.Rmd` with
them as knit params. 

## Input format

`--input` should point to a folder containing one file per contrast:

* Two tab-separated columns, **no header**: gene identifier (anything STRING
  recognizes — e.g. an Ensembl gene ID) and a numeric ranking statistic (e.g.
  a t-statistic from `limma::topTable`).
* The filename (minus extension) becomes the contrast's label in the report.

This can be written from limma results for example via:

```r
topTable_result %>%
  select(gene, t) %>%
  write.table(file = ".../string/input/<contrast>.tsv", sep = "\t", col.names = FALSE, row.names = FALSE, quote = FALSE)
```

## Params

| param | default | meaning |
|---|---|---|
| `input_loc` | *(required)* | folder of per-contrast input files, as above |
| `output_loc` | *(required)* | destination folder; `tables/`, `figures/`, `cache/`, `code/` are created under it |
| `species` | `9606` | NCBI/STRING species id |
| `fdr_threshold` | `0.05` | submission-time `ge_fdr` cutoff |
| `caller_identity` | `"ncarruth"` | STRING `caller_identity` |
| `api_key` | (shared courtesy key) | STRING `api_key` — this is a rate-limit token, not a secret credential |
| `poll_interval_sec` | `30` | delay between job status checks |
| `poll_timeout_min` | `60` | per-job polling ceiling before it's marked timed out |
| `force_refresh` | `FALSE` | ignore the cache and resubmit/redownload every contrast |

Pass overrides as `--param=value` to `run_string_enrichment.R`.

## Output layout

```
output_loc/
├── string_enrichment_summary.html   # the report
├── tables/
│   └── string_result_urls.csv       # per-contrast STRING page links
├── figures/
│   ├── Biological_Process_upset_plot.png/.pdf
│   └── FDR_scatter_plot_Process.png/.pdf, FDR_scatter_plot_CC.png/.pdf
├── cache/
│   └── string_results.RDS           # job ids + downloaded results, for resuming
└── code/
    └── string_enrichment.Rmd        # copy of the exact Rmd used, for provenance
```

## Resuming and re-rendering

Submission + polling can take several minutes across many contrasts, so
results are cached to `cache/string_results.RDS`. Re-rendering against the
same `output_loc` reuses that cache instead of resubmitting to STRING. Pass
`--force_refresh=TRUE` to force a clean resubmission (e.g. if the input
files changed).

If a contrast's job fails or doesn't finish within `poll_timeout_min`, it is
dropped from the report with a visible warning rather than aborting the
whole render — check the "Skipped contrasts" callout at the top of the
summary.

## Environment

Runs under the same `proteomics_env:oculomics_cu11_v2` Singularity image
(see the `srun`/`singularity` lines at the top of `run_string_enrichment.R`) 
