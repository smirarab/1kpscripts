#!/bin/bash
set -x

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
H=/work/01721/smirarab/1kp/capstone/secondset

test $# == 7 || exit 1

ALGNAME=$1
DT=$2
CPUS=$3
ID=$4
label=$5
bestN=$6
rep=$7

S=raxml
in=$DT-$ALGNAME
boot="-x $RANDOM"
s="-p $RANDOM"
dirn=raxmlboot.$in.$label

cd $H/genes/$ID/
mkdir logs

$HOME/workspace/global/src/shell/convert_to_phylip.sh $in.fasta $in.phylip
test "`head -n 1 $in.phylip`" == "0 0" && exit 1

if [ "$DT" == "FAA" ]; then
  if [ -s bestModel.$ALGNAME ]; then
    echo bestModel.$ALGNAME exists
  else
    mkdir modelselection
    cd modelselection
    ln -s ../$in.phylip .
    perl $DIR/ProteinModelSelection.pl $in.phylip > ../bestModel.$ALGNAME
    cd ..
    tar cfj modelselection-logs.tar.bz --remove-files modelselection
  fi
  model=PROTGAMMA`sed -e "s/.* //g" bestModel.$ALGNAME`
else
  model=GTRGAMMA
fi

mkdir $dirn
cd $dirn

#Figure out if main ML has already finished
donebs=`grep "Overall execution time" RAxML_info.best`
#Infer ML if not done yet
if [ "$donebs" == "" ]; then
 rm RAxML*best.back
 rename "best" "best.back" *best
 # Estimate the RAxML best tree
 if [ $CPUS -gt 1 ]; then
  $DIR/raxmlHPC-PTHREADS -m $model -T $CPUS -n best -s ../$in.phylip $s -N $bestN &> ../logs/best_std.errout.$in
 else
  $DIR/raxmlHPC -m $model -n best -s ../$in.phylip $s -N $bestN &> ../logs/best_std.errout.$in
 fi
fi
 

if [ $rep == 0 ]; then
   mv logs-best.tar.bz logs-best.tar.bz.back.$RANDOM
   tar cvfj logs-best.tar.bz --remove-files RAxML_log.* RAxML_parsimonyTree.* RAxML_*back*  RAxML_result.best.*
   if [ -s RAxML_bestTree.best ]; then
    cd ..
    echo "Done">.done.best.$dirn
    exit 0
   fi
   exit 1
fi

#Figure out if bootstrapping has already finished
donebs=`grep "Overall Time" RAxML_info.ml`
#Bootstrap if not done yet
if [ "$donebs" == "" ]; then
  crep=$rep
  # if bootstrapping is partially done, resume from where it was left
  if [ `ls RAxML_bootstrap.ml*|wc -l` -ne 0 ]; then
    l=`cat RAxML_bootstrap.ml*|wc -l|sed -e "s/ .*//g"`
    crep=`expr $rep - $l`
  fi
  if [ -s RAxML_bootstrap.ml ]; then
    cp RAxML_bootstrap.ml RAxML_bootstrap.ml.$l
  fi
  rename "ml" "back.ml" *ml
  rm RAxML_info.ml
  if [ $crep -gt 0 ]; then
   if [ $CPUS -gt 1 ]; then
      $DIR/raxmlHPC-PTHREADS -m $model -n ml -s ../$in.phylip -N $crep $boot -T $CPUS  $s &> ../logs/ml_std.errout.$in
   else
      $DIR/raxmlHPC -m $model -n ml -s ../$in.phylip -N $crep $boot $s &> ../logs/ml_std.errout.$in
   fi
  fi
fi

if [ ! -s RAxML_bootstrap.all ] || [ `cat RAxML_bootstrap.all|wc -l` -ne $rep ]; then
 cat  RAxML_bootstrap.ml* > RAxML_bootstrap.all
fi

 
if [ ! `wc -l RAxML_bootstrap.all|sed -e "s/ .*//g"` -eq $rep ]; then
 echo `pwd`>>$H/notfinishedproperly
 exit 1
else
 #Finalize 
 rename "final" "final.back" *final
 $DIR/raxmlHPC -f b -m $model -n final -z RAxML_bootstrap.all -t RAxML_bestTree.best

 if [ -s RAxML_bipartitions.final ]; then
   mv logs.tar.bz logs.tar.bz.back.$RANDOM
   tar cvfj logs.tar.bz --remove-files RAxML_log.* RAxML_parsimonyTree.* RAxML_*back* RAxML_bootstrap.ml RAxML_result.best.* RAxML_bootstrap.ml* RAxML_info.final
   cd ..
   echo "Done">.done.$dirn
 fi
fi

