#!/bin/sh

writefile=$1
writestr=$2

if [ -z "$writefile" ] || [ -z "$writestr" ]
then
	echo "Arguments invalid"
	exit 1
fi

dir=$(dirname $writefile)
if [ ! -d $dir ]; then
	mkdir -p $dir
fi

echo $writestr > $writefile



