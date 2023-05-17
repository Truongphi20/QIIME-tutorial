#!/bin/bash -ue
mkdir rs
qiime feature-table filter-features 	  --i-table table.qza	  --p-min-samples 2 	  --o-filtered-table rs/sample-contingency-filtered-table.qza

qiime feature-table filter-samples 	  --i-table table.qza 	  --p-min-features 10 	  --o-filtered-table rs/feature-contingency-filtered-table.qza
