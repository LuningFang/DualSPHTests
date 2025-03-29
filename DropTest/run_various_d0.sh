#!/usr/bin/env zsh
#SBATCH --gres=gpu:a100:1
#SBATCH --time=10-0:0:0
#SBATCH --partition=sbel
#SBATCH -o dualSPH_%A_%a.out
#SBATCH -e dualSPH_%A_%a.err
#SBATCH --account=sbel
#SBATCH --qos=priority
##SBATCH --mem-per-cpu=20000
##SBATCH --cpus-per-task=8
##SBATCH --mem=40G

#SBATCH --array=1-5
module load nvidia/cuda/12.0.0
module load gcc/11.3.0

nvidia-smi

# Define arrays for parameters
coefh_array=(0.635 0.866 0.981 1.097 1.155)

# Get array index from SLURM
id=$SLURM_ARRAY_TASK_ID

# Get parameters for this run
coefh=${coefh_array[${id}]}

# Navigate to the DualSPH test directory
cd DropTest

# Print parameters for this run
echo "Running DualSPH simulation with parameters:"
echo "coefh=${coefh}"

# Run the simulation with the parameters
./run_linux_floating.sh ${coefh}