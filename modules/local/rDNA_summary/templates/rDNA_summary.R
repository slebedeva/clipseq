#!/usr/bin/env Rscript

library(tidyverse)
library(ggridges)

# Keep backslashes and dollar signs out of this file: Nextflow templates treat them as escapes/placeholders
files <- list.files(path = ".",
           all.files = FALSE,
           full.names = TRUE,
           recursive = FALSE)
files <- files[endsWith(files, ".xl.CPMnorm.bedgraph")]

for (i in 1:length(files)){
  if (i == 1){
  df <- read.delim(files[i],
                       col.names = c("chr", "xlink_1", "xlink2", "count")) %>%
      mutate(count = abs(count),
             sample = str_remove(basename(files[i]), ".rDNA.xl.CPMnorm.bedgraph"))

  }

  else{
    df_2 <- read.delim(files[i],
                       col.names = c("chr", "xlink_1", "xlink2", "count")) %>%
      mutate(count = abs(count),
             sample = str_remove(basename(files[i]), ".rDNA.xl.CPMnorm.bedgraph"))

    df <- rbind(df, df_2)
  }
}


# Region boxes come from an optional BED (chr, start, end, name); rRNA rows shaded blue, spacers grey.
# Without a BED, draw a single grey background.
region_files <- list.files(path = ".")
region_files <- region_files[endsWith(region_files, ".bed")]

if (length(region_files) == 1) {
  regions <- read.delim(region_files[1], header = FALSE,
                        col.names = c("chr", "start", "end", "name")) %>%
    mutate(fill = ifelse(grepl("ribosomal RNA", name, fixed = TRUE), "#E4F3F5", "#DEDDDD"))
} else {
  regions <- data.frame(start = -Inf, end = Inf, fill = "#DEDDDD")
}

plot <- ggplot(df, aes(x = xlink_1, y = sample, weight = count)) +
  geom_rect(data = regions, inherit.aes = FALSE,
            aes(xmin = start, xmax = end, ymin = -Inf, ymax = Inf, fill = fill)) +
  scale_fill_identity() +
  geom_density_ridges(scale = 1, alpha = 0.8, bandwidth = 20) +
  theme_minimal() +
  ylab("Sample") +
  xlab("Crosslink position")


ggsave("rDNA_summary.png",
       plot = plot,
       dpi = 450,
       units = "cm")

writeLines(c(
  '"${task.process}":',
  paste0("    r-tidyverse: ", as.character(packageVersion("tidyverse"))),
  paste0("    r-ggridges: ", as.character(packageVersion("ggridges")))
), "versions.yml")
