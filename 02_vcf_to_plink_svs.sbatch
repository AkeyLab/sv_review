#!/bin/bash
# Convert an SV VCF (HGSVC3 or ONT) to PLINK2 PGEN format.
# Variant IDs are simplified from graph-path notation to chr-pos-type-length.

#SBATCH --job-name=vcf2plink_svs
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --output=vcf2plink_svs_%j.out
#SBATCH --error=vcf2plink_svs_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=8G
#SBATCH --time=48:00:00
#SBATCH --mail-type=end
#SBATCH --mail-user=your.email@institution.edu

# ---- configure paths -------------------------------------------------------
INPUT_VCF="/path/to/svs.vcf.gz"
OUTPUT_PREFIX="/path/to/svs_simple_var_ids"
# ----------------------------------------------------------------------------

source ~/.bashrc
conda activate your_env

# Simplify variant IDs to chr-pos-type-length (fields 1, 2, 3, 5 of '-'-delimited ID)
bcftools view "${INPUT_VCF}" | awk 'BEGIN{FS=OFS="\t"}
    /^#/ {print; next}
    {
        n=split($3,a,"-");
        $3 = a[1] "-" a[2] "-" a[3] "-" a[5];
        print
    }' | bgzip -c > "${OUTPUT_PREFIX}.vcf.gz"

tabix "${OUTPUT_PREFIX}.vcf.gz"

plink2 \
    --vcf "${OUTPUT_PREFIX}.vcf.gz" \
    --make-pgen \
    --autosome \
    --out "${OUTPUT_PREFIX}"
