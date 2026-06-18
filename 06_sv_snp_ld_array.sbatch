#!/bin/bash
# Merge SV calls (giggles) with SNP calls (srWGS) per chromosome, convert to
# PGEN, then compute LD (r²) between SVs and SNPs.
# Runs as a SLURM array job (one task per autosome).

#SBATCH --job-name=sv_snp_ld
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --output=sv_snp_ld_%A_%a.out
#SBATCH --error=sv_snp_ld_%A_%a.err
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=16G
#SBATCH --time=48:00:00
#SBATCH --mail-type=end
#SBATCH --mail-user=your.email@institution.edu
#SBATCH --array=[1-22]

# ---- configure paths -------------------------------------------------------
CHR="${SLURM_ARRAY_TASK_ID}"
SAMPLE_LIST="/path/to/giggles_shared_sample_ids.txt"
SRWGS_DIR="/path/to/1KGP_T2T_Rhie_et_al_Nature_2023"
SRWGS_VCF="${SRWGS_DIR}/chr${CHR}.recalibrated.snp_indel.pass.vcf.gz"
SRWGS_SUBSET_VCF="${SRWGS_DIR}/chr${CHR}.recalibrated.snp_indel.pass.samples_present_in_1kgp_ont_vienna.vcf.gz"
GIGGLES_VCF="/path/to/giggles-genotyping_final-vcf.unphased_simple_var_ids.vcf.gz"
MERGED_VCF="/path/to/output/giggles-genotyping_final-vcf.unphased_simple_var_ids.and.gatk_smvar_calls.chr${CHR}.vcf.gz"
MERGED_PREFIX="/path/to/output/giggles-genotyping_final-vcf.unphased_simple_var_ids.and.gatk_smvar_calls.chr${CHR}"
OUTPUT_PREFIX="${MERGED_PREFIX}"
# ----------------------------------------------------------------------------

source ~/.bashrc
conda activate your_env

bcftools view -S "${SAMPLE_LIST}" \
    --threads "${SLURM_CPUS_PER_TASK}" \
    -Oz -o "${SRWGS_SUBSET_VCF}" \
    "${SRWGS_VCF}"

tabix "${SRWGS_SUBSET_VCF}"

bcftools concat \
    -a \
    -r chr${CHR} \
    --threads "${SLURM_CPUS_PER_TASK}" \
    -Oz \
    -o "${MERGED_VCF}" \
    "${GIGGLES_VCF}" \
    "${SRWGS_SUBSET_VCF}"

plink2 \
    --vcf "${MERGED_VCF}" \
    --make-pgen \
    --out "${MERGED_PREFIX}"

plink2 \
    --pfile "${MERGED_PREFIX}" \
    --r2-unphased 'ref-based' 'allow-ambiguous-allele' \
    --ld-window-kb 1000 \
    --ld-window 9999 \
    --threads "${SLURM_CPUS_PER_TASK}" \
    --memory 60000 \
    --out "${OUTPUT_PREFIX}"
