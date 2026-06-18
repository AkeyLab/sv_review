#!/bin/bash
# Convert a VCF to Zarr format using vcf2zarr (bio2zarr package).
# Suitable for HGSVC3 and ONT datasets (single VCF file).
# For per-chromosome SRWGS data, add '#SBATCH --array=[1-22]' and
# incorporate ${SLURM_ARRAY_TASK_ID} into INPUT_VCF / OUTPUT_ICF / OUTPUT_VCZ.

#SBATCH --job-name=vcf2zarr
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --output=vcf2zarr_%j.out
#SBATCH --error=vcf2zarr_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=8G
#SBATCH --time=48:00:00
#SBATCH --mail-type=end
#SBATCH --mail-user=your.email@institution.edu

# ---- configure paths -------------------------------------------------------
INPUT_VCF="/path/to/input.vcf.gz"
OUTPUT_ICF="/path/to/output.icf"   # intermediate chunked format (temporary)
OUTPUT_VCZ="/path/to/output.vcz"   # final Zarr store
# ----------------------------------------------------------------------------

source ~/.bashrc
conda activate bio2zarr

vcf2zarr explode \
    -p "${SLURM_CPUS_PER_TASK}" \
    --force \
    "${INPUT_VCF}" \
    "${OUTPUT_ICF}"

vcf2zarr encode \
    -p "${SLURM_CPUS_PER_TASK}" \
    "${OUTPUT_ICF}" \
    "${OUTPUT_VCZ}"

rm -r "${OUTPUT_ICF}"
