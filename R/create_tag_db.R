create_tag_db <- function(sqlite_dir, out = "Data/tag_db.sqlite") {
  if (!dir.exists(sqlite_dir)) stop("That directory doesn't seem to exist.")
  dbs <- list.files(path = sqlite_dir, pattern = ".sqlite$", full.names = TRUE)
  if (length(dbs) == 0) stop("No .sqlite files found in that directory.")
  
  tag_db <- dbConnect(RSQLite::SQLite(), out)
  
  for (i in seq_along(dbs)) {
    con <- dbConnect(RSQLite::SQLite(), dbs[i])
    df <- dbGetQuery(con, "SELECT * FROM tags")
    dbWriteTable(tag_db, "tags", df, append = TRUE)
    dbDisconnect(con)
  }
  tag_db <- dbConnect(RSQLite::SQLite(), out)
  df <- dbGetQuery(tag_db, "SELECT * FROM tags") %>%
    distinct()
  dbWriteTable(tag_db, "tags", df, overwrite = TRUE)
  dbDisconnect(tag_db)
  message("Created ", out)
}
  