#!/bin/bash
# Population structure analysis for SV datasets (ONT or HGSVC3).
# Filters SVs by length (>= 50 bp), splits by type (DEL, INS, COMPLEX),
# then runs LD pruning, PCA, and ADMIXTURE on each SV class and all SVs combined.
# Requires PGEN files produced by 02_vcf_to_plink_svs.sbatch.

#SBATCH --job-name=sv_popstruct
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --output=sv_popstruct_%j.out
#SBATCH --error=sv_popstruct_%j.err
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=8G
#SBATCH --time=48:00:00
#SBATCH --mail-type=end
#SBATCH --mail-user=your.email@institution.edu

# ---- configure paths -------------------------------------------------------
PLINK_PREFIX="/path/to/svs_simple_var_ids"  # output prefix from 02_vcf_to_plink_svs.sbatch
OUTPUT_DIR="/path/to/output"
ADMIXTURE_K=5
# ----------------------------------------------------------------------------

source ~/.bashrc
conda activate your_env

mkdir -p "${OUTPUT_DIR}"

# Extract unique SV IDs with length >= 50 bp
cut -f3 "${PLINK_PREFIX}.pvar" \
    | awk -F '-' 'BEGIN{OFS="\t"}{print $0, $NF}' \
    > "${OUTPUT_DIR}/svs_with_length.tab"

awk '{if ($2 >= 50) print $1}' "${OUTPUT_DIR}/svs_with_length.tab" \
    | grep -v "^#" | grep -v "^ID" \
    | sort | uniq -c | awk '{if ($1 == 1) print $2}' \
    > "${OUTPUT_DIR}/sv_all_ids.txt"

grep DEL     "${OUTPUT_DIR}/sv_all_ids.txt" > "${OUTPUT_DIR}/sv_del_ids.txt"
grep INS     "${OUTPUT_DIR}/sv_all_ids.txt" > "${OUTPUT_DIR}/sv_ins_ids.txt"
grep COMPLEX "${OUTPUT_DIR}/sv_all_ids.txt" > "${OUTPUT_DIR}/sv_complex_ids.txt"

# LD pruning, PCA, and ADMIXTURE for each SV class
for SVTYPE in all del ins complex; do
    ID_FILE="${OUTPUT_DIR}/sv_${SVTYPE}_ids.txt"
    OUT="${OUTPUT_DIR}/svs_${SVTYPE}"

    plink2 --pfile "${PLINK_PREFIX}" \
        --indep-pairwise 100kb 1 0.1 --maf 0.01 --geno 0.01 \
        --extract "${ID_FILE}" \
        --out "${OUT}"

    plink2 --pfile "${PLINK_PREFIX}" \
        --extract "${OUT}.prune.in" \
        --make-pgen --out "${OUT}"

    plink2 --pfile "${PLINK_PREFIX}" \
        --extract "${OUT}.prune.in" \
        --make-bed --out "${OUT}"

    plink2 --pfile "${OUT}" \
        --pca 100 \
        --threads 1 \
        --out "${OUT}"

    admixture --cv -j"${SLURM_CPUS_PER_TASK}" "${OUT}.bed" "${ADMIXTURE_K}"
done
