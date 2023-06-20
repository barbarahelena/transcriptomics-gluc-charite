# Transcriptomics glucagon HAEC experiments

## Introduction
We performed differential gene expression (DGE) analyses to assess the effects of glucagon on HAECs. The RNA sequencing was performed by Azenta using Illumina NovaSeq, PE 2x150. There were 3 replicates per condition (10 nM glucagon and control), originating from three separate experiments. [add more details about experiments]

## Processing RNA seq data (Azenta report)
Sequence reads were trimmed to remove possible adapter sequences and nucleotides with poor quality using Trimmomatic v.0.36. The trimmed reads were mapped to the Homo sapiens GRCh38 reference genome available on ENSEMBL using the STAR aligner v.2.5.2b. The STAR aligner is a splice aligner that detects splice junctions and incorporates them to help align the entire read sequences. BAM files were generated as a result of this step.

Unique gene hit counts were calculated by using featureCounts from the Subread package v.1.5.2. The hit counts were summarized and reported using the gene_id feature in the annotation file. Only unique reads that fell within exon regions were counted. If a strand-specific library preparation was performed, the reads were strand-specifically counted.

## DGE analyses
Genes with less than 5 counts across samples were filtered out. We used DESeq2 (v.1.36.0) to assess the differentially expressed genes between control and glucagon-stimulated samples (see `deseq2.R`). For these analyses, the formula Gene ~ Condition was used, with a Wald test and parametric fit. Genes with a P-value <0.01 were considered as differentially expressed between control and glucagon conditions. Gene counts were normalized using DESeq2’s median of ratios method to account for sequencing depth and RNA composition. 

## Plots
See the `plots.R` script. The following plots were drawn:
- Volcano plot: drawn using ggplot2 (v3.4.0). 
- Heatmap: After zero mean, unit variance scaling of the normalized gene counts, a heatmap with differentially expressed genes was drawn using the ComplexHeatmap package (v2.12.1). The dendrogram in this plot was constructed with Ward’s method.
- Boxplots

## Pathway analyses
Pathway analyses were performed using GO and KEGG (see `pathwayanalysis.R`). There were no significant pathways (padj < 0.1). One of the KEGG pathways with the lowest p-values was the hsa01522 "Endocrine resistance" pathway. That pathway, although not significant, was visualized. Plots can be found in the hsa01522 folder, in the pdf folder of the results.

## Data availability
Data will be made available on ENA. As soon as the data are available, the repository link will be made available here.
