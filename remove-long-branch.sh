#!/bin/bash

med=3

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#cat genes/*/??? > ??? 
#python $DIR/find-long-branches-2.py ???? $med > filter-lb-aa-$med

paste <( cat filter-lb-aa-$med |tr  '\n' ';'|tr ':' '\n'|sed -e "s/;;.*$/;/g"|sed -e "s/[^;]*;//"|sed -e "s/ [^;]*;/|/g"|sed -e "s/|$//"|tail -n+2 ) <( ls genes/*/FAA-upp-masked.fasta.mask10sites.mask33taxa.fasta ) |sed -e "s/\t/,/g" |xargs -n1 echo remove_taxon_from_fasta.sh|sed -e 's/ / "/g' -e 's/,/" /g'| grep -v '""'| awk '{print $0, "> ",$3"-filterbln"}'|sed -e "s/.fasta-filterbln/-filterbln-$med.fasta/g" > rem-aa-$med.sh

bash rem-aa-$med.sh

paste <( cat filter-lb-fna2aa-$med |tr  '\n' ';'|tr ':' '\n'|sed -e "s/;;.*$/;/g"|sed -e "s/[^;]*;//"|sed -e "s/ [^;]*;/|/g"|sed -e "s/|$//"|tail -n+2 ) <( ls genes/*/FNA2AA-upp-masked-c12.fasta.mask10sites.mask33taxa.fasta ) |sed -e "s/\t/,/g" |xargs -n1 echo remove_taxon_from_fasta.sh|sed -e 's/ / "/g' -e 's/,/" /g'| grep -v '""'| awk '{print $0, "> ",$3"-filterbln"}'|sed -e "s/.fasta-filterbln/-filterbln-$med.fasta/g" > rem-dna-$med.sh

bash rem-dna-$med.sh

for x in genes/*; do ln -s FNA2AA-upp-masked-c12.fasta.mask10sites.mask33taxa.fasta $x/FNA2AA-upp-masked-c12.fasta.mask10sites.mask33taxa-filterbln-$med.fasta; done

for x in genes/*; do ln -s FAA-upp-masked.fasta.mask10sites.mask33taxa.fasta $x/FAA-upp-masked.fasta.mask10sites.mask33taxa-filterbln-$med.fasta; done
