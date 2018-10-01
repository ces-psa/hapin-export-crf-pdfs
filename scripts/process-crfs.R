#------------------------------------------------------------------------------*
# Process CRFs pdf pack from the Emory RedCap project
#------------------------------------------------------------------------------*


#------------------------------------------------------------------------------*
# Prepare script environment ----
#------------------------------------------------------------------------------*
# See https://github.com/ropensci/pdftools for special requirements
#------------------------------------------------------------------------------*

# Load used packages
library(package = "tidyverse") # work with dataframes
library(package = "pdftools")  # read pdf contents using the poppler library




#------------------------------------------------------------------------------*
# Read in pdf ----
#------------------------------------------------------------------------------*

# get most recent file
gt_emory_crfs_file <- list.files(
  path = "data/crfs", pattern = "MainSt.+pdf", full.names = TRUE
) %>%
  data_frame(
    file = .,
    export_time = file %>%
      gsub(".+?_([-0-9_]+).csv", "\\1", .) %>%
      lubridate::ymd(tz = "America/New_York")
  ) %>%
  slice(which.max(export_time))


# Read all pages
all_crfs <- pdf_text(pdf = gt_emory_crfs_file$file)


# Work on a data.frame
crfs_df <- data_frame(
  pages = all_crfs
) %>%
  # Process the text
  mutate(
    page_num = seq(from = 1, to = n()),
    page_text = map_chr(
      pages,
      ~ .x %>%
        gsub(
          pattern = " *Confidential *\n[^\n]+\n *Page *[0-9]+ *of *[0-9]+\n +",
          replacement = "",
          x = .
        )
    ),
    crf_name = map_chr(
      page_text,
      ~.x %>%
        strsplit(split = "\n") %>%
        unlist() %>%
        magrittr::extract2(1) %>%
        gsub(" *Confidential *", "", .)
    ) %>%
      if_else(. == "", NA_character_, .) %>%
      zoo::na.locf.default()
  ) %>%
  select(page_num, crf_name, page_text, pages)


# Get page ranges
crfs_pages <- crfs_df %>%
  group_by(crf_name) %>%
  summarize(
    first_page = min(page_num),
    last_page = max(page_num)
  ) %>%
  ungroup() %>%
  arrange(first_page) %>%
  mutate(
    order = seq(from = 1, to = n()) %>%
      stringr::str_pad(width = 2, side = "left", pad = "0")
  )
  
  
  
  
#------------------------------------------------------------------------------*
# Write indivicual crfs ----
#------------------------------------------------------------------------------*
# Needs pdftk to makage the pdfs through the command line
# https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/
#------------------------------------------------------------------------------*

# Generate export instructions
export_isntructions <- crfs_pages %>%
  mutate(
    instruction = paste(
      paste0("pdftk A=\"", gt_emory_crfs_file$file, "\""),
      paste0("cat A", first_page, "-", last_page),
      "output",
      paste0(
        "\"output/", order, "_",
        gt_emory_crfs_file$export_time, "_", crf_name, ".pdf\""
      )
    )
  )




# End of script
