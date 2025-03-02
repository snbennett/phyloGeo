#phylogenyExample_ape_phytools.R

# --- Load Required Packages ---
# Install packages if necessary:
if (!requireNamespace("ape", quietly = TRUE)) install.packages("ape")
if (!requireNamespace("phytools", quietly = TRUE)) install.packages("phytools")

library(ape)
library(phytools)

# --- Set Reproducibility ---
set.seed(42)

# --- 1. Generate a Random Phylogenetic Tree ---
tree <- rtree(10)  # A tree with 10 tips

# --- 2. Define a Helper Function to Get Descendants ---
# This function returns all descendant nodes of a given node (excluding the node itself)
getDescendants <- function(tree, node) {
  children <- tree$edge[tree$edge[,1] == node, 2]
  if (length(children) == 0) return(integer(0))
  out <- children
  for (child in children) {
    out <- c(out, getDescendants(tree, child))
  }
  return(out)
}

# --- 3. Define Clades by Their Base Nodes ---
# (You can inspect node numbers using plot(tree) or functions like nodelabels())
node_clade1 <- 12  # Base node for clade 1
node_clade2 <- 14  # Base node for clade 2

# --- 4. Determine Descendant Nodes for Coloring (Excluding the Clade Base) ---
# This ensures that the branch leading into the clade remains black.
desc1 <- getDescendants(tree, node_clade1)  # All nodes descending from clade1 (excluding node 12)
desc2 <- getDescendants(tree, node_clade2)  # All nodes descending from clade2 (excluding node 14)

# --- 5. Remove Overlap if Clade2 is Nested Within Clade1 ---
# Remove clade2's base and its descendants from clade1 so that the branch leading to clade2 remains black.
desc1 <- setdiff(desc1, c(node_clade2, getDescendants(tree, node_clade2)))

# --- 6. Map Edges to Colors ---
# For each edge in the full tree, assign a color based on whether its child node falls in a clade.
# Default color is black. Edges where the child node is in desc1 are colored blue;
# edges where the child node is in desc2 are colored red.
edge_colors <- rep("black", nrow(tree$edge))
edge_colors[tree$edge[,2] %in% desc1] <- "blue"
edge_colors[tree$edge[,2] %in% desc2] <- "red"

# --- 7. Plot the Phylogenetic Tree Using ape ---
plot(tree, edge.color = edge_colors, edge.width = 2, cex = 1.2)
# Add tip labels
tiplabels(tree$tip.label, adj = c(0.5, -0.5), frame = "none", col = "black", cex = 1)

