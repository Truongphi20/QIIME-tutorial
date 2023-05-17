#!/bin/bash -ue
mkdir rs
qiime feature-table filter-samples 	  --i-table table.qza 	  --p-min-frequency 1500 	  --o-filtered-table rs/sample-frequency-filtered-table-1500.qza

qiime feature-table filter-features 	  --i-table table.qza 	  --p-min-frequency 10 	  --o-filtered-table rs/feature-frequency-filtered-table-10.qza
