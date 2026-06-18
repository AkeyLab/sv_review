#!/bin/bash
# Population structure analysis for SRWGS SNP data.
# Merges per-chromosome LD-pruned PLINK files (from 03_vcf_to_plink_snps_array.sbatch),
# then runs genome-wide PCA and ADMIXTURE.

#SBATCH --job-name=snp_popstruct
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --output=snp_popstruct_%j.out
#SBATCH --error=snp_popstruct_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=8G
#SBATCH --time=48:00:00
#SBATCH --mail-type=end
#SBATCH --mail-user=your.email@institution.edu

# ---- configure paths -------------------------------------------------------
# Per-chromosome PLINK prefix (without the .chr{N} part)
CHR_PREFIX="/path/to/output/data.chr"
CHR_SUFFIX="_ld_pruned"
OUTPUT_PREFIX="/path/to/output/data.autosomes_ld_pruned"
ADMIXTURE_K=5
# ----------------------------------------------------------------------------

source ~/.bashrc
conda activate your_env

# Build merge list (chr1 first, then chr2-22)
echo "${CHR_PREFIX}1${CHR_SUFFIX}" > files_to_merge.txt
seq 2 22 | xargs -I {} echo "${CHR_PREFIX}{}${CHR_SUFFIX}" >> files_to_merge.txt

plink2 --pmerge-list files_to_merge.txt \
    --threads "${SLURM_CPUS_PER_TASK}" \
    --make-pgen \
    --out "${OUTPUT_PREFIX}"

plink2 --pmerge-list files_to_merge.txt \
    --threads "${SLURM_CPUS_PER_TASK}" \
    --make-bed \
    --out "${OUTPUT_PREFIX}"

plink2 --pfile "${OUTPUT_PREFIX}" \
    --pca 100 \
    --threads "${SLURM_CPUS_PER_TASK}" \
    --out "${OUTPUT_PREFIX}"

admixture --cv -j"${SLURM_CPUS_PER_TASK}" "${OUTPUT_PREFIX}.bed" "${ADMIXTURE_K}"
