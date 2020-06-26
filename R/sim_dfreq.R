sim_dfreq <- function(n) {
  dfreqs <- readRDS("Data/noise_only.rds")$X3
  return(sample(dfreqs, n, replace = TRUE))
}
