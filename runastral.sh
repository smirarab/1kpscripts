#!/bin/bash

x=`basename $1`
cd `dirname $1`

java -jar /projects/sate4/smirarab/1kp-capstone//Astral/astral.4.7.8.jar -i $x -o astral-$x.tre -m 596  2> astral-$x.log > astral-$x.out
