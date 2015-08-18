#!/bin/bash

set -e
set -x

med=3

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

y=$1 # FNA2AA-upp-masked-c12.fasta.mask10sites.mask33taxa  FAA-upp-masked.fasta.mask10sites.mask33taxa
x=raxmlboot.$y.rapid

cat genes/*/$x/RAxML_bestTree.best > $x
test `cat $x |wc -l` != `ls genes|wc -l` && { echo "not enough gene trees?"; exit 1; } 

python $DIR/root.py $x
python $DIR/find-long-branches-2.py $x.rerooted $med > filter-lb-$med-$x

paste <( cat filter-lb-$med-$x |tr  '\n' ';'|tr ':' '\n'|sed -e "s/;;.*$/;/g"|sed -e "s/[^;]*;//"|sed -e "s/ [^;]*;/|/g"|sed -e "s/|$//"|tail -n+2 ) <( ls genes/*/$y.fasta ) |sed -e "s/\t/,/g" |xargs -n1 echo remove_taxon_from_fasta.sh|sed -e 's/ / "/g' -e 's/,/" /g'| grep -v '""'| awk '{print $0, "> ",$3"-filterbln"}'|sed -e "s/.fasta-filterbln/-filterbln-$med.fasta/g" > rem-lb-$med-$x.sh

bash rem-lb-$med-$x.sh

unset -e

for f in genes/*; do ln -s $y.fasta $f/$y-filterbln-$med.fasta; done

