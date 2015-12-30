#!/bin/sh

# Updates the local hadoop configuration files to the new slaves given.

# verify configuration
if [ $# -lt 1 ]; then
	echo "No slaves set"
	echo "Usage: set-slaves.sh XXXXX:XXXXXX:XXXXX"
	exit 1
fi

IN=$1
CONF_PATH="$HADOOP_HOME/conf"

# cut the slaves
SLAVES=$(echo $IN | tr ":" "\n")

# remove the old configuration files
rm -f $CONF_PATH/slaves

# copy the skeletons
cp $HADOOP_HOME/scripts/default/slaves $CONF_PATH

# entering the slaves
for SLAVE in $SLAVES
do
	echo "$SLAVE " >> $CONF_PATH/slaves
done

echo "Slaves set."
exit 0
