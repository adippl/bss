#!/bin/sh
dir=$1
sub=$2
snaps=$3

function checkFree(){
	if (( $(df $dir |awk 'NR==2 {print $5}' |sed 's/%//') > 95 )) ; then 
		return true
	else
		return false
	fi
	}

for x in $(seq 30 -10 10) ; do
	if checkFree ; then
		cleaner $x
		fi
	done


function cleaner(){
	cd $dir
	for x in $(ls -d1 $sub-r-*|sort -r|sed -n $1',$p'); do 
		btrfs sub del $x
		done
	cd -
	}
