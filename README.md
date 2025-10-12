# schwammerlRohr 
*A Bioinformatics Pipeline for Semi-Supervised Symbiotic Metagenome Binning*

---

## Overview
**schwammerlRohr** is a modular, reproducible bioinformatics pipeline designed for **semi-supervised binning of symbiotic metagenomes**, integrating long-read sequencing data, genome assembly, and quality assessment.

The workflow is built with **[Snakemake](https://snakemake.github.io/)** and incorporates multiple established bioinformatics tools within **Singularity containers** for consistent and portable execution.

---

## Features
- **Reproducible**: containerized with Singularity for consistent environments  
- **Modular**: easily extendable for new tools or analysis steps  
- **Semi-supervised binning**: integrates fungal and algal/plant metagenomes  
- **Long-read compatible**: optimized for PacBio data  
- **Automated reporting**: generates summary HTML reports with `mycoBinR`

---

## Pipeline Components
| Step | Tool | Purpose |
|------|------|----------|
| Quality control | LongQC | Assess raw long-read quality |
| Assembly | Flye | Assemble long-read genomes |
| Coverage mapping | CoverM | Compute coverage per contig |
| Completeness check | BUSCO | Assess genome completeness |
| Taxonomic annotation | DIAMOND | Protein-based taxonomic classification |
| Telomere detection | TelFinder | Identify telomeric repeats |
| Reporting | mycoBinR | Generate R-based summary report |

---

## Installation

### 1. Clone the repository
```bash
git clone https://github.com/taui11/schwammerlRohr.git
cd schwammerlRohr
```

### 2. Run the setup script
This script checks if the required Singularity images are there and creates the folder structure
```bash
chmod +x ./bin/setup.sh # make the file executable
./bin/setup.sh # run setup
```

### 3. Add your data
Place your input `.fastq.gz`files in:
```
PacBio_data/
```

### 4. Configure the pipeline variables

Open **`bin/Snakefile`** and edit the section labeled
`Changeable Variables`
to match your project setup:

```python
API_KEY = ""        # NCBI-API key for mycoBinR report generation
DIAMOND_DB = "/path/to/the/DiamondDB/nr_diamond.dmnd"  # Path to DIAMOND database
```

### 5. Launch the pipeline
Following example uses `nr_001.hifireads.fastq.gz, nr_002.hifireads.fastq.gz, nr_003.hifireads.fastq.gz` as input files.
```bash
snakemake \
  --cores 20 \
  --snakefile ./bin/Snakefile \
  --use-singularity \
  --config project_nr=nr_ samples=001,002,003
```
If there are problems running snakemake try to activate a conda environment for snakemake.

---

## Project Structure
```python
schwammerlRohr/
├── bin/                  # Scripts and Snakemake rules
|   ├── singularity/      # Singularity image files
|   ├── definitions/      # Singularity definitions
|   ├── report.rmd        # Rmd file for the final report (using mycoBinR)
|   ├── setup.sh          # Setup file
|   └── Snakefile         # Snakefile for runing the pipeline
├── PacBio_data/          # Input data
├── PacBio_output/        # Pipeline output
└── README.md             # This file
```

---

## Requirements

* **Linux environment**
* **Snakemake ≥8.0**
* **Singularity (or Apptainer) ≥3.8**

---

## Related Project
This pupeline integrates with the R package
**[mycoBinR](https://github.com/taui11/mycoBinR)**
for downstream analysis and report generation.

## Acknowledgments
Developed as part of the Bachelor's Thesis project at the Institute of Biomedical Informatics, TU Graz.

Special thanks to the open-source bioinformatics community for providing all integrated tools.

