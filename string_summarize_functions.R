jaccard <- function(a, b) {
	split_a <- unlist(strsplit(a, ","))
	split_b <- unlist(strsplit(b, ","))
    intersection = length(intersect(split_a, split_b))
    union = length(split_a) + length(split_b) - intersection
    return (intersection/union)
}

# jaccard(str_res_list_vitreous[["D_vs_ND"]]$proteinIDs[1], str_res_list_vitreous[["D_vs_ND"]]$proteinIDs[2])

make_jaccard_matrix <- function(string_result){
	res_mat <- matrix(1, nr = nrow(string_result), nc = nrow(string_result))
	rownames(res_mat) <- string_result$termID
	colnames(res_mat) <- string_result$termID
	for(i in seq(1, nrow(string_result))){
		for(j in seq(1, nrow(string_result))){
			if(i > j){
				res_mat[i, j] <- jaccard(string_result$proteinIDs[i], string_result$proteinIDs[j])
			}
		}
	}
	tm <- t(res_mat)
	res_mat[upper.tri(res_mat)] <- tm[upper.tri(tm)]
	return(res_mat)
}


# jaccard_matrix <- make_jaccard_matrix(str_res_list[[6]] %>% filter(category == "GO Process"))
		
cluster_jaccard_matrix <- function(jaccard_matrix, cut_height = 0.9){
	distance_mat <- as.dist(1 - jaccard_matrix)
	hc <- hclust(distance_mat, method = "complete")
	ct <- cutree(hc, h = cut_height)
	return(ct)
}

# tree <- cluster_jaccard_matrix(jaccard_matrix)

select_top_categories <- function(tree, string_result){
	return(string_result %>%
		mutate(cluster = tree[termID]) %>%
		group_by(cluster) %>%
		slice_min(falseDiscoveryRate, n = 1, with_ties = FALSE) %>%
		ungroup() %>%
		select(-cluster))
}

# select_top_categories(tree, string_result)

reduce_string_results <- function(string_result, cut_height = 0.9){
	if(nrow(string_result) > 2){
		jaccard_matrix <- make_jaccard_matrix(string_result)
		tree <- cluster_jaccard_matrix(jaccard_matrix, cut_height = cut_height)
		return(select_top_categories(tree, string_result))
	} else {return(string_result)}
}
