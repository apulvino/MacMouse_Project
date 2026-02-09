#!/bin/bash

#SBATCH --account=b1057
#SBATCH --partition=b1057
#SBATCH --job-name=buns
#SBATCH --output=buns.out
#SBATCH --error=buns.err
#SBATCH --time=00:3:00
#SBATCH --mem=80G
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mail-user=apulvino@u.northwestern.edu
#SBATCH --mail-type=END

#source activate krakenuniq
# don't  worry this issss actually the env that has the krakenuniq you want in it
source activate kneaddata

db=/projects/b1042/AmatoLab/apulvino/b1042_cecalshotgun_ATPulvino_2023/krakenuniq2/DBDIR
reports_dir=k2_reports
bracken_dir=/home/atp1458/Bracken-2.9
bracken=/home/atp1458/Bracken-2.9/bracken
bracken_outs=/projects/b1042/AmatoLab/apulvino/b1042_cecalshotgun_ATPulvino_2023/krakenuniq2

#Abundance estimation with braken (phylum, genus, species)

mkdir bracken
mkdir bracken/species
mkdir bracken/genus
mkdir bracken/phylum

cp $db/database150mers.kraken $db/database150mers.kraken_copy
$bracken_dir/src/generate_kmer_distribution.py -i $db/database150mers.kraken_copy -o $db/database150mers.kmer_distrib

for i in $reports_dir/*_report.txt
do
  filename=$(basename "$i")
  fname="${filename%_report.txt}"
  /home/atp1458/Bracken-2.9/bracken -d $db \
  -i $i -r 150 -l S -o $bracken_outs/${fname}_report_species.txt
done
rm *_species.txt
#mv *_bracken.txt bracken/species/.
mv $reports_dir/*_species.txt bracken/species/.

for i in $reports_dir/*_report.txt
do
  filename=$(basename "$i")
  fname="${filename%_report.txt}"
  /home/atp1458/Bracken-2.9/bracken -d $db \
  -i $i -r 150 -l G -o $bracken_outs/${fname}_report_genus.txt
done
rm *_genus.txt
#mv *_bracken.txt bracken/genus/.
mv $reports_dir/*_genuses.txt bracken/genus/.

for i in $reports_dir/*_report.txt
do
  filename=$(basename "$i")
  fname="${filename%_report.txt}"
  /home/atp1458/Bracken-2.9/bracken -d $db \
  -i $i -r 150 -l P -o $bracken_outs/${fname}_report_phylum.txt
done
rm *_phylum.txt
#mv *_.txt bracken/phylum/.
mv $reports_dir/*_phylums.txt bracken/phylum/.

#Generating combined abundance tables in mpa format
mkdir bracken/species/mpa
mkdir bracken/genus/mpa
mkdir bracken/phylum/mpa

for i in bracken/species/*_species.txt
do
  filename=$(basename "$i")
  fname="${filename%_report_bracken.txt}"
  kreport2mpa.py -r $i -o bracken/species/mpa/${fname}_mpa.txt --display-header
done

mkdir bracken/species/mpa/combined
combine_mpa.py -i bracken/species/mpa/*_mpa.txt -o bracken/species/mpa/combined/combined_species_mpa.txt
grep -E "(s__)|(#Classification)" bracken/species/mpa/combined/combined_species_mpa.txt > bracken/species/mpa/combined/bracken_abundance_species_mpa.txt

for i in bracken/genus/*_genuses.txt
do
  filename=$(basename "$i")
  fname="${filename%_report_bracken.txt}"
  kreport2mpa.py -r $i -o bracken/genus/mpa/${fname}_mpa.txt --display-header
done

mkdir bracken/genus/mpa/combined
combine_mpa.py -i bracken/genus/mpa/*_mpa.txt -o bracken/genus/mpa/combined/combined_genus_mpa.txt
grep -E "(g__)|(#Classification)" bracken/genus/mpa/combined/combined_genus_mpa.txt > bracken/genus/mpa/combined/bracken_abundance_genus_mpa.txt


for i in bracken/phylum/*_phylums.txt
do
  filename=$(basename "$i")
  fname="${filename%_report_bracken.txt}"
  kreport2mpa.py -r $i -o bracken/phylum/mpa/${fname}_mpa.txt --display-header
done

mkdir bracken/phylum/mpa/combined
combine_mpa.py -i bracken/phylum/mpa/*_mpa.txt -o bracken/phylum/mpa/combined/combined_phylum_mpa.txt
grep -E "(p__)|(#Classification)" bracken/phylum/mpa/combined/combined_phylum_mpa.txt > bracken/phylum/mpa/combined/bracken_abundance_phylum_mpa.txt


#Cleaning up sample names
sed -i -e 's/_report_bracken.txt//g' bracken/species/mpa/combined/bracken_abundance_species_mpa.txt
sed -i -e 's/_report_bracken.txt//g' bracken/genus/mpa/combined/bracken_abundance_genus_mpa.txt
sed -i -e 's/_report_bracken.txt//g' bracken/phylum/mpa/combined/bracken_abundance_phylum_mpa.txt



#Cleaning up top-level folders
mkdir bracken/bracken_abundance_files

cp bracken/species/mpa/combined/bracken_abundance_species_mpa.txt bracken/bracken_abundance_files/
cp bracken/genus/mpa/combined/bracken_abundance_genus_mpa.txt bracken/bracken_abundance_files/
cp bracken/phylum/mpa/combined/bracken_abundance_phylum_mpa.txt bracken/bracken_abundance_files/


