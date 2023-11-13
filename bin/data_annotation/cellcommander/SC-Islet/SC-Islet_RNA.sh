#!/bin/bash
#SBATCH --partition=carter-compute
#SBATCH --output=/cellar/users/aklie/data/datasets/Augsornworawat2023_sc-islet_10X-Multiome/bin/data_annotation/cellcommander/slurm_logs/%x.%A_%a.out
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=32G
#SBATCH --time=01-00:00:00
#SBATCH --array=1-1%1

#####
# USAGE:
# sbatch --job-name=Augsornworawat2023_sc-islet_10X-Multiome_RNA_pipeline SC-Islet_RNA.sh
#####

# Date
date
echo -e "Job ID: $SLURM_JOB_ID\n"

# Configuring env (choose either singularity or conda)
source activate /cellar/users/aklie/opt/miniconda3/envs/cellcommander

indir_paths=(
    /cellar/users/aklie/data/datasets/Augsornworawat2023_sc-islet_10X-Multiome/processed/10Nov23/cellranger/SC-Islet_1/outs
)
sample_ids=(
    SC-Islet_1
)
indir_path=${indir_paths[$SLURM_ARRAY_TASK_ID-1]}
sample_id=${sample_ids[$SLURM_ARRAY_TASK_ID-1]}
outdir_path=/cellar/users/aklie/data/datasets/Augsornworawat2023_sc-islet_10X-Multiome/annotation/11Nov23/cellcommander/${sample_id}/rna

# If output dir does not exist, create it
if [ ! -d $outdir_path ]; then
    mkdir -p $outdir_path
fi

# Step 1 -- QC and filtering
echo -e "Running step 1 -- QC and filtering in two modes\n"
metadata_path=$indir_path/per_barcode_metrics.csv
cmd="cellcommander qc \
--input_h5_path $indir_path/raw_feature_bc_matrix.h5 \
--outdir_path $outdir_path/mad_qc \
--metadata_path $metadata_path \
--metadata_source cellranger \
--output_prefix mad_qc \
--multimodal_input \
--mode rna \
--filtering_strategy mad \
--total_counts_nmads 2 \
--n_features_nmads 2 \
--pct_counts_mt_hi 10 \
--random-state 1234"
echo -e "Running:\n $cmd\n"
eval $cmd

cmd="cellcommander qc \
--input_h5_path $indir_path/raw_feature_bc_matrix.h5 \
--outdir_path $outdir_path/threshold_qc \
--metadata_path $metadata_path \
--metadata_source cellranger \
--output_prefix threshold_qc \
--mode rna \
--filtering_strategy threshold \
--n_features_low 1000 \
--n_features_hi 10000 \
--pct_counts_mt_hi 10 \
--random-state 1234"
echo -e "Running:\n $cmd\n"
eval $cmd
echo -e "Done with step 1\n"

# Step 2 -- Background removal
soupx_marker_path=/cellar/users/aklie/data/datasets/igvf_sc-islet_10X-Multiome/annotation/14Sep22/seurat/sc_islet_genelist.txt
echo -e "Running step 2 -- Background removal\n"
cmd="cellcommander remove-background \
--input_h5ad_path $outdir_path/threshold_qc/threshold_qc.h5ad \
--outdir_path $outdir_path/remove_background \
--method soupx \
--raw-h5-path $indir_path/raw_feature_bc_matrix.h5 \
--markers_path $soupx_marker_path \
--layer soupx_counts
--random-state 1234"
echo $cmd
eval $cmd
echo -e "Done with step 2\n"

# Step 3 -- Detect doublets
echo -e "Running step 3 -- Detect doublets\n"
cmd="cellcommander detect-doublets \
--input_h5ad_path $outdir_path/remove_background/remove_background.h5ad \
--outdir_path $outdir_path/detect_doublets \
--output_prefix scrublet_only \
--method scrublet \
--random-state 1234"
echo -e "Running:\n $cmd\n"
eval $cmd
echo -e "Done with step 3\n"

# Step 4 -- Normalize data
echo -e "Running step 4 -- Normalize data\n"
cmd="cellcommander normalize \
--input_h5ad_path $outdir_path/detect_doublets/scrublet_only.h5ad \
--outdir_path $outdir_path/normalize \
--output_prefix sctransform_only \
--save-normalized-mtx \
--methods sctransform \
--random-state 1234"
echo -e "Running:\n $cmd\n"
eval $cmd
echo -e "Done with step 4\n"

# Step 4 -- Reduce dimensionality
echo -e "Running step 5 -- Reduce dimensionality\n"
cmd="cellcommander reduce-dimensions \
--input_h5ad_path $outdir_path/normalize/sctransform_only.h5ad \
--outdir_path $outdir_path/reduce_dimensions \
--output_prefix scanpy_default_pca \
--method scanpy_default \
--obsm_key sctransform_scale_data \
--random-state 1234"
echo -e "Running:\n $cmd\n"
eval $cmd
echo -e "Done with step 5\n"

date
