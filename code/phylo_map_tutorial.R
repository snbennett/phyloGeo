#####################################################
# Script: phylo_map_tutorial.R
# Purpose: Demonstrate how to load a BEAST .trees file,
#          convert it to .trees.nex, parse metadata,
#          and visualize Markov jumps on a map.
#####################################################

# -------------------------------
# 1. Install and load packages
# -------------------------------
required_packages <- c("ape", "dplyr", "ggplot2", "ggtree", "grid", "here", "lubridate", "patchwork", 
                       "readr", "rnaturalearth", "rnaturalearthdata", "sf", "stringr", "tidyr", "treeio")

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
beast_mcc_tree      <- ape::read.nexus(here("data/input/MCC_aligned_D1_sequeneces_V3.trees.nex"))
beast_trees_file    <- ape::read.nexus(here("data/input/aligned_D1_sequeneces_V3.trees")) # original BEAST trees file
beast_log_file      <- read_tsv(here("data/input/aligned_D1_sequeneces_V3.log"), comment = "#")    # BEAST log file (if needed)
metadata_file       <- read_tsv(here("data/input/D1_sequences_metadata_R.tsv"))  # Metadata file (TSV)

# -------------------------------
# 3. Read in Files and Convert .trees to .trees.nex
# -------------------------------
# Read the BEAST trees file (as plain text) and convert it to Nexus format if necessary.
convert_trees_to_nex <- function(input_file, output_file) {
  # Read lines from the original .trees file
  lines <- readLines(input_file)
  
  # If the file does not start with a Nexus header, add one.
  if (!grepl("#NEXUS", lines[1], ignore.case = TRUE)) {
    header <- c("#NEXUS",
                "Begin trees;",
                "   Translate")
    # Append a minimal footer
    lines <- c(header, lines, "End;")
  }
  
  # Write out the new .trees.nex file
  writeLines(lines, con = output_file)
}

# Create the new .trees.nex filename by substituting the extension
beast_trees_nex <- sub(".trees$", ".trees.nex", beast_trees_file)
# convert_trees_to_nex(beast_trees_file, beast_trees_nex)

# -------------------------------
# 4. Load the BEAST Trees
# -------------------------------
# Read in the posterior trees from the newly created .trees.nex file
posterior_trees <-beast_trees_file # read.nexus(beast_trees_nex)
# For demonstration, we'll use the first tree in the set
one_tree <- posterior_trees[[1]]

# -------------------------------
# 5. Load Metadata
# -------------------------------
# Rename columns to match expected names (adjust as needed based on your file)
metadata <- metadata_file %>%
  dplyr::rename(label = sample,   # change 'Trait' to your tip label column name
                latitude = latitude,  # change 'Lat' if needed
                longitude = longitude)  # change 'Long' if needed

# Inspect the metadata to confirm successful reading
print(head(metadata))

# -------------------------------
# 6. Attach Metadata to the Tree and Plot the Tree
# -------------------------------
# Attach metadata to the tree using the %<+% operator from ggtree
p <- ggtree(beast_mcc_tree, layout = "rectangular") %<+% metadata +
  geom_tiplab(aes(label = label), size = 2)

# Print the tree with attached metadata
print(p)

# -------------------------------
# 7. Markov Jump Data
# -------------------------------
# We assume beast_log_file is already loaded.
# For clarity, assign it to beast_log:
beast_log <- beast_log_file

# Extract only the columns that contain country rate information.
# These columns should start with "country.rates."
jump_columns <- beast_log %>%
  select(starts_with("country.rates."))

# Pivot these columns to long format so each row corresponds to a transition rate
jump_long <- jump_columns %>%
  pivot_longer(
    cols = everything(),
    names_to = "transition",
    values_to = "rate"
  )

# Extract origin and destination from the transition name.
jump_long <- jump_long %>%
  mutate(
    origin = str_extract(transition, "(?<=country\\.rates\\.)[^\\.]+"),
    destination = str_extract(transition, "(?<=\\.)[^\\.]+$")
  )

# Summarize the jump rates (e.g., median and mean) for each origin-destination pair.
jump_summary <- jump_long %>%
  group_by(origin, destination) %>%
  summarise(
    median_rate = median(rate, na.rm = TRUE),
    mean_rate = mean(rate, na.rm = TRUE),
    .groups = "drop"
  )

print(jump_summary)

# -------------------------------
# 7b. Merge with Geographic Coordinates using metadata_file
# -------------------------------
# Create a unique lookup table for location coordinates based on country
location_coords <- metadata_file %>%
  distinct(country, .keep_all = TRUE) %>%
  select(country, latitude, longitude)

# Merge the jump summary (jump_summary) with the location coordinates:
jump_data <- jump_summary %>%
  left_join(location_coords, by = c("origin" = "country")) %>%
  rename(origin_lat = latitude, origin_lon = longitude) %>% 
  left_join(location_coords, by = c("destination" = "country"), suffix = c("", "_dest")) %>%
  rename(dest_lat = latitude, dest_lon = longitude) %>%
  # Optionally, create additional columns for plotting.
  mutate(
    jump_support = median_rate,       # using median_rate as a proxy for support
    jump_count   = median_rate * 10     # scale median_rate to derive a jump count
  )

print(jump_data)

# -------------------------------
# 8. Plot the Map with Jumps
# -------------------------------
# Load a world basemap
world <- ne_countries(scale = "medium", returnclass = "sf")

map_plot <- ggplot(data = world) +
  geom_sf(fill = "gray90", color = "black") +
  # Adjust the coordinate limits as needed (example here focuses on South America)
  coord_sf(xlim = c(-80, 0), ylim = c(-60, 20)) +
  geom_curve(data = jump_data,
             aes(x = origin_lon, y = origin_lat,
                 xend = dest_lon, yend = dest_lat,
                 size = jump_count, alpha = jump_support),
             arrow = arrow(length = unit(0.2, "cm")),
             curvature = 0.2, color = "blue") +
  scale_size_continuous(range = c(0.5, 2)) +
  theme_minimal() +
  labs(title = "Geographic History of DENV‑1 (Markov Jumps)",
       x = "Longitude", y = "Latitude",
       size = "Number of Jumps", alpha = "Support")

print(map_plot)

# -------------------------------
# 8.b. get the dates
# -------------------------------

library(dplyr)
library(lubridate)
library(ggplot2)

# Build the time_data data frame from the metadata_file.

metadata_file <- metadata_file %>%
  mutate(parsed_date = parse_date_time(date, orders = c("ymd", "ym", "y")))

# Group by 'country' (or change to province, city, etc.) and compute the
# earliest (start_date) and latest (end_date) sampling dates.
time_data <- metadata_file %>%
  group_by(country) %>%
  summarise(
    start_date = min(parsed_date, na.rm = TRUE),
    end_date   = max(parsed_date, na.rm = TRUE)
  ) %>%
  mutate(
    jump_date = start_date + (end_date - start_date) / 2,
    start_time = decimal_date(start_date),
    end_time   = decimal_date(end_date),
    jump_time  = decimal_date(jump_date),
    jump_support = 0.8,
    lineage_id = country
  ) %>%
  select(lineage_id, start_time, jump_time, end_time, jump_support)

print(time_data)

# -------------------------------
# 9. Time Plot of Jumps and Rewards using time_data
# -------------------------------
time_plot <- ggplot(time_data) +
  # Vertical line at the jump time (with alpha reflecting support)
  geom_vline(aes(xintercept = jump_time, alpha = jump_support),
             color = "red") +
  # Horizontal segment showing the duration from start_time to end_time for each lineage
  geom_segment(aes(x = start_time, xend = end_time,
                   y = lineage_id, yend = lineage_id),
               size = 2, color = "darkgreen") +
  labs(title = "Timing of Markov Jumps and Rewards",
       x = "Time (Years)", y = "Lineage") +
  theme_classic()

print(time_plot)

# -------------------------------
# 10. Combine Final Plots
# -------------------------------
library(patchwork)

final_figure <- map_plot / time_plot +
  plot_annotation(title = "Phylogeographic Reconstruction of DENV‑1",
                  subtitle = "Example with Markov Jumps & Rewards")

print(final_figure)

# Done!
#####################################################