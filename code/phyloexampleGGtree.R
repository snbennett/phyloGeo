# --- Installation & Loading Packages ---
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
if (!requireNamespace("ape", quietly = TRUE)) install.packages("ape")
if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")
BiocManager::install("ggtree", force = TRUE)

library(ape)
library(ggtree)
library(ggplot2)
library(dplyr)

# --- Reproducibility ---
set.seed(42)

# --- 1. Generate a Random Phylogenetic Tree ---
tree <- rtree(10)

# --- 2. Helper Function to Get Descendants ---
# Returns all descendant nodes of a given node (excluding the node itself)
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
# (Inspect node numbers with: ggtree(tree) + geom_text(aes(label=node)))
node_clade1 <- 12  # base node for clade 1
node_clade2 <- 14  # base node for clade 2

# --- 4. Determine Descendant Nodes for Coloring (excluding the clade base) ---
desc1 <- getDescendants(tree, node_clade1)  # descendants of clade1 (node 12 not included)
desc2 <- getDescendants(tree, node_clade2)  # descendants of clade2 (node 14 not included)

# --- 5. Remove Overlap if Clade2 is Nested Within Clade1 ---
# This prevents the branch leading to clade2 from being colored as part of clade1.
desc1 <- setdiff(desc1, c(node_clade2, getDescendants(tree, node_clade2)))

# --- 6. Map Edges to Color Groups ---
# Create a data frame that assigns a group (and thus color) to each edge based on its child node.
edges_df <- data.frame(
  parent = tree$edge[,1],
  child  = tree$edge[,2],
  group  = 0  # default group: not part of any highlighted clade (will be black)
)
edges_df$group[edges_df$child %in% desc1] <- 1  # assign blue to clade1 edges
edges_df$group[edges_df$child %in% desc2] <- 2  # assign red to clade2 edges

# --- 7. Create ggtree Object ---
gtree_obj <- ggtree(tree)
# Verify that ggtree_obj was created:
if (!exists("gtree_obj")) stop("gtree_obj was not created. Please check your ggtree() call.")

# --- 8. Merge Edge Info Directly into ggtree_obj Data ---
# Instead of using %<+%, assign the merged data to the ggtree object.
gtree_obj$data <- left_join(gtree_obj$data, edges_df, by = c("node" = "child"))

# --- 9. Plot the Tree with Custom Coloring ---
p <- ggtree_obj +
  geom_tree(aes(color = factor(group)), size = 1.2) +
  scale_color_manual(
    values = c("0" = "black",  # not in any highlighted clade
               "1" = "blue",   # clade1 edges
               "2" = "red")    # clade2 edges
  ) +
  geom_tiplab(size = 4, align = TRUE) +
  theme_tree() +
  ggtitle("Phylogenetic Tree with Colored Monophyletic Clades")

# --- 10. Display the Plot ---
print(p)
