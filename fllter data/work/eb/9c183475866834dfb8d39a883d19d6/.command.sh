#!/bin/bash -ue
echo SampleID > samples-to-keep.tsv
echo L1S8 >> samples-to-keep.tsv
echo L1S105 >> samples-to-keep.tsv

qiime feature-table filter-samples 	  --i-table table.qza 	  --m-metadata-file samples-to-keep.tsv 	  --o-filtered-table id-filtered-table.qza
