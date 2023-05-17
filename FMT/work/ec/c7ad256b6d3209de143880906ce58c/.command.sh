#!/bin/bash -ue
mkdir seq_qc
qiime demux summarize 	  --i-data fmt-tutorial-demux-1-10p.qza	  --o-visualization seq_qc/demux-summary-1.qzv
qiime demux summarize 	  --i-data fmt-tutorial-demux-2-10p.qza	  --o-visualization seq_qc/demux-summary-2.qzv
