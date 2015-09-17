#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

x=`basename $1`
cd `dirname $1`


java -jar $DIR/Astral/astral.4.7.8.jar -i $x -o astral-$x.tre -m 589  2> astral-$x.log > astral-$x.out
