# Prompt user if they want to remove all files in the slurm_logs directory
read -p "Are you sure you want to remove all files in the slurm_logs directory? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    rm -f ./slurm_logs/*
fi
