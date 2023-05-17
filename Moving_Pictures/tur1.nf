#!/usr/bin/env nextflow
params.link_download="${projectDir}/downfiles" 

process DOWNDATA{

	//publishDir "$projectDir", mode: 'copy'
	
	input:
	val downfile
	
	output:
	path "download"
	
	"""
	mkdir download && $projectDir/command/download.sh $projectDir/downfiles.df download
	"""
}

process ARTIFACTS{
	//publishDir "$projectDir", mode: 'copy'
	
	input:
	path down_files
	
	output:
	path "artifacts" 
	
	"""
	mkdir artifacts
	qiime tools import \
	  --type EMPSingleEndSequences \
	  --input-path $down_files/Importing_data \
	  --output-path "artifacts/emp-single-end-sequences.qza"
	"""
}

process DEMULTIPLEX{

//	publishDir "$projectDir", mode: 'copy'
	input:
	path down_files
	path artifact
	
	output:
	path "demultiplex"
	
	"""
	mkdir demultiplex
	qiime demux emp-single \
	  --i-seqs $artifact/emp-single-end-sequences.qza \
	  --m-barcodes-file $down_files/Sample_metadata/sample_metadata.tsv \
	  --m-barcodes-column barcode-sequence \
	  --o-per-sample-sequences demultiplex/demux.qza \
	  --o-error-correction-details demultiplex/demux-details.qza
	  
	qiime demux summarize \
	  --i-data demultiplex/demux.qza \
	  --o-visualization demultiplex/demux.qzv
	"""
}

process QC_DADA{
//	publishDir "$projectDir", mode: 'copy'
	input:
	path demultiplex
	
	output:
	path "qc_dada"
	
	"""
	mkdir qc_dada
	qiime dada2 denoise-single \
	  --i-demultiplexed-seqs $demultiplex/demux.qza \
	  --p-trim-left 0 \
	  --p-trunc-len 120 \
	  --o-representative-sequences qc_dada/rep-seqs-dada2.qza \
	  --o-table qc_dada/table-dada2.qza \
	  --o-denoising-stats qc_dada/stats-dada2.qza
	  
	qiime metadata tabulate \
	  --m-input-file qc_dada/stats-dada2.qza \
	  --o-visualization qc_dada/stats-dada2.qzv
	
	mv qc_dada/rep-seqs-dada2.qza qc_dada/rep-seqs.qza
	mv qc_dada/table-dada2.qza qc_dada/table.qza
	"""
}

process QC_DEBLUR{
//	publishDir "$projectDir", mode: 'copy'
	input:
	path demultiplex
	
	output:
	path "qc_deblur"
	
	"""
	mkdir qc_deblur
	qiime quality-filter q-score \
	 --i-demux $demultiplex/demux.qza \
	 --o-filtered-sequences qc_deblur/demux-filtered.qza \
	 --o-filter-stats qc_deblur/demux-filter-stats.qza
	 
	qiime deblur denoise-16S \
	  --i-demultiplexed-seqs qc_deblur/demux-filtered.qza \
	  --p-trim-length 120 \
	  --o-representative-sequences qc_deblur/rep-seqs-deblur.qza \
	  --o-table qc_deblur/table-deblur.qza \
	  --p-sample-stats \
	  --o-stats qc_deblur/deblur-stats.qza
	  
	qiime metadata tabulate \
	  --m-input-file qc_deblur/demux-filter-stats.qza \
	  --o-visualization qc_deblur/demux-filter-stats.qzv
	qiime deblur visualize-stats \
	  --i-deblur-stats qc_deblur/deblur-stats.qza \
	  --o-visualization qc_deblur/deblur-stats.qzv
	  
	mv qc_deblur/rep-seqs-deblur.qza qc_deblur/rep-seqs.qza
	mv qc_deblur/table-deblur.qza qc_deblur/table.qza
	"""
}

process SUMMARY{
	publishDir "$projectDir", mode: 'copy'
	input:
	path down_files
	path qc
	
	output:
	path "summary"
	
	"""
	mkdir summary
	qiime feature-table summarize \
	  --i-table $qc/table.qza \
	  --o-visualization summary/table.qzv \
	  --m-sample-metadata-file $down_files/Sample_metadata/sample_metadata.tsv
	qiime feature-table tabulate-seqs \
	  --i-data $qc/rep-seqs.qza \
	  --o-visualization summary/rep-seqs.qzv
	"""
}

process PHYLOGENETIC{
//	publishDir "$projectDir", mode: 'copy'
	input:
	path qc
	
	output:
	path "tree"
	
	"""
	mkdir tree
	qiime phylogeny align-to-tree-mafft-fasttree \
	  --i-sequences $qc/rep-seqs.qza \
	  --o-alignment tree/aligned-rep-seqs.qza \
	  --o-masked-alignment tree/masked-aligned-rep-seqs.qza \
	  --o-tree tree/unrooted-tree.qza \
	  --o-rooted-tree tree/rooted-tree.qza
	"""
}

process DIVERSITY{
	publishDir "$projectDir", mode: 'copy'
	input:
	path down_files
	path qc
	path tree
	
	output:
	path "alpha_beta"
	
	"""
	qiime diversity core-metrics-phylogenetic \
	  --i-phylogeny $tree/rooted-tree.qza \
	  --i-table $qc/table.qza \
	  --p-sampling-depth 1103 \
	  --m-metadata-file $down_files/Sample_metadata/sample_metadata.tsv \
	  --output-dir alpha_beta
	  
	mkdir alpha_beta/analysis
	qiime diversity alpha-group-significance \
	  --i-alpha-diversity alpha_beta/faith_pd_vector.qza \
	  --m-metadata-file $down_files/Sample_metadata/sample_metadata.tsv \
	  --o-visualization alpha_beta/analysis/faith_pd_group_significance.qzv

	qiime diversity alpha-group-significance \
	  --i-alpha-diversity alpha_beta/evenness_vector.qza \
	  --m-metadata-file $down_files/Sample_metadata/sample_metadata.tsv \
	  --o-visualization alpha_beta/analysis/evenness_group_significance.qzv
	  
	qiime emperor plot \
	  --i-pcoa alpha_beta/unweighted_unifrac_pcoa_results.qza \
	  --m-metadata-file $down_files/Sample_metadata/sample_metadata.tsv \
	  --p-custom-axes days-since-experiment-start \
	  --o-visualization alpha_beta/analysis/unweighted-unifrac-emperor-days-since-experiment-start.qzv

	qiime emperor plot \
	  --i-pcoa alpha_beta/bray_curtis_pcoa_results.qza \
	  --m-metadata-file $down_files/Sample_metadata/sample_metadata.tsv \
	  --p-custom-axes days-since-experiment-start \
	  --o-visualization alpha_beta/analysis/bray-curtis-emperor-days-since-experiment-start.qzv
	"""
}

process ALPHAL_RAREFACTION{
	publishDir "$projectDir", mode: 'copy'
	input:
	path qc
	path tree
	path down_files
	
	output:
	path "alpha_rare"
	
	"""
	mkdir alpha_rare
	qiime diversity alpha-rarefaction \
	  --i-table $qc/table.qza \
	  --i-phylogeny $tree/rooted-tree.qza \
	  --p-max-depth 4000 \
	  --m-metadata-file $down_files/Sample_metadata/sample_metadata.tsv \
	  --o-visualization alpha_rare/alpha-rarefaction.qzv
	"""
}

process TAXONOMIC{
	publishDir "$projectDir", mode: 'copy'
	input:
	path down_files
	path qc
	
	
	output:
	path "taxo"
	
	"""
	mkdir taxo
	mkdir taxo/vis
	qiime feature-classifier classify-sklearn \
	  --i-classifier $down_files/Taxonomic_analysis/gg-13-8-99-515-806-nb-classifier.qza \
	  --i-reads $qc/rep-seqs.qza \
	  --o-classification taxo/taxonomy.qza

	qiime metadata tabulate \
	  --m-input-file taxo/taxonomy.qza \
	  --o-visualization taxo/vis/taxonomy.qzv
	  
	qiime taxa barplot \
	  --i-table $qc/table.qza \
	  --i-taxonomy taxo/taxonomy.qza \
	  --m-metadata-file $down_files/Sample_metadata/sample_metadata.tsv \
	  --o-visualization taxo/vis/taxa-bar-plots.qzv
	"""
}

process ANCOM{
	publishDir "$projectDir", mode: 'copy'
	input:
	path qc
	path down_files
	path taxo
	
	output:
	path abundance
	
	"""
	mkdir abundance
	qiime feature-table filter-samples \
	  --i-table $qc/table.qza \
	  --m-metadata-file $down_files/Sample_metadata/sample_metadata.tsv \
	  --p-where "[body-site]='gut'" \
	  --o-filtered-table abundance/gut-table.qza
	
	qiime composition add-pseudocount \
	  --i-table abundance/gut-table.qza \
	  --o-composition-table abundance/comp-gut-table.qza
	
	mkdir abundance/vis  
	qiime composition ancom \
	  --i-table abundance/comp-gut-table.qza \
	  --m-metadata-file $down_files/Sample_metadata/sample_metadata.tsv \
	  --m-metadata-column subject \
	  --o-visualization abundance/vis/ancom-subject.qzv
	  
	qiime taxa collapse \
	  --i-table abundance/gut-table.qza \
	  --i-taxonomy $taxo/taxonomy.qza \
	  --p-level 6 \
	  --o-collapsed-table abundance/gut-table-l6.qza

	qiime composition add-pseudocount \
	  --i-table abundance/gut-table-l6.qza \
	  --o-composition-table abundance/comp-gut-table-l6.qza

	qiime composition ancom \
	  --i-table abundance/comp-gut-table-l6.qza \
	  --m-metadata-file $down_files/Sample_metadata/sample_metadata.tsv \
	  --m-metadata-column subject \
	  --o-visualization abundance/vis/l6-ancom-subject.qzv
	"""
}

workflow{
	download = DOWNDATA(params.link_download)
	artifact = ARTIFACTS(download )
	demultiplex = DEMULTIPLEX(download , artifact)
	qc_dada = QC_DADA(demultiplex)
	qc_deblur = QC_DEBLUR(demultiplex)
	summary = SUMMARY(download , qc_dada)
	phylogenetic = PHYLOGENETIC(qc_dada)
	diversity = DIVERSITY(download , qc_dada, phylogenetic)
	alpha_rarefaction = ALPHAL_RAREFACTION(qc_dada, phylogenetic, download )
	taxonomic = TAXONOMIC(download , qc_dada)
	abundance = ANCOM(qc_dada, download, taxonomic)
}



