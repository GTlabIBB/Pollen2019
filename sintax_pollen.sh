#!/bin/sh

#pipeline to analyze sequencing data from pollen metabarcoding 
#classification and quantification of each reads for a plant species
#raw reads from sequencing are stored in a folder /path/to/rawreads
#reads were sequenced paired-end
#-------------------------------- 

#create new directories to store data for each analysis step
mkdir 2-merged/
mkdir 3-cleaned/
mkdir 4-filtered/
mkdir 5-dereplicated/
mkdir 6-classification/

#OPTIONAL: if necessary, rename rawreads with your sample names 
#sequencing centres rename the samples for their purposes
for f in /path/to/rawreads/*_1.fastq.gz
do
rev=${f/_1.fastq.gz/_2.fastq.gz}
a=$(basename $f | sed 's/_1.fastq.gz//g')
b=$(grep $n file_with_names.csv| optional changes | awk '{OFS=""} {print $1,"_1"}' )
c=$(grep $n file_with_names.csv| optional changes | awk '{OFS=""} {print $1,"_2"}' )
cp $f 1-rawreads/$b.fastq.gz
cp $rev 1-rawreads/$c.fastq.gz
done

#MERGE paired-end reads
for fvd in /1-rawreads/*_1.fastq.gz
do
rev=${fvd/_1.fastq.gz/_2.fastq.gz}
out=$(basename $fvd | sed 's/.\{39\}$//g')
pear -j $THREADS -f $fvd -r $rev -o 2-merged/$out 2>&1 | tee 2-merged/$out.assembled.log
done

# TRIM primers
for f in 2-merged/*.assembled.fastq
do
out=$(basename $f | sed 's/.assembled.fastq//g') 
cutadapt -a N{7}TGCGATACTTGGTGTGAAT...GCATATCAATAAGCGGAGGAN{6} \
         --discard-untrimmed \
         -O 26 \
         -o 3-cleaned/$out.trimmed.assembled.fastq $f 2>&1 | tee 3-cleaned/$out.trimmed.assembled.log
done

# FILTER reads
for f in 3-cleaned/*.trimmed.assembled.fastq
do
out=$(basename $f | sed 's/.trimmed.assembled.fastq//g')
label=${out/-/}
vsearch --threads $THREADS \
        --fastq_filter  $f \
        --fastq_maxee 1 \
        --fastq_minlen 250 \
        --fastq_maxns 0 \
        --fastaout 4-filtered/$out.fitered.trimmed.assembled.fasta \
        --fasta_width 0 \
        --relabel $label. 2>&1 | tee 4-filtered/$out.filtered.trimmed.assembled.log
done

# DEREPLICATE reads  for each sample and rename reads with sample id
for f in 4-filtered/*.fitered.trimmed.assembled.fasta
do
out=$(basename $f | sed 's/.filtered.trimmed.assembled.fasta//g')
label=${out/-/}
vsearch --threads $THREADS \
        --derep_fulllength $f \
        --strand plus \
        --output 5-dereplicated/$out.derep.filtered.trimmed.assembled.fasta \
        --sizeout \
        --uc 5-dereplicated/$out.derep.uc \
        --relabel $label. \
        --fasta_width 0 2>&1 | tee 5-dereplicated/$out.derep.filtered.trimmed.assembled.log
done

# MERGE filtered samples together
cat 5-dereplicated/*.fitered.trimmed.assembled.fasta > all.fasta


#DEREPLICATE all reads
vsearch --derep_fulllength all.fasta \
        --threads $THREADS \
        --sizein \
        --sizeout \
        --fasta_width 0 \
        --uc all.derep.uc \
        --output 6-classification/derep.fasta

#CLUSTER reads with 98% similarity & save centroid sequences
vsearch --cluster_size 6-classification/derep.fasta \
        --threads $THREADS \
        --id 0.98 \
        --strand plus \
        --sizein \
        --sizeout \
        --fasta_width 0 \
        --centroids 6-classification/otus.centroids.fasta

# SORT reads by size and REMOVE singletons (clusters with only one sequence)
vsearch --sortbysize 6-classification/otus.centroids.fasta \
        --threads $THREADS \
        --sizein \
        --sizeout \
        --fasta_width 0 \
        --minsize 2 \
        --output 6-classification/otus.sorted.fasta
        
# DE NOVO CHIMERA DETECTION in clustered and denoised sequences
vsearch --uchime_denovo 6-classification/otus.sorted.fasta \
        --sizein \
        --sizeout \
        --fasta_width 0 \
        --qmask none \
        --nonchimeras 6-classification/otus.nonchimeras.fasta

#RELABEL OTUs
vsearch --fastx_filter 6-classification/otus.nonchimeras.fasta \
        --threads $THREADS \
        --sizein \
        --sizeout \
        --fasta_width 0 \
        --relabel OTU_ \
        --fastaout 6-classification/otus.fasta

# MAP sequences before clustering back to OTUs/ZOTUs => gives a tab-separated list how often wich OTU is found in each sample
vsearch --usearch_global all.fasta \
        --threads $THREADS \
        --db 6-classification/otus.fasta \
        --id 0.98 \
        --strand plus \
        --sizein \
        --sizeout \
        --fasta_width 0 \
        --qmask none \
        --dbmask none \
        --otutabout 6-classification/otutab.txt 2>&1 | tee 6-classification/otutab.log

# CLASSIFY OTUs/ZOTUs => classification of OTUs 
#sintax will give a list for each OTU:
#first part: for each taxonomic rank the most probable is given plus probability 
#second part: if you entered a cutoff then the rank where probability is below cutoff
# example: OTU_10;size=180926	k:Viridiplantae(1.00),p:Streptophyta(1.00),o:Asterales(1.00),f:Asteraceae(1.00),g:Galactites(0.94),s:Galactites_tomentosus(0.94)	k:Viridiplantae,p:Streptophyta,o:Asterales,f:Asteraceae

vsearch --sintax 6-classification/otus.fasta \
        --db its.viridiplantae.fa \
        --tabbedout 6-classification/otus.sintax.txt \
        --strand both \
        --sintax_cutoff 0.95

#OPTIONAL: change otutab.txt to a komma-separated file 
python3 txt2csv.py 6-classification/otutab.txt 6-classification/otutab.csv

#COMBINE occurence of each OTU in each sample with OTU classification and classification probability on species level
python3 sintax_species.py otus.sintax.txt otutab.csv otutab.final.csv

