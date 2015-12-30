#!/bin/sh

# Updates the local hadoop configuration files to the new
# master given. 


# verify configuration
if [ $# -lt 1 ]; then
	echo "No master value set"
	exit 1
fi

CONF_PATH="$HADOOP_HOME/conf"
MASTER=$1

# remove the old configuration files
rm -f $CONF_PATH/masters
rm -f $CONF_PATH/core-site.xml
rm -f $CONF_PATH/mapred-site.xml

# copy the skeletons
cp $HADOOP_HOME/scripts/default/masters $CONF_PATH
cp $HADOOP_HOME/scripts/default/core-site.xml $CONF_PATH
cp $HADOOP_HOME/scripts/default/mapred-site.xml $CONF_PATH

# enter the new master value
sed -i "s/{MASTER}/$MASTER/g" $CONF_PATH/masters
sed -i "s/{MASTER}/$MASTER/g" $CONF_PATH/core-site.xml
sed -i "s/{MASTER}/$MASTER/g" $CONF_PATH/mapred-site.xml

echo "Masters set."
exit 0
