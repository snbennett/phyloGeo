# phyloDiscrete.R

# Function to check and install missing packages
install_if_missing <- function(packages) {
  missing <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(missing)) {
    install.packages(missing, dependencies = TRUE)
  }
  invisible(lapply(packages, library, character.only = TRUE))
}

# Required packages
required_packages <- c("ggplot2", "ape", "dplyr", "maps", "BiocManager", "here", "rnaturalearth", "rnaturalearthdata", "sf")
install_if_missing(required_packages)

# Fix ggtree installation if needed
BiocManager::install("ggtree", force = TRUE)
library(ggtree)

# Load additional necessary libraries
library(rnaturalearth)
library(rnaturalearthdata)
library(sf)

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

# Load country centroids from rnaturalearth
world_data <- ne_countries(scale = "medium", returnclass = "sf")

# Extract centroids from country polygons
country_centroids <- world_data %>%
  mutate(centroid = sf::st_centroid(geometry)) %>%
  cbind(sf::st_coordinates(.$centroid)) %>%  # Extract latitude and longitude
  dplyr::select(country = admin, latitude = Y, longitude = X)  # Keep only relevant columns

# Function to fill missing lat/lon with country centroid
fill_missing_coordinates <- function(metadata, country_centroids) {
  metadata <- metadata %>%
    left_join(country_centroids, by = "country") %>%
    mutate(
      latitude = ifelse(is.na(latitude.x), latitude.y, latitude.x),
      longitude = ifelse(is.na(longitude.x), longitude.y, longitude.x)
    ) %>%
    select(Trait, latitude, longitude, country)  # Keep only relevant columns
  
  return(metadata)
}
# Fill missing coordinates
metadata <- fill_missing_coordinates(metadata, country_centroids)

# Merge tree tip labels with metadata
trait_data <- data.frame(Trait = tree$tip.label) %>%
  left_join(metadata, by = "Trait")

# Ensure all tree tips have corresponding metadata
missing_tips <- setdiff(tree$tip.label, trait_data$Trait)
if (length(missing_tips) > 0) {
  warning(paste("The following tree tips have no matching metadata and will be ignored:", paste(missing_tips, collapse = ", ")))
}

# Plot the phylogenetic tree with discrete location traits
p <- ggtree(tree, layout = "rectangular") %>%
  ggtree::`%<+%`(trait_data) +  # Attach metadata to tree
  geom_tiplab(aes(label = label), size = 3) +  # Use the correct column name for tip labels
  theme_tree()

# Load a base map
world_map <- map_data("world")

# Plot geographic distribution of sampled taxa
map_plot <- ggplot() +
  geom_polygon(data = world_map, aes(x = long, y = lat, group = group), fill = "gray80", color = "black") +
  geom_point(data = trait_data, aes(x = longitude, y = latitude, color = Trait), size = 3) +
  theme_minimal() +
  labs(title = "Geographic Distribution of Discrete Traits") +
  theme(legend.position = "none")  # Suppress legend

# Display plots
print(p)
print(map_plot)