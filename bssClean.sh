#!/bin/sh
cd $1
for x in $(ls -d1 $2-r-*|sort -r|sed -n '30,$p'); do 
	btrfs sub del $x
	done
cd -
