#phyDiscrete2.R

# Function to check and install missing packages
install_if_missing <- function(packages) {
  missing <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(missing)) {
    install.packages(missing, dependencies = TRUE)
  }
  invisible(lapply(packages, library, character.only = TRUE))
}

# Required packages
required_packages <- c("ggplot2", "ape", "dplyr", "maps", "BiocManager", "here", "rnaturalearth", "rnaturalearthdata", "sf", "ggtree")
install_if_missing(required_packages)

# Fix ggtree installation if needed
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install("ggtree", force = TRUE)
library(ggtree)

# Load additional necessary libraries
library(rnaturalearth)
library(rnaturalearthdata)
library(sf)
library(ggplot2)
library(ape)
library(dplyr)
library(maps)

# Define file paths
tree_file <- here("data/input/MCC_aligned_D1_sequeneces_V3.trees.nex")
metadata_file <- here("data/input/metadata_Latitude_longitude.csv")

# Read the MCC tree
tree <- read.nexus(tree_file)

# Read metadata containing tip locations
metadata <- read.csv(metadata_file, stringsAsFactors = FALSE)

# Standardize column names for latitude and longitude
metadata <- metadata %>%
  rename(latitude = Latitud, longitude = Longitud)

# Ensure metadata has the required columns
if (!all(c("Trait", "latitude", "longitude", "country") %in% colnames(metadata))) {
  stop("Metadata file must contain 'Trait' (tip_label), 'latitude', 'longitude', and 'country' columns.")
}

# Load South America map data
south_america <- map_data("world") %>%
  filter(region %in% c("Argentina", "Brazil", "Chile", "Colombia", "Ecuador",
                       "Paraguay", "Peru", "Uruguay", "Venezuela", "Bolivia",
                       "Guyana", "Suriname", "French Guiana"))

# Load country centroids from rnaturalearth
world_data <- ne_countries(scale = "medium", returnclass = "sf")

# Extract centroids from country polygons
country_centroids <- world_data %>%
  mutate(centroid = sf::st_centroid(geometry)) %>%
  cbind(sf::st_coordinates(.$centroid)) %>%
  dplyr::select(country = admin, latitude = Y, longitude = X)

# Function to fill missing lat/lon with country centroid
fill_missing_coordinates <- function(metadata, country_centroids) {
  metadata <- metadata %>%
    left_join(country_centroids, by = "country") %>%
    mutate(
      latitude = ifelse(is.na(latitude.x), latitude.y, latitude.x),
      longitude = ifelse(is.na(longitude.x), longitude.y, longitude.x)
    ) %>%
    select(Trait, latitude, longitude, country)
  return(metadata)
}

# Fill missing coordinates
metadata <- fill_missing_coordinates(metadata, country_centroids)

# Merge tree tip labels with metadata
trait_data <- metadata %>%
  rename(label = Trait)  # Match tip labels with tree

# Attach metadata to tree
p <- ggtree(tree, layout = "rectangular") %<+% trait_data +  
  geom_tiplab(aes(label = label), size = 3) +
  theme_tree()

# Extract node positions from tree
tree_df <- as.data.frame(tree$edge)
colnames(tree_df) <- c("parent", "child")

# Ensure 'child' column is character type to match 'label'
tree_df$child <- as.character(tree_df$child)

# Merge node positions with tip locations
tree_df <- tree_df %>%
  left_join(trait_data, by = c("child" = "label")) %>%
  filter(!is.na(latitude) & !is.na(longitude))  # Remove missing locations

# Infer ancestor locations (simple median lat/lon approach)
ancestor_locs <- tree_df %>%
  group_by(parent) %>%
  summarize(latitude = median(latitude, na.rm = TRUE),
            longitude = median(longitude, na.rm = TRUE))

# Merge ancestor locations back to tree_df
tree_df <- tree_df %>%
  left_join(ancestor_locs, by = c("parent" = "parent"))

# Map Phylogeographic Tree Over South America
phylo_map <- ggplot() +
  geom_polygon(data = south_america, aes(x = long, y = lat, group = group), 
               fill = "gray80", color = "black") +
  geom_segment(data = tree_df, 
               aes(x = longitude.y, y = latitude.y, xend = longitude.x, yend = latitude.x),
               arrow = arrow(length = unit(0.15, "inches")), color = "blue", alpha = 0.7) + 
  geom_point(data = trait_data, aes(x = longitude, y = latitude), size = 3, color = "red") +
  theme_minimal() +
  labs(title = "Phylogeographic Reconstruction of Discrete Traits in South America")

# Display plots
print(p)  # Tree plot
print(phylo_map)  # Phylogeographic map
