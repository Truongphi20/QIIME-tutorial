#!/bin/bash -ue
mkdir pair_dist
qiime longitudinal pairwise-distances 	  --i-distance-matrix download/Importing_data/unweighted_unifrac_distance_matrix.qza 	  --m-metadata-file download/Sample_metadata/ecam-sample-metadata.tsv 	  --p-group-column delivery 	  --p-state-column month 	  --p-state-1 0 	  --p-state-2 12 	  --p-individual-id-column studyid 	  --p-replicate-handling random 	  --o-visualization pair_dist/pairwise-distances.qzv
