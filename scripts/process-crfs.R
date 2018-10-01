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




# End of script
