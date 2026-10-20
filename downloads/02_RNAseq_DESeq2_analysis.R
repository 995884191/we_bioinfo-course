# ============================================================
# 生物信息学入门：R / RStudio 与 RNA-seq 差异表达分析
# 输入：
#   data/rnaseq_counts.csv
#   data/sample_metadata.csv
# 输出：results/ 下的 QC 图、差异表达表、火山图、热图
# 数据是模拟的教学数据，不代表真实实验。
# ============================================================

# 0. 设置工作目录
# 建议在 RStudio 中打开本项目文件夹作为 Project。
# 若不是从项目根目录运行，请修改 setwd()。
# setwd("你的项目根目录")
dir.create("results", showWarnings = FALSE)

# 1. 安装并加载 CRAN 包（首次运行安装）
cran_pkgs <- c("ggplot2", "pheatmap", "ggrepel")
for (p in cran_pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
}
library(ggplot2)
library(pheatmap)
library(ggrepel)

# DESeq2 属于 Bioconductor。首次安装时取消下方注释运行一次：
# if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
# BiocManager::install("DESeq2")
if (!requireNamespace("DESeq2", quietly = TRUE)) {
  stop("未检测到 DESeq2。请先运行：if (!requireNamespace('BiocManager')) install.packages('BiocManager'); BiocManager::install('DESeq2')")
}
library(DESeq2)

# 2. 读取数据
counts_df <- read.csv("data/rnaseq_counts.csv", row.names = 1, check.names = FALSE)
meta <- read.csv("data/sample_metadata.csv", stringsAsFactors = FALSE)

# 样本信息行顺序必须与 count matrix 列顺序一致
stopifnot(all(meta$sample %in% colnames(counts_df)))
counts_df <- counts_df[, meta$sample, drop = FALSE]
rownames(meta) <- meta$sample
meta$condition <- factor(meta$condition, levels = c("Control", "Treatment"))
stopifnot(identical(colnames(counts_df), rownames(meta)))
stopifnot(all(as.matrix(counts_df) >= 0))
stopifnot(all(as.matrix(counts_df) == round(as.matrix(counts_df))))

cat("Count matrix dimensions:", dim(counts_df), "\n")
cat("Sample metadata:\n")
print(meta)
cat("Counts summary:\n")
print(summary(as.vector(as.matrix(counts_df))))

# 3. 过滤低表达基因
# 教学阈值：至少在 4 个样本中 count >= 10。真实项目应结合测序深度与设计决定。
keep <- rowSums(counts_df >= 10) >= 4
counts_filt <- as.matrix(counts_df[keep, , drop = FALSE])
cat("Genes before filtering:", nrow(counts_df), "\n")
cat("Genes after filtering:", nrow(counts_filt), "\n")

# 4. DESeq2 差异表达分析
dds <- DESeqDataSetFromMatrix(
  countData = round(counts_filt),
  colData = meta,
  design = ~ condition
)
dds <- DESeq(dds)
res <- results(dds, contrast = c("condition", "Treatment", "Control"), alpha = 0.05)
res_df <- as.data.frame(res)
res_df$gene_id <- rownames(res_df)
res_df <- res_df[order(res_df$padj, na.last = TRUE), ]
write.csv(res_df, "results/deseq2_all_results.csv", row.names = FALSE)

# 标记显著差异基因：示例阈值 padj < 0.05 且 |log2FC| >= 1
res_df$significance <- "Not significant"
res_df$significance[!is.na(res_df$padj) & res_df$padj < 0.05 & res_df$log2FoldChange >= 1] <- "Up"
res_df$significance[!is.na(res_df$padj) & res_df$padj < 0.05 & res_df$log2FoldChange <= -1] <- "Down"
write.csv(subset(res_df, significance != "Not significant"),
          "results/deseq2_significant_results.csv", row.names = FALSE)

# 5. PCA：使用 VST 转换后的表达矩阵
vsd <- vst(dds, blind = FALSE)
pca <- plotPCA(vsd, intgroup = "condition", returnData = TRUE)
percentVar <- round(100 * attr(pca, "percentVar"))
p_pca <- ggplot(pca, aes(PC1, PC2, color = condition, label = name)) +
  geom_point(size = 3) +
  geom_text_repel(show.legend = FALSE, size = 3) +
  xlab(paste0("PC1: ", percentVar[1], "% variance")) +
  ylab(paste0("PC2: ", percentVar[2], "% variance")) +
  ggtitle("PCA of VST-transformed counts") +
  theme_bw(base_size = 12)
ggsave("results/PCA.png", p_pca, width = 7, height = 5, dpi = 300)
ggsave("results/PCA.pdf", p_pca, width = 7, height = 5)

# 6. 火山图
volcano_df <- res_df
volcano_df$neglog10padj <- -log10(pmax(volcano_df$padj, .Machine$double.xmin))
volcano_df$significance <- factor(volcano_df$significance,
                                  levels = c("Down", "Not significant", "Up"))
p_volcano <- ggplot(volcano_df, aes(log2FoldChange, neglog10padj, color = significance)) +
  geom_point(alpha = 0.75, size = 1.4, na.rm = TRUE) +
  scale_color_manual(values = c("Down" = "#2878B5",
                               "Not significant" = "grey75",
                               "Up" = "#D9534F")) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = "grey40") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "grey40") +
  labs(title = "Differential expression: Treatment vs Control",
       x = "log2 fold change", y = "-log10 adjusted p-value", color = NULL) +
  theme_bw(base_size = 12)
ggsave("results/volcano.png", p_volcano, width = 7, height = 5, dpi = 300)
ggsave("results/volcano.pdf", p_volcano, width = 7, height = 5)

# 7. 热图：选择 padj 最小的前 30 个基因，使用 VST 表达值按基因标准化
top_genes <- res_df$gene_id[!is.na(res_df$padj)]
top_genes <- head(top_genes, 30)
if (length(top_genes) >= 2) {
  mat <- assay(vsd)[top_genes, , drop = FALSE]
  annotation_col <- data.frame(condition = meta$condition)
  rownames(annotation_col) <- rownames(meta)
  png("results/heatmap_top30.png", width = 1800, height = 1500, res = 200)
  pheatmap(mat,
           scale = "row",
           annotation_col = annotation_col,
           show_rownames = TRUE,
           fontsize_row = 7,
           main = "Top 30 genes (VST; row Z-score)")
  dev.off()
  pdf("results/heatmap_top30.pdf", width = 8, height = 7)
  pheatmap(mat,
           scale = "row",
           annotation_col = annotation_col,
           show_rownames = TRUE,
           fontsize_row = 7,
           main = "Top 30 genes (VST; row Z-score)")
  dev.off()
}

# 8. 样本距离热图（QC）
sample_dists <- dist(t(assay(vsd)))
sample_dist_mat <- as.matrix(sample_dists)
rownames(sample_dist_mat) <- colnames(sample_dist_mat) <- colnames(vsd)
png("results/sample_distance_heatmap.png", width = 1400, height = 1200, res = 180)
pheatmap(sample_dist_mat, annotation_col = data.frame(condition = meta$condition,
         row.names = rownames(meta)), main = "Sample-to-sample distances")
dev.off()

# 9. 导出标准化表达矩阵（仅用于可视化/下游探索，不作为 DESeq2 输入）
norm_counts <- counts(dds, normalized = TRUE)
write.csv(norm_counts, "results/normalized_counts_for_exploration.csv")

cat("\\n完成。请查看 results/ 文件夹。\\n")
cat("重要提醒：这是模拟数据；DESeq2 输入必须是原始整数 count，不要将 TPM/FPKM 作为 countData。\\n")
