#!/usr/bin/env nextflow
params.link_download="${projectDir}/downfiles"

process DOWNDATA{

	//publishDir "$projectDir", mode: 'copy'
	
	input:
	path downfile
	
	output:
	path "download"
	
	"""
	mkdir download | $projectDir/command/download.sh $projectDir/downfiles.df download
	
	mv download/Sample_metadata/sample_metadata.tsv download/Sample_metadata/ecam-sample-metadata.tsv
	mv download/Importing_data/ecam_shannon.qza download/Importing_data/shannon.qza
	"""
}

process PAIRWISE_DIFF{
	
	publishDir "$projectDir", mode: 'copy'
	
	input:
	path downfile
	
	output:
	path "pair_diff"
	
	"""
	mkdir pair_diff
	qiime longitudinal pairwise-differences \
	  --m-metadata-file $downfile/Sample_metadata/ecam-sample-metadata.tsv \
	  --m-metadata-file $downfile/Importing_data/shannon.qza \
	  --p-metric shannon \
	  --p-group-column delivery \
	  --p-state-column month \
	  --p-state-1 0 \
	  --p-state-2 12 \
	  --p-individual-id-column studyid \
	  --p-replicate-handling random \
	  --o-visualization pair_diff/pairwise-differences.qzv
	"""
}

process PAIRWISE_DIST{
	publishDir "$projectDir", mode: 'copy'
	
	input:
	path downfile
	
	output:
	path "pair_dist"
	
	"""
	mkdir pair_dist
	qiime longitudinal pairwise-distances \
	  --i-distance-matrix $downfile/Importing_data/unweighted_unifrac_distance_matrix.qza \
	  --m-metadata-file $downfile/Sample_metadata/ecam-sample-metadata.tsv \
	  --p-group-column delivery \
	  --p-state-column month \
	  --p-state-1 0 \
	  --p-state-2 12 \
	  --p-individual-id-column studyid \
	  --p-replicate-handling random \
	  --o-visualization pair_dist/pairwise-distances.qzv
	"""
}

process LINEAR_MIX{
	publishDir "$projectDir", mode: 'copy'
	
	input:
	path downfile
	
	output:
	path "linear"
	
	"""
	mkdir linear
	qiime longitudinal linear-mixed-effects \
	  --m-metadata-file $downfile/Sample_metadata/ecam-sample-metadata.tsv \
	  --m-metadata-file $downfile/Importing_data/shannon.qza \
	  --p-metric shannon \
	  --p-group-columns delivery,diet,sex \
	  --p-state-column month \
	  --p-individual-id-column studyid \
	  --o-visualization linear/linear-mixed-effects.qzv
	"""
}

process VOLATILITY{
	publishDir "$projectDir", mode: 'copy'
	
	input:
	path downfile
	
	output:
	path "vola"
	
	"""
	mkdir vola
	qiime longitudinal volatility \
	  --m-metadata-file $downfile/Sample_metadata/ecam-sample-metadata.tsv \
	  --m-metadata-file $downfile/Importing_data/shannon.qza \
	  --p-default-metric shannon \
	  --p-default-group-column delivery \
	  --p-state-column month \
	  --p-individual-id-column studyid \
	  --o-visualization vola/volatility.qzv
	"""
}

workflow{
	download = DOWNDATA(params.link_download)
	pair_diff = PAIRWISE_DIFF(download)
	pair_dist = PAIRWISE_DIST(download)
	linear_mix = LINEAR_MIX(download)
	volatility = VOLATILITY(download)
}
