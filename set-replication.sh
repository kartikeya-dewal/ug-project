#!/bin/sh

# Edit the replication level of the HDFS system.

# verify configuration
if [ $# -lt 1 ]; then
	echo "No replication number given"
	echo "Usage: set-replication.sh <number>"
	exit 1
fi

IN=$1
CONF_PATH="$HADOOP_HOME/conf"

# remove the old configuration files
rm -f $CONF_PATH/hdfs-site.xml

# copy the skeletons
cp $HADOOP_HOME/scripts/default/hdfs-site.xml $CONF_PATH

# entering the slaves
sed -i "s/{REPLICATION_NUMBER}/$1/g" $CONF_PATH/hdfs-site.xml

# fix the ownership
#chown -R ubuntu:ubuntu $CONF_PATH

echo "Replication level set."
exit 0
