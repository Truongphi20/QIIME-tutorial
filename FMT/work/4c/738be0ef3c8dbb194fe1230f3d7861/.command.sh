#!/bin/bash -ue
qiime dada2 denoise-single 	  --p-trim-left 13 	  --p-trunc-len 150 	  --i-demultiplexed-seqs fmt-tutorial-demux-1-10p.qza 	  --o-representative-sequences rep-seqs-1.qza 	  --o-table table-1.qza 	  --o-denoising-stats stats-1.qza

qiime dada2 denoise-single 	  --p-trim-left 13 	  --p-trunc-len 150 	  --i-demultiplexed-seqs fmt-tutorial-demux-2-10p.qza 	  --o-representative-sequences rep-seqs-2.qza 	  --o-table table-2.qza 	  --o-denoising-stats stats-2.qza
