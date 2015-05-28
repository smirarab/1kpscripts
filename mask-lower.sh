#!/bin/bash

x=$1; 

torem=`python -c "import sys; import re; print '\n'.join('\n'.join(str(x.start()) for x in re.finditer('[a-z]',l)) for l in open(sys.argv[1]) if not l.startswith('>'))" $x|sort -n|uniq|tail -n+2 |awk 'BEGIN{p=-2;b=-2} {if ($0!=p+1) {print b"-"p; b=$0; }; p=$0;} END{print b"-"p;}'|tail -n+2 |tr '\n' ',' |sed -e "s/,$//g"`

trimal -selectcols { $torem } -in $x -out $x.lowermasked
