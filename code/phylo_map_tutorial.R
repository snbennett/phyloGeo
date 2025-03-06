#####################################################
# Script: phylo_map_tutorial.R
# Purpose: Demonstrate how to load a BEAST .trees file,
#          convert it to .trees.nex (if needed), parse metadata,
#          and visualize Markov jumps and timing on a map.
#####################################################

# -------------------------------
# 1. Install and load packages
# -------------------------------

required_packages <- c(
  "ape", "dplyr", "ggplot2", "ggtree", "grid", "here",
  "lubridate", "patchwork", "readr", "rnaturalearth",
  "rnaturalearthdata", "sf", "stringr", "tidyr", "treeio"
)

install_if_missing <- function(packages) {
  missing <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(missing)) {
    install.packages(missing, dependencies = TRUE)
  }
  invisible(lapply(packages, library, character.only = TRUE))
}

install_if_missing(required_packages)

#also from devtools
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
# Adjust these paths to your setup
beast_mcc_tree <- ape::read.nexus(here("data", "input", "MCC_aligned_D1_sequences_V3.trees.nex"))
# beast_trees_file <- ape::read.nexus(here("data", "input", "aligned_D1_sequences_V3.trees"))
# beast_log_file <- read_tsv(here("data", "input", "aligned_D1_sequences_V3.log"), comment = "#")
beast_log_file <- read_tsv(here("data", "input", "BEAST_jump_history", "aligned_D1_sequences_V3.jumpHistory.log"), comment = "#")
metadata_file <- read_tsv(here("data", "input", "D1_sequences_metadata_R.tsv"))

# -------------------------------
# 5. Load and Process Metadata
# -------------------------------
# Rename columns to match expected names
metadata <- metadata_file %>%
  dplyr::rename(
    label = sample,
    latitude = latitude,
    longitude = longitude
  )
print(head(metadata))

# -------------------------------
# 6. Attach Metadata to the Tree and Plot the Tree
# -------------------------------
p <- ggtree(beast_mcc_tree, layout = "rectangular") %<+% metadata +
  geom_tiplab(aes(label = label), size = 2) +
  theme_tree()
print(p)

# -------------------------------
# 7. Markov Jump Data
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
# 7b. Merge Jump Summary with Geographic Coordinates (from metadata)
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
# 8. Plot the Map with Jumps
# -------------------------------
world <- ne_countries(scale = "medium", returnclass = "sf")

map_plot <- ggplot(data = world) +
  geom_sf(fill = "gray90", color = "black") +
  coord_sf(xlim = c(-80, 0), ylim = c(-60, 20)) +
  geom_curve(
    data = jump_data,
    aes(
      x = origin_lon, y = origin_lat,
      xend = dest_lon, yend = dest_lat,
      size = jump_count, alpha = jump_support
    ),
    arrow = arrow(length = unit(0.2, "cm")),
    curvature = 0.2,
    color = "blue"
  ) +
  scale_size_continuous(range = c(0.5, 2)) +
  theme_minimal() +
  labs(
    title = "Geographic History of DENV‑1 (Markov Jumps)",
    x = "Longitude", y = "Latitude",
    size = "Number of Jumps", alpha = "Support"
  )
print(map_plot)

# -------------------------------
# 8.b. Get the Dates and Build time_data from Metadata
# -------------------------------

# use the perl script collect_times in the code/perl directory run the following script
source(here("code","collect_times.R"))

#read in that output file
jumps <- read_tsv(output_file) 

#####################################################
# Section: Build time_data from BEAST log jump output
# Purpose: Extract raw jump times from beast_log and build 
#          the time_data data frame with columns:
#          lineage_id, start_time, jump_time, end_time, jump_support.
#####################################################

# We assume that beast_log (from the BEAST log file) is already loaded.
# Add a new column "sample_time" from the "age(root)" column.
jump_columns <- beast_log %>%
  select(`age(root)`, starts_with("country.rates.")) %>%
  mutate(sample_time = `age(root)`) %>% View()

# Pivot the jump rate columns into long format and add origin/destination.
jump_long <- jump_columns %>%
  pivot_longer(
    cols = -c(`age(root)`, sample_time),
    names_to = "transition",
    values_to = "rate"
  ) %>%
  mutate(
    origin = str_extract(transition, "(?<=country\\.rates\\.)[^\\.]+"),
    destination = str_extract(transition, "(?<=\\.)[^\\.]+$")
  )

# Summarize raw jump times by grouping over the origin (lineage_id).
# For each origin state, we compute:
# - start_time: minimum sample_time
# - jump_time: median sample_time
# - end_time: maximum sample_time
# - jump_support: median jump rate
time_data <- jump_long %>%
  group_by(origin) %>%
  summarise(
    start_time   = min(sample_time, na.rm = TRUE),
    jump_time    = median(sample_time, na.rm = TRUE),
    end_time     = max(sample_time, na.rm = TRUE),
    jump_support = median(rate, na.rm = TRUE),
    .groups      = "drop"
  ) %>%
  rename(lineage_id = origin)

print(time_data)

# -------------------------------
# 9. Time Plot of Jumps and Rewards using time_data
# -------------------------------
time_plot <- ggplot(time_data) +
  geom_vline(
    aes(xintercept = jump_time, alpha = jump_support),
    color = "red"
  ) +
  geom_segment(
    aes(x = start_time, xend = end_time,
        y = lineage_id, yend = lineage_id),
    size = 2, color = "darkgreen"
  ) +
  labs(
    title = "Timing of Markov Jumps and Rewards",
    x = "Time (Years)",
    y = "Lineage"
  ) +
  theme_classic()

print(time_plot)

# -------------------------------
# 10. Combine Final Plots
# -------------------------------
final_figure <- map_plot / time_plot +
  plot_annotation(
    title = "Phylogeographic Reconstruction of DENV‑1",
    subtitle = "Example with Markov Jumps & Rewards"
  )
print(final_figure)

# Done!