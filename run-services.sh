#!/bin/sh

# It reads the hadoop-cc.conf file to determine the master(s) 
# of the cluster and then, if defined, formats the
# namenode and starts Hadoop services.

USAGE="usage: run-services.sh [-f] [-i] [-p privatekey]"

if [ ! -e hadoop-cc.conf ]; then
	echo "Configuration file not found"
	exit 1
fi

FORMAT="N"
PKEY="-"
IPTABLES="N"

# verify options
while getopts "fip:" opt; do
case $opt in

	f)
	FORMAT="Y"
	;;

	p)
	PKEY=$OPTARG
	echo "Using private key: $PKEY"
	;;

	i)
	IPTABLES="Y"
	;;

	\?)
	echo "Invalid option: -$OPTARG" >&2
	echo "$USAGE" >&2
	exit 1
	;;

	:)
	echo "Option -$OPTARG requires an argument." >&2
	echo "$USAGE" >&2
	exit 1
	;;
esac
done

# set up the ssh command structure
SSH="ssh ubuntu@"
if [ $PKEY != "-" ]; then
	SSH="ssh -i $PKEY ubuntu@"
fi

. ./hadoop-cc.conf

MASTER=$HADOOP_MASTER
HADOOP_HOME=$HADOOP_INSTANCE_HOME

# Fix the iptables issues of eucalyptus
for SL in $HADOOP_SLAVES
do
	PUB_IP=`$SSH$SL "curl -m 10 -s http://172.16.14.72:8773/latest/meta-data/public-ipv4"`
	LOC_IP=`$SSH$SL "curl -m 10 -s http://172.16.14.72:8773/latest/meta-data/local-ipv4"`

	sudo iptables -t nat -D POSTROUTING -s "$LOC_IP" -j SNAT --to-source "$PUB_IP"
	sudo iptables -t nat -A POSTROUTING -s "$LOC_IP" -j SNAT --to-source "$PUB_IP"

	# Each hadoop instance must know the master node
	$SSH$MASTER "ssh -o StrictHostKeyChecking=no $SL hostname"
done

# Format the namenode
if [ $FORMAT = "Y" ]; then
	$SSH$MASTER "$HADOOP_HOME/bin/hadoop namenode -format"
fi

# Start all hadoop services (Namenode/DataNode/JobTracker/TaskTracker)
$SSH$MASTER "$HADOOP_HOME/bin/start-all.sh"

if [ $IPTABLES = "Y" ]; then
	echo "# IPTABLES"
	sudo iptables -t nat -L
fi

echo "# Hadoop services running ! "

exit 0
