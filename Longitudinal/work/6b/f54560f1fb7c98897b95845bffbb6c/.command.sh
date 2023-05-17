#!/bin/bash -ue
mkdir download | /home/truongphi/Desktop/meta/QIIME/Longitudinal/command/download.sh /home/truongphi/Desktop/meta/QIIME/Longitudinal/downfiles.df download

mv download/Sample_metadata/sample_metadata.tsv download/Sample_metadata/ecam-sample-metadata.tsv
mv download/Importing_data/ecam_shannon.qza download/Importing_data/shannon.qza
