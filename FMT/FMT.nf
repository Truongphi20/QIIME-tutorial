#!/usr/bin/env nextflow


process DOWNLOAD{

	//publishDir "$projectDir", mode: 'copy'
	
	
	output:
	path "Sample_metadata/sample_metadata.tsv"
	path "Importing_data/fmt-tutorial-demux-1-10p.qza"
	path "Importing_data/fmt-tutorial-demux-2-10p.qza"
	
	"""
	$projectDir/command/download.sh $projectDir/downfiles.df \$(pwd)
	"""
}

process SEQ_QC{
	publishDir "$projectDir/qc", mode: 'copy'

	input:
	path seq1
	path seq2
	
	output:
	path "seq_qc"
	
	"""
	mkdir seq_qc
	qiime demux summarize \
	  --i-data $seq1\
	  --o-visualization seq_qc/demux-summary-1.qzv
	qiime demux summarize \
	  --i-data $seq2\
	  --o-visualization seq_qc/demux-summary-2.qzv
	"""
}

process DENOISE{
	input:
	path seq1
	path seq2
	
	output:
	path "rep-seqs-1.qza"
	path "table-1.qza"
	
	path "rep-seqs-2.qza"
	path "table-2.qza"
	
	"""
	qiime dada2 denoise-single \
	  --p-trim-left 13 \
	  --p-trunc-len 150 \
	  --i-demultiplexed-seqs $seq1 \
	  --o-representative-sequences rep-seqs-1.qza \
	  --o-table table-1.qza \
	  --o-denoising-stats stats-1.qza
	  
	qiime dada2 denoise-single \
	  --p-trim-left 13 \
	  --p-trunc-len 150 \
	  --i-demultiplexed-seqs $seq2 \
	  --o-representative-sequences rep-seqs-2.qza \
	  --o-table table-2.qza \
	  --o-denoising-stats stats-2.qza
	"""
}

process DENOISE_VIS{
	publishDir(
		path:"$projectDir/qc/denoise",
		mode:"copy",
	)	
	
	input:
	path seq1
	path seq2
	
	output:
	path "denoising-stats-1.qzv"
	path "denoising-stats-2.qzv"
	
	"""
	qiime metadata tabulate \
	  --m-input-file $seq1 \
	  --o-visualization denoising-stats-1.qzv
	qiime metadata tabulate \
	  --m-input-file $seq2 \
	  --o-visualization denoising-stats-2.qzv
	"""
}

process MERGE{
	input:
	path seq1
	path table1
	
	path seq2
	path table2
	
	output:
	path "table.qza"
	path "rep-seqs.qza"
	
	"""
	qiime feature-table merge \
	  --i-tables table-1.qza \
	  --i-tables table-2.qza \
	  --o-merged-table table.qza
	qiime feature-table merge-seqs \
	  --i-data rep-seqs-1.qza \
	  --i-data rep-seqs-2.qza \
	  --o-merged-data rep-seqs.qza
	"""
}

process MERGE_VIS{
	publishDir "$projectDir/qc", mode: 'copy'
	
	input:
	path table
	path seq
	
	path metadata
	
	output:
	path "merge_qc"
	
	"""
	mkdir merge_qc
	qiime feature-table summarize \
	  --i-table $table \
	  --o-visualization merge_qc/table.qzv \
	  --m-sample-metadata-file $metadata
	  
	qiime feature-table tabulate-seqs \
	  --i-data $seq \
	  --o-visualization merge_qc/rep-seqs.qzv
	"""
}

process FILTER{
	
	publishDir(
		path: "$projectDir/qc/filtered/",
		pattern: "*.qzv",  
		mode: 'copy')

	input:
	path table
	path metadata
	
	output:
	path "filtered-table.qza"
	path "sample_metadata_filtered.tsv"
	path "ftable.qzv"
	
	"""
	qiime feature-table filter-samples \
    --i-table $table \
    --m-metadata-file $metadata \
    --p-where 'NOT [treatment-group]="donor"' \
    --o-filtered-table filtered-table.qza
    
    cat $metadata| grep -v "donor" > sample_metadata_filtered.tsv
    
    qiime feature-table summarize \
	  --i-table filtered-table.qza \
	  --o-visualization ftable.qzv \
	  --m-sample-metadata-file sample_metadata_filtered.tsv
	"""
}

process PHYLOGENETIC{
	input:
	path seqs
	
	output:
	path "tree"
	
	"""
	mkdir tree
	qiime phylogeny align-to-tree-mafft-fasttree \
	  --i-sequences $seqs \
	  --o-alignment tree/aligned-rep-seqs.qza \
	  --o-masked-alignment tree/masked-aligned-rep-seqs.qza \
	  --o-tree tree/unrooted-tree.qza \
	  --o-rooted-tree tree/rooted-tree.qza
	"""
}

process DIVERSITY{

	publishDir(
		path: "$projectDir/qc",
		pattern: "diversity/*.qzv",  
		mode: 'copy')
	
	input:
	path tree
	path table
	path metadata
	
	output:
	path "diversity/*"
	
	"""
	qiime diversity core-metrics-phylogenetic \
	  --i-phylogeny $tree/rooted-tree.qza \
	  --i-table $table \
	  --p-sampling-depth 900 \
	  --m-metadata-file $metadata \
	  --output-dir diversity
	"""
}

process ALPHA{

	publishDir(
		path: "$projectDir/qc/alpha",
		pattern: "*.qzv",  
		mode: 'copy')
	
	input:
	path diversity
	path metadata
	
	
	output:
	path "*.qzv"
	
	"""
	qiime diversity alpha-group-significance \
	  --i-alpha-diversity faith_pd_vector.qza \
	  --m-metadata-file $metadata \
	  --o-visualization faith-pd-group-significance.qzv

	qiime diversity alpha-group-significance \
	  --i-alpha-diversity evenness_vector.qza \
	  --m-metadata-file $metadata \
	  --o-visualization evenness-group-significance.qzv
	"""
}

process BETA{

	publishDir(
		path: "$projectDir/qc/beta",
		pattern: "*.qzv",  
		mode: 'copy')

	input:
	path diversity
	path metadata
	
	output:
	path "*.qzv"
	
	"""
	qiime diversity beta-group-significance \
	  --i-distance-matrix unweighted_unifrac_distance_matrix.qza \
	  --m-metadata-file $metadata \
	  --m-metadata-column sample-type\
	  --o-visualization unweighted-unifrac-sample-type-significance.qzv \
	  --p-pairwise

	qiime diversity beta-group-significance \
	  --i-distance-matrix unweighted_unifrac_distance_matrix.qza \
	  --m-metadata-file $metadata \
	  --m-metadata-column subject-id \
	  --o-visualization unweighted-unifrac-subject-id-group-significance.qzv \
	  --p-pairwise
	"""

}

process RAREFACTION{
	
	publishDir(
		path: "$projectDir/qc/rarefaction", 
		mode: 'copy')
	
	input:
	path ftable
	path tree
	path metadata
	
	output:
	path "alpha-rarefaction.qzv"
	
	"""
	qiime diversity alpha-rarefaction \
	  --i-table $ftable \
	  --i-phylogeny $tree/rooted-tree.qza \
	  --p-max-depth 6000 \
	  --m-metadata-file $metadata \
	  --o-visualization alpha-rarefaction.qzv
	"""
}

process PAIRWISE_DIFF{
	
	publishDir "$projectDir/qc/pair", mode: 'copy'
	
	input:
	path fmetadata
	path diversity
	
	output:
	path "pairwise-differences.qzv"
	
	"""
	qiime longitudinal pairwise-differences \
	  --m-metadata-file $fmetadata \
	  --m-metadata-file shannon_vector.qza \
	  --p-metric shannon_entropy \
	  --p-group-column treatment-group \
	  --p-state-column week \
	  --p-state-1 0 \
	  --p-state-2 18 \
	  --p-individual-id-column subject-id \
	  --p-replicate-handling random \
	  --o-visualization pairwise-differences.qzv
	"""
}

process PAIRWISE_DIST{
	publishDir "$projectDir/qc/pair", mode: 'copy'
	
	input:
	path fmetadata
	path diversity
	
	output:
	path "pairwise-distances.qzv"
	
	"""
	qiime longitudinal pairwise-distances \
	  --i-distance-matrix unweighted_unifrac_distance_matrix.qza \
	  --m-metadata-file $fmetadata \
	  --p-group-column treatment-group \
	  --p-state-column week \
	  --p-state-1 0 \
	  --p-state-2 18 \
	  --p-individual-id-column subject-id \
	  --p-replicate-handling random \
	  --o-visualization pairwise-distances.qzv
	"""
}

workflow{
	(metadata, rseq1, rseq2) = DOWNLOAD()
	(seq_qc) = SEQ_QC(rseq1, rseq2)
	(seq1, table1, seq2, table2) = DENOISE(rseq1, rseq2)
	DENOISE_VIS(seq1, seq2)
	(table, seq) = MERGE(seq1, table1, seq2, table2)
	MERGE_VIS(table, seq, metadata)
	(ftable, fmeta) = FILTER(table, metadata)
	(tree_folder) = PHYLOGENETIC(seq)
	(dfolder) = DIVERSITY(tree_folder, ftable, fmeta)
	(alpha) = ALPHA(dfolder, fmeta)
	(beta) = BETA(dfolder, fmeta)
	(rare) = RAREFACTION(ftable, tree_folder, fmeta)
	(pairdif) = PAIRWISE_DIFF(fmeta, dfolder)
	(pairdis) = PAIRWISE_DIST(fmeta, dfolder)
	
}
