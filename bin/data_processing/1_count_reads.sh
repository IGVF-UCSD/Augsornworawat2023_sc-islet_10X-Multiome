#mamba activate get_data

seqkit stats \
--threads 24 \
--tabular /cellar/users/aklie/data/datasets/Zhu2023_sc-islet_scRNA-seq/fastq/24Oct23/SRP374217/*/*.fastq.gz \
> /cellar/users/aklie/data/datasets/Zhu2023_sc-islet_scRNA-seq/metadata/24Oct23/fastq_stats.tsv
