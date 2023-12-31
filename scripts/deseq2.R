## DESeq2 analysis

## libraries
library(DESeq2)
library(dplyr)
library(stringr)

# Pending installations
# updateR::updateR()
# BiocManager::install("BiocParallel")
# install.packages("locfit")
# BiocManager::install(c("gage","GO.db","AnnotationDbi","org.Hs.eg.db"))

## Check summary stats
summarystats <- read.csv('data/01_analysis/stats/star/summary_mapping_stats.csv')
summarystats
head(summarystats)
sampleno <- nrow(summarystats)
print(str_c("Mean total reads for ", sampleno, " samples was: ", format(mean(summarystats$Total.Reads), 10), 
            " with an SD of: ", format(sd(summarystats$Total.Reads), 10), " of which ", 
            format((mean(summarystats$Total.Mapped.Reads)/mean(summarystats$Total.Reads)) * 100, 1),
            "% were mapped."
            ))

## Open raw count file
rawCounts <- read.csv('data/01_analysis/DEG/deseq2/Control-vs-Stimulation/counts/raw_counts.csv')
print(str_c("Mean total counts for ", sampleno, " samples was: ", mean(colSums(rawCounts[,-1])), 
            " with an SD of: ", sd(colSums(rawCounts[,-1]))))
rawCounts$Gene.ID <- rawCounts$X
rawCounts$X <- NULL

## Open sample mapping
sampleData <- read.delim("data/01_analysis/DEG/deseq2/Control-vs-Stimulation/testCondition.txt")
sampleData$batch <- NULL
sampleData <- sampleData %>% mutate(SampleName = str_remove(SampleID, "10nM-"),
                                    condition = as.factor(condition),
                                    condition = forcats::fct_recode(condition,
                                                                    "Treatment" = "Control",
                                                            "Control" = "Stimulation"),
                                    condition = forcats::fct_relevel(condition, "Control", after = 0L),
                                    SampleID = case_when(
                                        str_detect(SampleID, "10nM") ~ str_c("X", str_replace_all(SampleID, "-", ".")),
                                        str_detect(SampleID, "Ctrl") ~ str_replace_all(SampleID, "-", ".")
                                    ),
                                    Run = "1")
head(sampleData)
levels(sampleData$condition)
rownames(sampleData) <- sampleData$SampleID

# Also save a copy for later
sampleData_v2 <- sampleData

# Convert count data to a matrix of appropriate form that DEseq2 can read
geneID <- rawCounts$Gene.ID
sampleIndex <- !grepl("Gene", colnames(rawCounts))
rawCounts <- as.matrix(rawCounts[,sampleIndex])
rownames(rawCounts) <- geneID
head(rawCounts)

# Put the columns of the count data in the same order as rows names of the sample mapping, then make sure it worked
rawCounts <- rawCounts[,unique(rownames(sampleData))]
all(colnames(rawCounts) == rownames(sampleData))

# Create the DEseq2DataSet object
deseq2Data <- DESeqDataSetFromMatrix(countData=rawCounts, colData=sampleData, design= ~ condition)

# Prefiltering data (low counts)
dim(deseq2Data)
dim(deseq2Data[rowSums(counts(deseq2Data) >= 10 ) >= 3, ]) # 15,072 of 57,500
deseq2Data <- deseq2Data[rowSums(counts(deseq2Data) >= 10 ) >= 3, ]

# Run pipeline for differential expression steps 
deseq2Data <- DESeq(deseq2Data)

# Extract differential expression results
deseq2Results <- results(deseq2Data, contrast=c("condition", "Control", "Treatment"),
                         alpha = 0.1)
deseq2Results$ENSEMBL <- rownames(deseq2Results)

summary(deseq2Results)

# out of 14165 with nonzero total read count
# adjusted p-value < 0.1
# LFC > 0 (up)       : 0, 0%
# LFC < 0 (down)     : 0, 0%
# outliers [1]       : 0, 0%
# low counts [2]     : 0, 0%
# (mean count < 12)
# [1] see 'cooksCutoff' argument of ?results
# [2] see 'independentFiltering' argument of ?results

plotMA(deseq2Results)

deseq2Results[which(deseq2Results$pvalue < 0.01),]

library(EnsDb.Hsapiens.v86)
deseq2Results$symbol <- mapIds(EnsDb.Hsapiens.v86, keys=deseq2Results$ENSEMBL,
                               column="SYMBOL", keytype="GENEID", multiVals="first")

counts <- as.data.frame(counts(estimateSizeFactors(deseq2Data), normalized=TRUE))
counts$ENSEMBL <- rownames(counts)

deseq2Results <- dplyr::right_join(counts, as.data.frame(deseq2Results), by = "ENSEMBL")

# Save files
# DESeq2 results object
head(deseq2Results)
deseq2Results %>% dplyr::filter(pvalue < 0.01)
write.csv2(deseq2Results, "data/230620_deseq2results.csv")
head(deseq2Results)
