# phyDiscrete2.R
# Purpose: Load a BEAST MCC tree and tip metadata, fill in missing coordinates,
#          merge tree tip labels with metadata, infer ancestral positions,
#          and map the phylogeographic reconstruction over South America.
#
# 1. Install and load packages -----------------------------------------------
install_if_missing <- function(packages) {
  missing_pkgs <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(missing_pkgs) > 0) {
    install.packages(missing_pkgs, dependencies = TRUE)
  }
  invisible(lapply(packages, library, character.only = TRUE))
}

required_packages <- c(
  "ape", "dplyr", "ggplot2", "ggtree", "here",
  "maps", "rnaturalearth", "rnaturalearthdata", "sf", "BiocManager"
)
install_if_missing(required_packages)

# Ensure ggtree is installed from Bioconductor
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install("ggtree", force = TRUE)
library(ggtree)

# 2. Define file paths --------------------------------------------------------
tree_file     <- here("data", "input", "MCC_aligned_D1_sequeneces_V3.trees.nex")
metadata_file <- here("data", "input", "D1_sequences_metadata_R.tsv")

# 3. Load tree and metadata --------------------------------------------------
tree <- read.nexus(tree_file)
metadata <- readr::read_tsv(metadata_file)

# 4. Fill missing coordinates using country centroids ------------------------
world_data <- ne_countries(scale = "medium", returnclass = "sf")
country_centroids <- world_data %>%
  mutate(centroid = sf::st_centroid(geometry)) %>%
  cbind(sf::st_coordinates(.$centroid)) %>%
  dplyr::select(country = admin, latitude = Y, longitude = X)

fill_missing_coordinates <- function(md, centroids) {
  md %>%
    left_join(centroids, by = "country") %>%
    mutate(
      latitude = ifelse(is.na(latitude.x), latitude.y, latitude.x),
      longitude = ifelse(is.na(longitude.x), longitude.y, longitude.x)
    ) %>%
    select(sample, latitude, longitude, country)
}

metadata <- fill_missing_coordinates(metadata, country_centroids)

# Rename tip label column to match the tree
trait_data <- metadata %>%
  rename(label = sample)

# 5. Plot the MCC tree with tip labels ---------------------------------------
p <- ggtree(tree, layout = "rectangular") %<+% trait_data +
  geom_tiplab(aes(label = label), size = 3) +
  theme_tree()

print(p)

# 6. Extract tip positions from tree and merge with metadata -----------------
# Convert the edge matrix to a data frame
tree_df <- as.data.frame(tree$edge)
colnames(tree_df) <- c("parent", "child")

# In a phylo object, tips are numbered 1:Ntip(tree)
num_tips <- length(tree$tip.label)
tree_df <- tree_df %>%
  mutate(child_label = ifelse(child <= num_tips, tree$tip.label[child], NA)) %>%
  filter(!is.na(child_label)) %>%
  left_join(trait_data, by = c("child_label" = "label"))

# 7. Infer ancestor locations (median of child tip coordinates) ----------------
ancestor_locs <- tree_df %>%
  group_by(parent) %>%
  summarize(
    latitude = median(latitude, na.rm = TRUE),
    longitude = median(longitude, na.rm = TRUE)
  )

# Merge the ancestor locations back to tree_df
tree_df <- tree_df %>%
  left_join(ancestor_locs, by = "parent")

# 8. Prepare South America map data ------------------------------------------
south_america <- map_data("world") %>%
  filter(region %in% c(
    "Argentina", "Brazil", "Chile", "Colombia", "Ecuador",
    "Paraguay", "Peru", "Uruguay", "Venezuela", "Bolivia",
    "Guyana", "Suriname", "French Guiana"
  ))

# 9. Build the phylogeographic map -------------------------------------------
phylo_map <- ggplot() +
  geom_polygon(
    data = south_america,
    aes(x = long, y = lat, group = group),
    fill = "gray80",
    color = "black"
  ) +
  geom_segment(
    data = tree_df,
    aes(x = longitude.y, y = latitude.y, xend = longitude.x, yend = latitude.x),
    arrow = arrow(length = unit(0.15, "inches")),
    color = "blue",
    alpha = 0.7
  ) +
  geom_point(
    data = trait_data,
    aes(x = longitude, y = latitude),
    size = 3,
    color = "red"
  ) +
  theme_minimal() +
  labs(
    title = "Phylogeographic Reconstruction of Discrete Traits in South America",
    x = "Longitude",
    y = "Latitude"
  )

print(phylo_map)
