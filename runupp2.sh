#!/bin/bash

set -x

module load jdk64 
module load perl
module load pyhton

H=/work/01721/smirarab/1kp/capstone/secondset
T=FAA
INPUT=$1.input.$T
C=$2

CD=$H/genes/$1

cd $CD
mkdir logs

# Find median sequence length for the genomes (i.e., sequences with a _ in their name)
seq=`grep "_" $CD/$INPUT|wc -l|sed -e "s:$: / 2:g"|bc`
median=`grep -A1 "_" $CD/$INPUT |grep -v ">"|awk '{print length($0)}'|sort -n|head -n $seq|tail -n1`

echo Expected sequence length is set to $median letters > $CD/logs/std.out.upp.$T.$1

tmp=`mktemp -d`
#$H/run-upp-wrapper.sh -s $CD/$INPUT -B 100000 -M $median -T 0.66 -m amino -x $C -o $T -d $CD/upp  1>>$CD/logs/std.out.upp.$T.$1 2>$CD/logs/std.err.upp.$T.$1

if [ -s $CD/upp/${T}_alignment.fasta ]; then
 ln -sf upp/${T}_alignment.fasta ${T}-upp-unmasked.fasta
 if [ -s upp/${T}_alignment_masked.fasta ]; then
   ln -sf upp/${T}_alignment_masked.fasta ${T}-upp-masked.fasta
 else 
  test "`grep -l 'No query' $CD/logs/std.err.upp.$T.$1`" != ""  && ( ln -s FAA_alignment.fasta upp/FAA_alignment_masked.fasta ) 
 fi
 # derive other form of the alignment (fna and fna-c12)
 if [ "$T" == "FAA" ]; then
    # translate back to fna
    perl $HOME/workspace/global/src/perl/pepMfa_to_cdsMfa.pl FAA-upp-unmasked.fasta $1.input.FNA 1>FNA2AA-upp-unmasked.fasta;
    # mask insertion sites from fna alignment
    $H/mask-insertion.sh .
    # remove 1st and 2nd codon positions
    $HOME/workspace/global/src/shell/create_1stAnd2ndcodon_alignment.sh FNA2AA-upp-masked.fasta FNA2AA-upp-masked-c12.fasta FNA2AA-upp-masked-c12.part; 
 fi
 echo "Done">.done.$T.upp
fi 
