#!/bin/bash
#SBATCH --partition=carter-compute
#SBATCH --output=/cellar/users/aklie/data/datasets/Zhu2023_sc-islet_snATAC-seq/bin/data_annotation/cellcommander/slurm_logs/%x.%A_%a.out
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G 
#SBATCH --time=02-00:00:00
#SBATCH --array=1-5%5

#####
# USAGE:
# sbatch --job-name=igvf_sc-islet_10X-Multiome_ATAC_pipeline_cleanup ATAC.sh
#####

# Date
date
echo -e "Job ID: $SLURM_JOB_ID\n"

# Configuring env (choose either singularity or conda)
source activate /cellar/users/aklie/opt/miniconda3/envs/cellcommander

indir_paths=(
    '/cellar/users/aklie/data/datasets/Zhu2023_sc-islet_snATAC-seq/processed/23Oct23/cellranger/MM129/outs'
    '/cellar/users/aklie/data/datasets/Zhu2023_sc-islet_snATAC-seq/processed/23Oct23/cellranger/MM157/outs'
    '/cellar/users/aklie/data/datasets/Zhu2023_sc-islet_snATAC-seq/processed/23Oct23/cellranger/MM166/outs'
    '/cellar/users/aklie/data/datasets/Zhu2023_sc-islet_snATAC-seq/processed/23Oct23/cellranger/MM168/outs'
    '/cellar/users/aklie/data/datasets/Zhu2023_sc-islet_snATAC-seq/processed/23Oct23/cellranger/MM290/outs'
)
sample_ids=(
    'MM129'
    'MM157'
    'MM166'
    'MM168'
    'MM290'
)
indir_path=${indir_paths[$SLURM_ARRAY_TASK_ID-1]}
sample_id=${sample_ids[$SLURM_ARRAY_TASK_ID-1]}
outdir_path=/cellar/users/aklie/data/datasets/Zhu2023_sc-islet_snATAC-seq/annotation/26Oct23/cellcommander/${sample_id}

# If output dir does not exist, create it
if [ ! -d $outdir_path ]; then
    mkdir -p $outdir_path
fi

# Step 1 -- QC and filtering
echo -e "Running step 1 -- QC and filtering\n"
metadata_path=$indir_path/singlecell.csv
cmd="cellcommander qc \
--input_h5_path $indir_path/filtered_peak_bc_matrix.h5 \
--outdir_path $outdir_path/threshold_qc \
--output_prefix threshold_qc \
--metadata_path $metadata_path \
--metadata_source cellranger \
--mode atac \
--filtering_strategy threshold \
--total_counts_low 1000 \
--total_counts_hi 60000 \
--n_features_low 1000 \
--n_for_ns_calc 1000 \
--ns_hi 1.5 \
--n_tss 1000 \
--tss_low 4 \
--tss_hi 18 \
--random-state 1234"
echo -e "Running:\n $cmd\n"
#eval $cmd
echo -e "Done with step 1\n"

# Step 2 -- Detect doublets
echo -e "Running step 2 -- Detect doublets\n"
cmd="cellcommander detect-doublets \
--input_h5ad_path $outdir_path/threshold_qc/threshold_qc.h5ad \
--outdir_path $outdir_path/detect_doublets \
--output_prefix amulet_only \
--method amulet"
echo -e "Running:\n $cmd\n"
eval $cmd
echo -e "Done with step 2\n"

# Step 3 -- Normalize data
echo -e "Running step 3 -- Normalize data\n"
cmd="cellcommander normalize \
--input_h5ad_path $outdir_path/detect_doublets/amulet_only.h5ad \
--outdir_path $outdir_path/normalize \
--output_prefix tfidf_only \
--save-normalized-mtx \
--methods tfidf \
--log-tf-idf True"
echo -e "Running:\n $cmd\n"
eval $cmd
echo -e "Done with step 3\n"

# Step 4 -- Select features
echo -e "Running step 4 -- Select features\n"
cmd="cellcommander select-features \
--input_h5ad_path $outdir_path/normalize/tfidf_only.h5ad \
--outdir_path $outdir_path/select_features \
--output_prefix signac_only \
--methods signac \
--layer counts"
echo -e "Running:\n $cmd\n"
eval $cmd
echo -e "Done with step 4\n"

# Step 5 -- Reduce dimensionality
echo -e "Running step 5 -- Reduce dimensionality\n"
cmd="cellcommander reduce-dimensions \
--input_h5ad_path $outdir_path/select_features/signac_only.h5ad \
--outdir_path $outdir_path/reduce_dimensions \
--output_prefix muon_lsi \
--method lsi \
--layer tfidf_norm \
--variable-features-key highly_variable_signac \
--scale-data \
--components-to-remove 0"
echo -e "Running:\n $cmd\n"
eval $cmd
echo -e "Done with step 5\n"

date
