#!/bin/bash -ue
mkdir linear
qiime longitudinal linear-mixed-effects 	  --m-metadata-file download/Sample_metadata/ecam-sample-metadata.tsv 	  --m-metadata-file download/Importing_data/shannon.qza 	  --p-metric shannon 	  --p-group-columns delivery,diet,sex 	  --p-state-column month 	  --p-individual-id-column studyid 	  --o-visualization linear/linear-mixed-effects.qzv
