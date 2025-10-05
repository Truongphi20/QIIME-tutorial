#!/usr/bin/env nextflow

params.metadata = "https://data.qiime2.org/2023.2/tutorials/moving-pictures/sample_metadata.tsv"
params.table = "https://data.qiime2.org/2023.2/tutorials/filtering/table.qza"
params.matrix = "https://data.qiime2.org/2023.2/tutorials/filtering/distance-matrix.qza"
params.taxanomy = "https://data.qiime2.org/2023.2/tutorials/filtering/taxonomy.qza"
params.sequences = "https://data.qiime2.org/2023.2/tutorials/filtering/sequences.qza"

process FREQUENCY_FILTERING{
	input:
	path table
	
	
	"""
	mkdir rs
	qiime feature-table filter-samples \
	  --i-table $table \
	  --p-min-frequency 1500 \
	  --o-filtered-table rs/sample-frequency-filtered-table-1500.qza
	
	qiime feature-table filter-features \
	  --i-table table.qza \
	  --p-min-frequency 10 \
	  --o-filtered-table rs/feature-frequency-filtered-table-10.qza
	"""
	
}

process CONTINGENCY_FILTERING{
	input:
	path table
	
	"""
	mkdir rs
	qiime feature-table filter-features \
	  --i-table $table\
	  --p-min-samples 2 \
	  --o-filtered-table rs/sample-contingency-filtered-table.qza
	  
	qiime feature-table filter-samples \
	  --i-table $table \
	  --p-min-features 10 \
	  --o-filtered-table rs/feature-contingency-filtered-table.qza
	"""
}

process IDENTIFIER_FILTERING{
	input:
	path table
	
	"""
	echo SampleID > samples-to-keep.tsv
	echo L1S8 >> samples-to-keep.tsv
	echo L1S105 >> samples-to-keep.tsv
	
	qiime feature-table filter-samples \
	  --i-table $table \
	  --m-metadata-file samples-to-keep.tsv \
	  --o-filtered-table id-filtered-table.qza
	"""
}


workflow{
	FREQUENCY_FILTERING(params.table)
	CONTINGENCY_FILTERING(params.table)
	IDENTIFIER_FILTERING(params.table)
}
