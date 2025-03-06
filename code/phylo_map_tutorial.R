#####################################################
# Script: phylo_map_tutorial.R
# Purpose: Demonstrate how to load a BEAST .trees file,
#          convert it to .trees.nex (if needed), parse metadata,
#          extract Markov jump data, and visualize 
#          phylogenetic and geographic reconstructions.
#####################################################

# -------------------------------
# 1. Install and load packages
# -------------------------------
required_packages <- c(
  "ape", "ggplot2", "ggtree", "grid", "here",
  "lubridate", "patchwork", "readr", "rnaturalearth",
  "rnaturalearthdata", "sf", "stringr", "tidyverse", "treeio"
)

install_if_missing <- function(packages) {
  missing <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(missing)) {
    install.packages(missing, dependencies = TRUE)
  }
  invisible(lapply(packages, library, character.only = TRUE))
}
install_if_missing(required_packages)

# Install MarkovJumpR from GitHub if needed
if (!requireNamespace("MarkovJumpR", quietly = TRUE)) {
  if (!requireNamespace("devtools", quietly = TRUE)) {
    install.packages("devtools")
  }
  devtools::install_github("beast-dev/MarkovJumpR")
}
library(MarkovJumpR)

# -------------------------------
# 2. Define file paths and read files
# -------------------------------
beast_mcc_tree <- ape::read.nexus(here("data", "input", "MCC_aligned_D1_sequences_V3.trees.nex"))
beast_log_file <- read_tsv(here("data", "input", "aligned_D1_sequences_V3.log"), comment = "#")
metadata_file  <- read_tsv(here("data", "input", "D1_sequences_metadata_R.tsv"))

# -------------------------------
# 3. Load and Process Metadata
# -------------------------------
metadata <- metadata_file %>%
  dplyr::rename(
    label = sample,
    latitude = latitude,
    longitude = longitude
  )
print(head(metadata))

# -------------------------------
# 4. Attach Metadata to the Tree and Plot the Tree
# -------------------------------
tree_plot <- ggtree(beast_mcc_tree, layout = "rectangular") %<+% metadata +
  geom_tiplab(aes(label = label, color = country), size = 2) +
  scale_color_manual(values = country_colors) +
  theme_tree() +
  theme(legend.position = "none") + 
  ggtitle("Phylogenetic Tree Colored by Country")
print(tree_plot)

# -------------------------------
# 5. Markov Jump Data
# -------------------------------
# Assign beast_log_file to beast_log for clarity
beast_log <- beast_log_file

jump_columns <- beast_log %>%
  select(starts_with("country.rates."))

jump_long <- jump_columns %>%
  pivot_longer(
    cols = everything(),
    names_to = "transition",
    values_to = "rate"
  ) %>%
  mutate(
    origin = str_extract(transition, "(?<=country\\.rates\\.)[^\\.]+"),
    destination = str_extract(transition, "(?<=\\.)[^\\.]+$")
  )

jump_summary <- jump_long %>%
  group_by(origin, destination) %>%
  summarise(
    median_rate = median(rate, na.rm = TRUE),
    mean_rate = mean(rate, na.rm = TRUE),
    .groups = "drop"
  )
print(jump_summary)

# -------------------------------
# 6. Merge Jump Summary with Geographic Coordinates (from metadata)
# -------------------------------
location_coords <- metadata_file %>%
  distinct(country, .keep_all = TRUE) %>%
  select(country, latitude, longitude)

jump_data <- jump_summary %>%
  left_join(location_coords, by = c("origin" = "country")) %>%
  rename(origin_lat = latitude, origin_lon = longitude) %>%
  left_join(location_coords, by = c("destination" = "country"), suffix = c("", "_dest")) %>%
  rename(dest_lat = latitude, dest_lon = longitude) %>%
  mutate(
    jump_support = median_rate,
    jump_count = median_rate * 10
  )
print(jump_data)

# -------------------------------
# 7. Plot the Map with Jumps
# -------------------------------
world <- ne_countries(scale = "medium", returnclass = "sf")

map_plot <- ggplot(data = world) +
  geom_sf(fill = "gray90", color = "black") +
  coord_sf(xlim = c(-90, -30), ylim = c(-60, 20)) +
  geom_curve(
    data = jump_data,
    aes(
      x = origin_lon, y = origin_lat,
      xend = dest_lon, yend = dest_lat,
      size = jump_count, alpha = jump_support,
      color = origin
    ),
    arrow = arrow(length = unit(0.2, "cm")),
    curvature = 0.2
  ) +
  scale_size_continuous(range = c(0.5, 2)) +
  scale_color_manual(values = country_colors) +
  theme_minimal() +
  labs(
    title = "Geographic History of DENV‑1 (Markov Jumps)",
    x = "Longitude", y = "Latitude",
    size = "Number of Jumps", alpha = "Support"
  )
print(map_plot)

# -------------------------------
# 8. Combined Phylogeny & Map Colored by Country (Side-by-Side)
# -------------------------------
# Define manual color mapping for countries if not already defined.
country_colors <- c(
  "Argentina" = "#1f78b4",
  "Brazil" = "#33a02c",
  "Chile" = "#e31a1c",
  "Colombia" = "#ff7f00",
  "Ecuador" = "#6a3d9a",
  "Paraguay" = "#a6cee3",
  "Peru" = "#b2df8a",
  "Uruguay" = "#fb9a99",
  "Venezuela" = "#fdbf6f",
  "Bolivia" = "#cab2d6",
  "Guyana" = "#ffff99",
  "Suriname" = "#b15928",
  "French Guiana" = "#8dd3c7",
  "Other" = "grey50"
)

# Ensure location_coords is defined (from metadata_file)
location_coords <- metadata_file %>%
  distinct(country, .keep_all = TRUE) %>%
  select(country, latitude, longitude)

combined_figure <- tree_plot + map_plot +
  plot_annotation(
    title = "Phylogeographic Reconstruction of DENV‑1",
    subtitle = "Left: Phylogenetic Tree; Right: Geographic Map"
  )
print(combined_figure)

# EXTRA CREDIT HOMEWORK:
# The next step is to build raw time_data from jump history using 
# output from TaxaMarkovJumpHistoryAnalyzer found in Beast and plot as 
# in Nyathi et al 2024 Nature Comms.