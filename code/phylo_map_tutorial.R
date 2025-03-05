#####################################################
# Script: phylo_map_tutorial.R
# Purpose: Demonstrate how to load a BEAST .trees file,
#          convert it to .trees.nex, parse metadata,
#          and visualize Markov jumps on a map.
#####################################################

# -------------------------------
# 1. Install and load packages
# -------------------------------
required_packages <- c("ggplot2", "ape", "dplyr", "sf",
                       "rnaturalearth", "rnaturalearthdata",
                       "ggtree", "treeio", "patchwork",
                       "readr")

install_if_missing <- function(packages) {
  missing <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(missing)) {
    install.packages(missing, dependencies = TRUE)
  }
  invisible(lapply(packages, library, character.only = TRUE))
}
install_if_missing(required_packages)

# -------------------------------
# 2. Define file paths
# -------------------------------
# Adjust these paths to your setup
beast_trees_file    <- "data/aligned_D1_sequences_V3.trees"  # We'll convert to .trees.nex
beast_log_file      <- "data/aligned_D1_sequences_V3.log"
metadata_file       <- "data/D1_sequences_metadata - BEAST.tsv"

# -------------------------------
# 3. Convert .trees to .trees.nex
# -------------------------------
# We'll read the .trees file as plain text and wrap it in Nexus formatting if needed.
# Some workflows require a simple rename + small format tweak. The code below is
# a placeholder. Adjust as needed if your .trees file already has NEXUS headers.

convert_trees_to_nex <- function(input_file, output_file) {
  # Read lines
  lines <- readLines(input_file)
  
  # Check if it has a #NEXUS header. If not, we'll add one.
  # A minimal NEXUS file might need something like this:
  if(!grepl("#NEXUS", lines[1], ignore.case = TRUE)) {
    header <- c("#NEXUS",
                "Begin trees;",
                "   Translate")
    # For a typical BEAST .trees file, you might need to parse the 'Translate' block
    # or ensure the file has it. Below is a placeholder for minimal compliance.
    # If your file already has the 'Translate' block, skip this insertion.
    # We can also just wrap the entire file after we add #NEXUS lines.
    
    # In a minimal approach, we'll just add the #NEXUS and 'Begin trees;' lines:
    lines <- c(header, lines, "End;")
  }
  
  # Write out the new .trees.nex file
  writeLines(lines, con = output_file)
}

# We'll create a new file with .trees.nex extension
beast_trees_nex <- sub(".trees$", ".trees.nex", beast_trees_file)
convert_trees_to_nex(beast_trees_file, beast_trees_nex)

# -------------------------------
# 4. Load the MCC or posterior trees
# -------------------------------
library(ape)
library(treeio)

# If you have an MCC tree, it might be inside the .tre file (aligned_D1_sequences_V3.tre).
# If you want to read a posterior set of trees from .trees.nex, you can do something like this:
# Posterior trees:
posterior_trees <- read.nexus(beast_trees_nex)
# For large posterior sets, you might want to read a subset or an MCC summary.

# Example: If you have an MCC tree in "aligned_D1_sequences_V3.tre"
# mcc_tree <- read.nexus("data/aligned_D1_sequences_V3.tre")

# For demonstration, let's assume we want to visualize the first tree in the posterior:
one_tree <- posterior_trees[[1]]

# -------------------------------
# 5. Load metadata
# -------------------------------
library(readr)

# The metadata is in TSV format, so we use read_tsv
metadata <- read_tsv(metadata_file) %>%
  # rename columns to match typical usage
  dplyr::rename(label = Trait,  # or whichever column holds your tip labels
                latitude = Lat, # adjust to match your file
                longitude = Long)  # adjust to match your file

# Inspect the metadata
head(metadata)

# -------------------------------
# 6. Attach metadata to the tree
# -------------------------------
# We'll use ggtree for a quick plot. If you have many tips, you might want to subset.
library(ggtree)

p <- ggtree(one_tree, layout = "rectangular") +
  geom_tiplab(size = 2)

# We can merge metadata by matching tip labels if needed:
# p <- ggtree(one_tree) %<+% metadata + geom_tiplab(aes(label = label), size = 2)

# Print the basic tree
print(p)

# -------------------------------
# 7. Example Markov jump data
# -------------------------------
# Typically, you'd parse the .log or .country.rates.log for BSSVS transitions.
# For demonstration, let's assume we have a CSV of jump events or we derive them
# from the logs. We'll create a dummy data frame:

jump_data <- data.frame(
  origin_lat = c(-1.28, 0.52),
  origin_lon = c(36.82, 37.46),
  dest_lat   = c(-3.98, 0.50),
  dest_lon   = c(39.72, 34.45),
  jump_count = c(5, 2),
  jump_support = c(0.8, 0.6),
  stringsAsFactors = FALSE
)

# -------------------------------
# 8. Plot the map with jumps
# -------------------------------
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(ggplot2)

# Load a basemap (e.g., Africa, or global)
world <- ne_countries(scale = "medium", returnclass = "sf")

map_plot <- ggplot(data = world) +
  geom_sf(fill = "gray90", color = "black") +
  coord_sf(xlim = c(-20, 60), ylim = c(-40, 40)) +  # adjust as needed
  geom_curve(data = jump_data,
             aes(x = origin_lon, y = origin_lat,
                 xend = dest_lon, yend = dest_lat,
                 size = jump_count, alpha = jump_support),
             arrow = arrow(length = unit(0.2, "cm")),
             curvature = 0.2, color = "blue") +
  scale_size_continuous(range = c(0.5, 2)) +
  theme_minimal() +
  labs(title = "Geographic History of DENV-1 (Markov Jumps)",
       x = "Longitude", y = "Latitude",
       size = "Number of Jumps", alpha = "Support")

print(map_plot)

# -------------------------------
# 9. Time plot of jumps and rewards
# -------------------------------
# If you parse the actual times from the .log or posterior trees, you can create a time-based plot.
# Below is a dummy example:
time_data <- data.frame(
  jump_time = c(2015.2, 2016.7),
  jump_support = c(0.8, 0.6),
  start_time = c(2014.5, 2016.0),
  end_time   = c(2015.2, 2016.7),
  lineage_id = c("LineageA", "LineageB")
)

time_plot <- ggplot(time_data) +
  # Vertical lines at jump_time
  geom_vline(aes(xintercept = jump_time, alpha = jump_support),
             color = "red") +
  # Horizontal segments for reward times
  geom_segment(aes(x = start_time, xend = end_time,
                   y = lineage_id, yend = lineage_id),
               size = 2, color = "darkgreen") +
  labs(title = "Timing of Markov Jumps and Rewards",
       x = "Time (Years)", y = "Lineage") +
  theme_classic()

print(time_plot)

# -------------------------------
# 10. Combine final plots
# -------------------------------
library(patchwork)

final_figure <- map_plot / time_plot +
  plot_annotation(title = "Phylogeographic Reconstruction of DENV-1",
                  subtitle = "Example with Markov Jumps & Rewards")

print(final_figure)

# Done!
#####################################################