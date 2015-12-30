#!/bin/sh

#
# Terminates the services of cluster specified in the configuration file. This will ensure
# that the NAT rules corresponding to the eucalyptus instances are removed and
# the HDFS/MapReduce daemons on the instances are terminated.
#

USAGE="usage: stop-services.sh [-i] [-p privatekey]"

if [ ! -e hadoop-cc.conf ]; then
	echo "Configuration file not found"
	exit 1
fi

PKEY="-"
IPTABLES="N"

# verify what we want to do
while getopts "ip:" opt; do
case $opt in
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

# stop the hadoop services
$SSH$MASTER "$HADOOP_HOME/bin/stop-all.sh"

for SL in $HADOOP_SLAVES
do
	PUB_IP=`$SSH$SL "curl -m 10 -s http://172.16.14.72:8773/latest/meta-data/public-ipv4"`
	LOC_IP=`$SSH$SL "curl -m 10 -s http://172.16.14.72:8773/latest/meta-data/local-ipv4"`

	sudo iptables -t nat -D POSTROUTING -s "$LOC_IP" -j SNAT --to-source "$PUB_IP"
done

if [ $IPTABLES = "Y" ]; then
	echo "# IPTABLES"
	sudo iptables -t nat -L
fi

echo "# Hadoop services terminated ! ";

exit 0
