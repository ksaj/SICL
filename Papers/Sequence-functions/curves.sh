#!/bin/sh

# if less than two arguments supplied, display usage 
if [ "$#" -lt 1 ]
then 
	echo "\nusage: $0 file"
	exit 1
fi

NAME=$1

GP=$NAME.gp

TITLE="Comparison between two find functions (SBCL/SICL)"
echo gp=$GP
OUTPUT=eps

cat << _EOF_ > $GP
set term $OUTPUT dashed
set output "$NAME.$OUTPUT"
set title "$TITLE"
set key on inside center top
set xlabel "List length"
set ylabel "Time in seconds"
_EOF_

STRING="'"$NAME"'"
echo STRING=$STRING

SAVE-IFS=$IFS

IFS='-'
set
TYPE=$0
TEST=$1
KEY=$2
IFS=$SAVE-IFS

echo plot '\' >> $GP

N=2
for i in $FIELDS ;
do 
	echo FIELD=$i N=$N
	echo "    " $STRING using 1:$N title \'$i\' with lines ',\' >> $GP
	N=$(expr $N + 1)
done
