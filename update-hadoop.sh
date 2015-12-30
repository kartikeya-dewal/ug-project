#!/bin/sh

# This script uses the set-*.sh scripts for setting master/slaves
# and replication level for hadoop. It requires that HADOOP_HOME
# is set and that the scripts are in the correct position.

# designed to run through SSH non-interactively
source /etc/profile

DIR=`dirname $0`

# verify configuration
if [ ! -e $DIR/hadoop-cc.conf ]; then
	echo "Couldn't find the conf file."
	exit 1
fi

if [ ! -e $DIR/set-masters.sh ]; then
	echo "Set masters not found."
	exit 1
fi

if [ ! -e $DIR/set-slaves.sh ]; then
	echo "Set slaves not found."
	exit 1
fi

if [ ! -e $DIR/set-replication.sh ]; then
	echo "Set replication not found."
	exit 1
fi

# read from the configuration file
. $DIR/hadoop-cc.conf

for SL in $HADOOP_SLAVES
do
	if [ ! -z $SLAVES ]; then
		SLAVES=$SLAVES:
	fi
	SLAVES=$SLAVES$SL
done

# read replication level and master
REP_LVL=$HADOOP_REPLICATION_LEVEL
MASTER=$HADOOP_MASTER

# execute the hadoop scripts
$DIR/set-masters.sh $MASTER
$DIR/set-slaves.sh $SLAVES
$DIR/set-replication.sh $REP_LVL

IP=`ifconfig eth0 | sed -n 2p | cut -d ":" -f2 | cut -d " " -f1`
echo "Updated $IP."

exit 0
