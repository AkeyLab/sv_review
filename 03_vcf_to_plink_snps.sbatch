#!/bin/bash
# Convert per-chromosome SRWGS VCFs to PLINK2 PGEN format and LD-prune SNPs.
# Runs as a SLURM array job (one task per autosome).
# Produces both PGEN and BED outputs for downstream merging and ADMIXTURE.

#SBATCH --job-name=vcf2plink_snps
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --output=vcf2plink_snps_%A_%a.out
#SBATCH --error=vcf2plink_snps_%A_%a.err
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=8G
#SBATCH --time=4:00:00
#SBATCH --mail-type=end
#SBATCH --mail-user=your.email@institution.edu
#SBATCH --array=[1-22]

# ---- configure paths -------------------------------------------------------
CHR="${SLURM_ARRAY_TASK_ID}"
INPUT_VCF="/path/to/data.chr${CHR}.vcf.gz"
OUTPUT_PREFIX="/path/to/output/data.chr${CHR}"
SAMPLES_TO_KEEP="samples_to_keep.txt"  # set to "" to skip sample filtering
# ----------------------------------------------------------------------------

source ~/.bashrc
conda activate your_env

plink2 \
    --vcf "${INPUT_VCF}" \
    --make-pgen \
    --snps-only \
    --keep "${SAMPLES_TO_KEEP}" \
    --out "${OUTPUT_PREFIX}"

plink2 --pfile "${OUTPUT_PREFIX}" \
    --indep-pairwise 100kb 1 0.1 \
    --maf 0.01 \
    --geno 0.01 \
    --out "${OUTPUT_PREFIX}"

plink2 --pfile "${OUTPUT_PREFIX}" \
    --extract "${OUTPUT_PREFIX}.prune.in" \
    --make-pgen \
    --out "${OUTPUT_PREFIX}_ld_pruned"

plink2 --pfile "${OUTPUT_PREFIX}" \
    --extract "${OUTPUT_PREFIX}.prune.in" \
    --make-bed \
    --out "${OUTPUT_PREFIX}_ld_pruned"
