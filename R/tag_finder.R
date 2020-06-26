#' @param tags_sqlite
#' @param sg_csv
#' @param freq numeric; default antenna frequency, in MHz 
#'   (defaults to 166.376 MHz).
#' @param freq_slop numeric; tag frequency slop, in KHz. A tag burst 
#'   will only be recognized if its bandwidth (i.e. the range of frequencies 
#'   of its component pulses) is within `freq_slop`. Applies to all bursts 
#'   within a sequence. Defaults to 0.5 kHz
#' @param min_dfreq numeric; minimum offset frequency, in kHz. Pulses with 
#'   smaller offset frequency are dropped. Defaults to -1000, so no minimum
#'   offset for all practical purposes.
#' @param max_dfreq numeric; maximum offset frequency, in kHz. Pulses with 
#'   larger offset frequency are dropped. Defaults to 1000, so no maximum
#'   offset for all practical purposes.
#' @param pulses_to_confirm integer; how many pulses must be detected 
#'   before a hit is confirmed. By default, it is set to the nominal number 
#'   of pulses per burst for nanotags (i.e., 4 pulses); for more stringent
#'   filtering when `burst_slop` is large relative to burst interval, consider
#'   at least 8 pulses so that more gaps must match those registered for a given 
#'   tag before a hit is reported.
#' @param pulse_slop numeric; how much to allow time between consecutive pulses in 
#'   a burst to differ from measured tag values, in milliseconds. Defaults to 1.5 ms
#' @param burst_slop numeric; how much to allow time between consecutive 
#'   bursts to differ from measured tag values, in milliseconds. Defaults to 10 ms
#' @param burst_slop_expansion numeric; how much to increase burst slop 
#'   for each missed burst in milliseconds; meant to allow for clock drift.
#'   Defaults to 1 ms per missed burst.
#' @param sig_slop integer; tag signal strength slop, in dB. A tag burst will only
#'   be recognized if its dynamic range (i.e. range of signal strengths of its 
#'   component pulses) is within `sig_slop`. Applies within each burst of a 
#'   sequence. Defaults to 10 dB
tag_finder <- function(tags_sqlite, sg_csv, 
                       freq = 166.376, freq_slop = 0.5,
                       min_dfreq = -1000L, max_dfreq = 1000L, 
                       pulses_to_confirm = 8, pulse_slop = 1.5,
                       burst_slop = 10, burst_slop_expansion = 1.0,
                       sig_slop = 10) {
  
  FREQ <- paste("-f", freq)
  FSLOP <- paste("-s", freq_slop)
  MINDFREQ <- paste("-m", min_dfreq)
  MAXDFREQ <- paste("-M", max_dfreq)
  CONFIRM <- paste("-c", pulses_to_confirm)
  PSLOP <- paste("-p", pulse_slop)
  BSLOP <- paste("-b", burst_slop)
  BSLOPEXP <- paste("-B", burst_slop_expansion)
  SSLOP <- paste("-l", sig_slop)
  
  command <- paste("find_tags_unifile", FREQ, FSLOP, MINDFREQ, MAXDFREQ,
                   CONFIRM, PSLOP, BSLOP, BSLOPEXP, SSLOP,
                   tags_sqlite, sg_csv)
  
  tmp <- system(command, intern = TRUE)
  if (length(tmp) == 1)
    tmp <- empty_tf()
  else 
    tmp <- readr::read_csv(tmp)
  tmp
}

empty_tf <- function() {
  out <- tibble(ant = numeric(0), ts = numeric(0), fullID = character(0), 
                freq = numeric(0), freq.sd = numeric(0), sig = numeric(0), 
                sig.sd = numeric(0), noise = numeric(0), run.id = numeric(0), 
                pos.in.run = numeric(0), slop = numeric(0), burst.slop = numeric(0), 
                ant.freq = numeric(0))
  return(out)
}
