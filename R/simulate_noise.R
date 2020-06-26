#' @param duration numeric; simulated run time in hours (default = 1 h)
#' @param noise_rate numeric; the desired rate (pulses per second) of random noise 
#'  to generate; probably 100 pulses/sec is a very high noise site in the network
#' @param fix_noise_freq logical; fix the frequency offset of noise pulses  
#'  relative to receiver listening freq? If `TRUE` (default), every pulse simulated 
#'  will pass tagfinder's filtering settings and thus be capable of generating false
#'  positives. This may emulate a nearby consistent source of noise at nominal 
#'  North American nanotag frequencies. If `FALSE`, each noise pulse receives a frequency
#'  offset value generated according to the approximate distribution of noise pulses 
#'  measured from SensorGnomes on the Motus network with FCDs at 166.376 MHz. Thus, false 
#'  positives are still possible but because many false positive bursts will exhibit
#'  considerable dynamic range in the component pulse frequencies, false positive rate
#'  will be considerably lower than the default behavior.
#' @param seed random seed
#' @param out character scalar indicated path to desired csv output ready for tagfinder
#'  analysis

simulate_noise <- function(duration = 1, noise_rate = 50, fix_noise_freq = TRUE,
                           seed = NULL, out = "Data/simulated_sg_noise.csv") {
  
  start <- Sys.time()
  end <- start + as.difftime(duration, units = "hours")
  n_sims <- as.integer(noise_rate * duration * 60 * 60)
  if (!is.null(seed)) set.seed(seed)
  pulse_times <- sort(runif(n_sims, min = as.numeric(start), max = as.numeric(end)))
  
  if (fix_noise_freq)
    dfreq <- 4
  else {
    source("R/sim_dfreq.R")
    dfreq <- sim_dfreq(n_sims)
  }
  
  sg_string <- paste("p1", sprintf("%.4f", pulse_times), sprintf("%.3f", dfreq), "-40.00,-50.00", sep = ",")
  message("Generated ", n_sims, " pulses over ", duration, ifelse(duration > 1, " hours", " hour"), " of simulated time.")
  writeLines(sg_string, con = out)
}
