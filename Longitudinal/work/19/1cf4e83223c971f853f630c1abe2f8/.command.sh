#!/bin/bash -ue
mkdir diff diff/vis
qiime longitudinal pairwise-differences 	  --m-metadata-file download/Sample_metadata/ecam-sample-metadata.tsv 	  --m-metadata-file download/Importing_data/shannon.qza 	  --p-metric shannon 	  --p-group-column delivery 	  --p-state-column month 	  --p-state-1 0 	  --p-state-2 12 	  --p-individual-id-column studyid 	  --p-replicate-handling random 	  --o-visualization diff/pairwise-differences.qzv
