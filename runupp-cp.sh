#!/bin/bash

test $# == 3 || echo USAGE: $0 gene_id num_cpus genedir
test $# == 3 || exit 1

module load jdk64 
module load perl
module load python/2.7.3-epd-7.3.2

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

H=$3
T=faa
INPUT=$1.$T
INPUTFNA=$1.fna
C=$2

CD=$H/genes/$1

cd $CD
mkdir logs

# Find median sequence length for the genomes (i.e., sequences with a _ in their name)
seq=`grep "_" $CD/$INPUT|wc -l|sed -e "s:$: / 2:g"|bc`
median=`grep -A1 "_" $CD/$INPUT |grep -v ">"|awk '{print length($0)}'|sort -n|head -n $seq|tail -n1`

echo Expected sequence length is set to $median letters > $CD/logs/std.out.upp.FAA.$1

tmp=`mktemp -d`
$DIR/run-upp-wrapper.sh -s $CD/$INPUT -B 100000 -M $median -T 0.66 -m amino -x $C -o FAA -d $CD/upp  1>>$CD/logs/std.out.upp.FAA.$1 2>$CD/logs/std.err.upp.FAA.$1

if [ -s $CD/upp/${T}_alignment.fasta ]; then
 ln -sf upp/${T}_alignment.fasta ${T}-upp-unmasked.fasta
 test "`grep -l 'No query' $CD/logs/std.err.upp.FAA.$1`" != ""  && ( ln -s ${T}_alignment.fasta upp/${T}_alignment_masked.fasta ) 
 if [ -s upp/${T}_alignment_masked.fasta ]; then
   ln -sf upp/${T}_alignment_masked.fasta ${T}-upp-masked.fasta
 else 
   echo "ERROR: no masked version of the ${T} alignment found."
   err=T
 fi
 # derive other form of the alignment (fna and fna-c12)
 if [ "$T" == "faa" ] || [ "$T" == "FAA" ]; then
    # translate back to fna
    perl $HOME/workspace/global/src/perl/pepMfa_to_cdsMfa.pl ${T}-upp-unmasked.fasta $INPUTFNA 1>FNA2AA-upp-unmasked.fasta;
    # mask insertion sites from fna alignment
    $DIR/mask-insertion.sh .
    # remove 1st and 2nd codon positions
    $HOME/workspace/global/src/shell/create_1stAnd2ndcodon_alignment.sh FNA2AA-upp-masked.fasta FNA2AA-upp-masked-c12.fasta FNA2AA-upp-masked-c12.part; 
 fi
 test "$err" == "T" || ( echo "Done">.done.FAA.upp )
fi 
