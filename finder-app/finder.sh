#!/bin/sh
filesdir=$1
searchstr=$2

if [ -z "$filesdir" ] || [ -z "$searchstr" ] 
then
   echo "Arguments invalid"
   exit 1
fi

if [ ! -d "$filesdir" ]
then 
   echo "$filesdir not a directory";
   exit 1
fi
files=$(find $filesdir -type f)
result=$(grep -i  "$searchstr" $files)

occurrences=$(echo -e "$result" | wc -l)
number_of_files=$(find $filesdir -type f | wc -l)

echo "The number of files are $number_of_files and the number of matching lines are $occurrences"

exit 0
