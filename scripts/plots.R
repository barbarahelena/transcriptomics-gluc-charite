## DESeq2 plots

## Libraries
library(ComplexHeatmap)
library(tidyverse)
library(ggrepel)
library(dplyr)
library(gridExtra)

theme_Publication <- function(base_size=12, base_family="sans") {
    library(grid)
    library(ggthemes)
    (theme_foundation(base_size=base_size, base_family=base_family)
    + theme(plot.title = element_text(face = "bold",
                                      size = rel(1.0), hjust = 0.5),
            text = element_text(family = 'Helvetica'),
            panel.background = element_rect(colour = NA),
            plot.background = element_rect(colour = NA),
            panel.border = element_rect(colour = NA),
            axis.title = element_text(face = "bold",size = rel(1)),
            axis.title.y = element_text(angle=90,vjust =2),
            axis.title.x = element_text(vjust = -0.2),
            axis.text = element_text(), 
            axis.line = element_line(colour="black"),
            axis.ticks = element_line(),
            panel.grid.major = element_line(colour="#f0f0f0"),
            panel.grid.minor = element_blank(),
            legend.key = element_rect(colour = NA),
            legend.position = "bottom",
            # legend.direction = "horizontal",
            legend.key.size= unit(0.2, "cm"),
            legend.spacing  = unit(0, "cm"),
            # legend.title = element_text(face="italic"),
            plot.margin=unit(c(10,5,5,5),"mm"),
            strip.background=element_rect(colour="#f0f0f0",fill="#f0f0f0"),
            strip.text = element_text(face="bold")
    ))

} 

heatmap_plot <- function(df, group = "unequal", number = 100) {
    if (group == "unequal")
        df3 <- df %>% group_by(group) %>% 
            arrange(pvalue) %>% 
            dplyr::slice(1:number) %>% 
            ungroup(.) %>% 
            arrange(log2FoldChange) %>% 
            dplyr::select(Gene.name, pvalue, contains("Gcg"), contains("Ctrl"))
    else if (group == "equal")
        df3 <- df %>%
            arrange(pvalue) %>% 
            dplyr::slice(1:number) %>% 
            arrange(log2FoldChange) %>% 
            dplyr::select(Gene.name, pvalue, contains("Gcg"), contains("Ctrl"))
    else if (group == "sig")
        df3 <- df %>% 
            arrange(padj) %>% 
            dplyr::filter(pvalue<0.05) %>% 
            arrange(pvalue) %>% 
            dplyr::slice(1:number) %>% 
            dplyr::select(Gene.name, pvalue, contains("Gcg"), contains("Ctrl"))
    
    df4 <- df3 %>% 
        pivot_longer(., cols = c(3:8), 
                     names_to = "condition",
                     values_to = "count") %>% 
        mutate(condition = fct_recode(condition,
                                      'Control (1)' = 'Ctrl.1', 'Control (2)' = 'Ctrl.2','Control (3)' =  'Ctrl.3',
                                      'Gcg (1)' = 'X10nM.Gcg.1','Gcg (2)' = 'X10nM.Gcg.2','Gcg (3)' = 'X10nM.Gcg.3')
        ) %>% 
        pivot_wider(., id_cols = c(1,2), names_from = "condition", values_from = "count",
                    names_sort = TRUE)
    
    rownames(df4) <- df4$Gene.name
    df3_counts <- as.matrix(df4[,3:8])
    rownames(df3_counts) <- rownames(df4)
    df3_counts <- t(scale(t(df3_counts)))
    colnames(df3_counts) <- NULL
    
    col_fun <- circlize::colorRamp2(c(-1, 0, 1), c("dodgerblue4", "white", "firebrick"))
    
    Heatmap(df3_counts, name = "Row Z-score", col = col_fun, rect_gp = gpar(col = "white", lwd = 2),
            column_split = c(rep("Gcg 10 nM", 3), rep("Control",3)),  
            column_order = colnames(df3_counts)[1:6],
            clustering_method_rows = "ward.D2",
            top_annotation = HeatmapAnnotation(Treatment = anno_block(
                                                gp = gpar(fill = c("black", "red"))),
                                               height = unit(0.2, "cm")),
            width = unit(6, "cm"), row_names_side = "left", column_gap = unit(2, "mm"),
            row_dend_side = "right",
            row_dend_width = unit(3, "cm"),
            row_names_max_width = max_text_width(
                rownames(df3_counts),
                gp = gpar(fontsize = 10)))
}

heatmap_plot_p_anno <- function(df, group = "unequal", number = 100) {
    df <- df %>% mutate(sig = case_when(
        pvalue >= 0.05 ~ paste0(""),
        pvalue < 0.0001 ~ paste0("****"),
        pvalue < 0.001 ~ paste0("***"),
        pvalue < 0.01 ~ paste0("**"),
        pvalue < 0.05 ~ paste0("*")
    ))
    
    if (group == "unequal")
        df3 <- df %>% group_by(group) %>% 
            arrange(pvalue) %>% 
            dplyr::slice(1:number) %>% 
            ungroup(.) %>% 
            arrange(log2FoldChange) %>% 
            dplyr::select(Gene.name, pvalue, sig, contains("Gcg"), contains("Ctrl"))
    else if (group == "equal")
        df3 <- df %>%
            arrange(pvalue) %>% 
            dplyr::slice(1:number) %>% 
            arrange(log2FoldChange) %>% 
            dplyr::select(Gene.name, pvalue, sig, contains("Gcg"), contains("Ctrl"))
    else if (group == "sig")
        df3 <- df %>% 
            arrange(padj) %>% 
            dplyr::filter(pvalue<0.05) %>% 
            arrange(pvalue) %>% 
            dplyr::slice(1:number) %>% 
            dplyr::select(Gene.name, pvalue, sig, contains("Gcg"), contains("Ctrl"))
    
    df4 <- df3 %>% 
        pivot_longer(., cols = c(4:9), 
                     names_to = "condition",
                     values_to = "count") %>% 
        mutate(condition = fct_recode(condition,
                                      'Control (1)' = 'Ctrl.1', 'Control (2)' = 'Ctrl.2','Control (3)' =  'Ctrl.3',
                                      'Gcg (1)' = 'X10nM.Gcg.1','Gcg (2)' = 'X10nM.Gcg.2','Gcg (3)' = 'X10nM.Gcg.3')
        ) %>% 
        pivot_wider(., id_cols = c(1,2), names_from = "condition", values_from = "count",
                    names_sort = TRUE)
    
    rownames(df4) <- df4$Gene.name
    df3_counts <- as.matrix(df4[,3:8])
    rownames(df3_counts) <- rownames(df4)
    df3_counts <- t(scale(t(df3_counts)))
    colnames(df3_counts) <- NULL
    # print(df3)
    
    col_fun <- circlize::colorRamp2(c(-1, 0, 1), c("dodgerblue4", "white", "firebrick"))
    pvalue_col_fun <- circlize::colorRamp2(c(0, 1, 3), c("lightgrey", "white", "firebrick1")) # color mapping for -log10(pvalue)
    
    pl1 <- Heatmap(df3_counts, name = "Row Z-score", col = col_fun, rect_gp = gpar(col = "white", lwd = 2),
            column_split = c(rep("Gcg 10 nM", 3), rep("Control",3)),
            column_order = colnames(df3_counts)[1:6],
            clustering_method_rows = "ward.D2",
            top_annotation = HeatmapAnnotation(Treatment = anno_block(
                gp = gpar(fill = c("black", "red"))),
                height = unit(0.2, "cm")),
            left_annotation = rowAnnotation(pvalue = anno_simple(-log10(df3$pvalue),
                                                                 which = 'row',
                                                                 col = pvalue_col_fun,
                                                                 pch = df3$sig,
                                                                 pt_size = unit(1, "snpc")*0.5
            ),
            annotation_name_side = "bottom",
            width = unit(0.5, "cm"),
            annotation_name_gp = grid::gpar(fontsize = 8)),
            width = unit(6, "cm"), row_names_side = "left", column_gap = unit(2, "mm"),
            row_dend_side = "right",
            row_dend_width = unit(3, "cm"),
            row_names_max_width = max_text_width(
                rownames(df3_counts),
                gp = gpar(fontsize = 10)))
    lgd_pvalue = Legend(title = "p-value", col_fun = pvalue_col_fun, at = c(0, 1, 2, 3),
                        labels = c("1", "0.1", "0.01", "0.001"))
    lgd_sig = Legend(pch = c("*", "**", "***"), type = "points", labels = c("< 0.05", "< 0.01", "<0.001"),
                     legend_gp = gpar(fontsize = 7))
    pl1_anno <- draw(pl1, annotation_legend_list = list(lgd_pvalue, lgd_sig))
}


## Data
df <- read.csv2("data/230620_deseq2results.csv")
names(df)
df$X <- NULL

# df_old <- read.csv("data/01_analysis/DEG/deseq2/Control-vs-Stimulation/Differential_expression_analysis_table.csv")
# df2_old <- df_old %>% 
#     arrange(pvalue) %>% 
#     slice_head(n = 25)

df$group <- case_when(
    df$log2FoldChange < 0 ~ paste0("lower in Gcg"),
    df$log2FoldChange > 0 ~ paste0("higher in Gcg")
)
df$sig <- case_when(df$pvalue < 0.05 ~ paste0("sig"), 
                  df$pvalue >0.05 ~ paste0("insig"))
df$Gene.name <- df$symbol
df$padj2 <- p.adjust(df$pvalue, method = "BH", n = length(df$pvalue))
summary(is.na(df$padj))

df2 <- df %>% group_by(group) %>% 
    arrange(pvalue) %>% 
    ungroup(.) %>% 
    slice_head(n = 25) %>% 
    arrange(log2FoldChange) %>% 
    mutate(Gene.name = forcats::fct_inorder(symbol))
nrow(df2)
head(df2)
df2$Gene.name
# df2_old$Gene.name
# unique(c(as.character(df2$Gene.name), df2_old$Gene.name))
# duplicated(c(as.character(df2$Gene.name), df2_old$Gene.name))

## DEG barplot
ggplot(df2, aes(x = Gene.name, y = log2FoldChange, fill = forcats::fct_rev(group))) +
        theme_Publication() +
        geom_bar(stat = "identity", alpha = 0.8) +
        #scale_y_continuous(breaks = c(-4,-3,-2,-1,0,1)) +
        ggsci::scale_fill_lancet() +
        coord_flip() +
        labs(y = 'Log2 fold change with Gcg', x='', 
             title = 'Differential gene expression: top 20 genes',
             fill = '') +
        theme(axis.text.x = element_text(size=11)) + 
        theme(axis.text.y = element_text(size=10)) +
        theme(legend.key.size= unit(0.5, "cm")) +
        theme(legend.position = 'none', legend.justification = 'center')
ggsave("results/pdf/230620_diff_exp_sig.pdf", height = 6, width = 6, device = "pdf")
ggsave("results/svg/230620_diff_exp_sig.svg", height = 6, width = 6, device = "svg")

df5 <- df %>% group_by(group) %>% 
    arrange(pvalue) %>% 
    dplyr::slice(1:20) %>% 
    ungroup(.) %>% 
    arrange(log2FoldChange) %>% 
    mutate(Gene.name = forcats::fct_inorder(symbol))

ggplot(df5, aes(x = Gene.name, y = log2FoldChange, fill = forcats::fct_rev(group))) +
    theme_Publication() +
    geom_bar(stat = "identity", alpha = 0.8) +
    #scale_y_continuous(breaks = c(-0.50, -0.25, 0, 0.25, 0.50), limits = c(-0.60, 0.60)) +
    ggsci::scale_fill_lancet() +
    coord_flip() +
    labs(y = 'Log2 fold change with Gcg', x='', 
         title = 'Differential gene expression',
         fill = '') +
    theme(axis.text.x = element_text(size=11)) + 
    theme(axis.text.y = element_text(size=10)) +
    theme(legend.key.size= unit(0.5, "cm")) +
    theme(legend.position = 'none', legend.justification = 'center')
ggsave("results/pdf/230620_diff_exp_top20_2sides.pdf", height = 6, width = 5, device = "pdf")
ggsave("results/svg/230620_diff_exp_top20_2sides.svg", height = 6, width = 5, device = "svg")

pdf("results/pdf/230620_heatmap_significant.pdf", width = 8, height = 6)
heatmap_plot(df, group = "sig", number = 20)
dev.off()
svg("results/svg/230620_heatmap_significant.svg", width = 8, height = 6)
heatmap_plot(df, group = "sig", number = 20)
dev.off()

pdf("results/pdf/230620_heatmap_withp.pdf", width = 8, height = 6)
heatmap_plot_p_anno(df, group = "sig", number = 20)
dev.off()
svg("results/svg/230620_heatmap_withp.svg", width = 8, height = 6)
heatmap_plot_p_anno(df, group = "sig", number = 20)
dev.off()

## Boxplot differences
res <- list()
for(a in 1:nrow(df2)){
    gene <- df2[a,]
    genename <- df2$symbol[a]
    genetab <- gene %>% pivot_longer(., cols = c(1:6)) %>% 
        mutate(group2 = case_when(
            str_detect(name, "Gcg") ~ paste0("Gcg 10 nM"),
            str_detect(name, "Ctrl") ~ paste0("Control")
        ))
    means_genetab <- genetab %>% group_by(group2) %>% 
        summarise(mean_count = mean(value), sd_count = sd(value))
    comp <- list(c("Control", "Gcg 10 nM"))
    (pl <- ggplot(data = genetab, aes(x = group2, y = value)) + 
        geom_bar(data = means_genetab, aes(x = group2, y = mean_count, 
                                           fill = group2), stat = "identity", color = "black") +
        geom_errorbar(data = means_genetab, 
                      aes(x=group2, y=mean_count, ymin=mean_count, 
                          ymax=mean_count+(sd_count/sqrt(3))), width = 0.5) +
            geom_jitter(color = "black", width = 0.2, height = 0) +
            ggpubr::geom_pwc(method = "t.test", label = "p.signif", comparisons = comp,
                             hide.ns = TRUE, bracket.nudge.y = 1, label.size = 5) +
        ylim(NA, max(genetab$value)*1.3) +
        scale_fill_manual(guide = "none", values = c("white",ggsci::pal_lancet()(2)[2])) +
        labs(title=paste0(genename), y="Normalized counts", x = "") +
        theme_Publication())
    ggsave(str_c("results/pdf/", genename, ".pdf"), width = 3, height = 5, device = "pdf")
    ggsave(str_c("results/svg/", genename, ".svg"), width = 3, height = 5, device = "svg")
    #ggsave(str_c("results/png/", genename, ".png"), width = 3, height = 5, device = "png")
    res[[a]] <- pl
}

pdf("results/pdf/boxplots_counts.pdf", width = 10, height = 12)
grid.arrange(grobs=res, ncol=5)
dev.off()

svg("results/svg/boxplots_counts.svg", width = 10, height = 12)
grid.arrange(grobs=res, ncol=5)
dev.off()


## Volcano plot
df$sigdir <- case_when(
    df$sig == "sig" & df$group == "higher in Gcg" ~ paste0("up"),
    df$sig == "sig" & df$group == "lower in Gcg" ~ paste0("down"),
    df$sig == "insig" ~ paste0("no")
)
df$sigdir <- as.factor(df$sigdir)
levels(df$sigdir)

df <- df %>% 
    mutate(
        sigdir = case_when(
            padj < 0.1 & group == "higher in Gcg" ~ paste0("up"),
            padj < 0.1 & group == "lower in Gcg" ~ paste0("down"),
            padj >= 0.1 ~ paste0("no")
        ),
        sigdir = as.factor(sigdir),
        sigdir = fct_infreq(sigdir),
        delabel = case_when(
            pvalue < 0.01 ~ paste0(Gene.name),
            pvalue >= 0.01 ~ paste0("")
        )
    ) %>% 
    arrange(padj2)

set.seed(1234)
ggplot(df, aes(x = log2FoldChange, y = -log10(pvalue), color = group, label = delabel)) +
    theme_Publication() +
    geom_hline(aes(yintercept = -log10(0.05)), color = "darkgrey", linetype = "dashed") +
    geom_point(alpha = 0.6) +
    geom_text_repel(size = 3, seed = 24, box.padding = 1.5, min.segment.length = 0,
                    point.padding = 0, 
                    #color = c(rep("black", 35), ggsci::pal_lancet()(2)[2], rep("black", 20339)),
                    fontface = "bold", force_pull = 0,
                    nudge_x = 0.05, nudge_y = 0.5, segment.color = "grey50", 
                    force = 1, max.overlaps = 15) +
    scale_color_manual(values = c(ggsci::pal_lancet()(2)), guide = "none") +
    #scale_x_continuous(limits = c(-0.6, 0.6)) +
    labs(x = "Log2 fold change with Gcg",
         y = "-log10(p-value)") 
ggsave("results/pdf/230620_volcanoplot.pdf", width = 5, height = 5, device = "pdf")    
ggsave("results/svg/230620_volcanoplot.svg", width = 5, height = 5, device = "svg")

# set.seed(1234)
# ggplot(df, aes(x = log2FoldChange, y = -log10(pvalue), color = group, label = delabel)) +
#     theme_Publication() +
#     geom_point(alpha = 0.6) +
#     geom_text_repel(size = 3, seed = 24, box.padding = 1.5, min.segment.length = 0,
#                     point.padding = 0, fontface = "bold", force_pull = 0,
#                     nudge_x = 0.05, nudge_y = 0.5, segment.color = "grey50", 
#                     force = 1, max.overlaps = 10
#                     #color = c(rep("black", 35), ggsci::pal_lancet()(2)[2], rep("black", 20339))
#                     ) +
#     scale_color_manual(values = c(ggsci::pal_lancet()(2)), guide = "none") +
#     scale_x_continuous(limits = c(-0.6, 0.6)) +
#     labs(x = "Log2 fold change with Gcg",
#          y = "-log10(p-value)")
# ggsave("results/pdf/230427_volcanoplot_noline.pdf", width = 5, height = 5, device = "pdf")    
# ggsave("results/svg/230427_volcanoplot_noline.svg", width = 5, height = 5, device = "svg")
# ggsave("results/png/230427_volcanoplot_noline.png", width = 5, height = 5, device = "png") 
