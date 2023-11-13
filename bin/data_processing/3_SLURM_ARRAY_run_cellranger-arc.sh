#!/bin/bash
#SBATCH --partition=carter-compute
#SBATCH --output=/cellar/users/aklie/data/datasets/Augsornworawat2023_sc-islet_10X-Multiome/bin/data_processing/slurm_logs/%x.%A_%a.out
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=14-00:00:00
#SBATCH --array=1-18%18

#####
# USAGE:
# sbatch --job-name=Augsornworawat2023_sc-islet_10X-Multiome_run_cellranger-arc 3_SLURM_ARRAY_run_cellranger-arc.sh
#####

# Start time
date
echo -e "Job ID: $SLURM_JOB_ID\n"

# Env
source /cellar/users/aklie/.bashrc

# Set file paths
csv_dir=/cellar/users/aklie/data/datasets/Augsornworawat2023_sc-islet_10X-Multiome/metadata/09Nov23
output_dir=/cellar/users/aklie/data/datasets/Augsornworawat2023_sc-islet_10X-Multiome/processed/11Nov23/cellranger

# If output directory does not exist, create it
if [ ! -d $output_dir ]; then
    mkdir -p $output_dir
fi

# Samples
sample_ids=(
    CRISPRA_SC-Islet_CTCF_Doxycycline
    CRISPRA_SC-Islet_CTCF_Untreated_Control
    Human_Islet_1
    Human_Islet_2
    Human_Islet_3
    Human_Islet_4
    SC-Islet_1
    SC-Islet_2
    SC-Islet_ARID1B_knockdown
    SC-Islet_GFP_Control
    SC-Islet_Stage6_month_12
    SC-Islet_Stage6_month_6
    SC-Islet_Stage6_week_2
    SC-Islet_Stage6_week_3
    SC-Islet_Stage6_week_4
    Transplanted_SC-Islet_1
    Transplanted_SC-Islet_2
    Transplanted_SC-Islet_3
)
sample=${sample_ids[$SLURM_ARRAY_TASK_ID-1]}
input_csv=$csv_dir/${sample_ids[$SLURM_ARRAY_TASK_ID-1]}.csv

# Go to output directory
cd $output_dir

# Run the command
cmd="cellranger-arc count \
--id=$sample \
--reference=/cellar/users/aklie/opt/refdata-cellranger-arc-GRCh38-2020-A-2.0.0 \
--libraries=$input_csv \
--localcores=12"
echo -e "Running:\n $cmd\n"
eval $cmd

# End time
date
