#!/bin/bash -ue
mkdir vola
qiime longitudinal volatility 	  --m-metadata-file download/Sample_metadata/ecam-sample-metadata.tsv 	  --m-metadata-file download/Importing_data/shannon.qza 	  --p-default-metric shannon 	  --p-default-group-column delivery 	  --p-state-column month 	  --p-individual-id-column studyid 	  --o-visualization vola/volatility.qzv
