#!/bin/sh

# Connects all the nodes and sets the proper variables.
# The master generates rsa-keypair that is distributed across all the slaves.
# Variables are injected into the hadoop configuration.


USAGE="usage: connect-instances.sh [-k] [-h] [-p private-key]"

if [ ! -e hadoop-cc.conf ]; then
	echo "Configuration file not found";
	exit 1
fi

KEYGEN="Y"
PKEY="-"
HOSTS="N"

# Verify options
while getopts "khp:" opt; do
case $opt in

	k)
	KEYGEN="N"
	;;

	h)
	HOSTS="Y"
	;;

	p)
	PKEY=$OPTARG
	echo "Using private key: $PKEY"
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

# Setup the ssh command structure
SSH="ssh ubuntu@"
if [ $PKEY != "-" ]; then
	SSH="ssh -i $PKEY ubuntu@"
fi

. ./hadoop-cc.conf

MASTER=$HADOOP_MASTER

# master: ssh public key generation and distribution
if [ $KEYGEN = "Y" ]; then
	echo "# Generating SSH Publc Key...";
	# create the key
	$SSH$MASTER "ssh-keygen -t rsa -P \"\" -f /home/ubuntu/.ssh/id_rsa.pub"
	# fetch the key
	RSA_KEY=`$SSH$MASTER cat /home/ubuntu/.ssh/id_rsa.pub`
	echo "$RSA_KEY" > master_rsa_key_tmp

	echo "# Distributing SSH Public Key across slaves...";
	# for each slave we add the key
	for SL in $HADOOP_SLAVES
	do
		$SSH$SL "cat >> /home/ubuntu/.ssh/authorized_keys" < master_rsa_key_tmp
	done
	rm -f master_rsa_key_tmp
fi

# we need to have all the ip-fqdn pairs inside the /etc/hosts of all the nodes
echo "# Building /etc/hosts hosts file...";
echo "127.0.0.1\t\tlocalhost.$HOSTNAME localhost" > nodes_hosts_tmp
for SL in $HADOOP_SLAVES
do
        PUB_IP=`$SSH$SL "curl -m 10 -s http://172.16.14.72:8773/latest/meta-data/public-ipv4"`
	PRIV_IP=`$SSH$SL "curl -m 10 -s http://172.16.14.72:8773/latest/meta-data/local-ipv4"`
        FQDN=`$SSH$SL "curl -m 10 -s http://172.16.14.72:8773/latest/meta-data/hostname"`
	PRIV_FQDN=`$SSH$SL "curl -m 10 -s http://172.16.14.72:8773/latest/meta-data/local-hostname"`

# save the IP and FQDN pair to distribute it across all the slaves
	echo "$PRIV_IP\t\t$FQDN\n$PRIV_IP\t\t$PRIV_FQDN\n$PUB_IP\t\t$FQDN" >> nodes_hosts_tmp
done

if [ $HOSTS = "Y" ]; then
        echo "# /etc/hosts file";
        cat nodes_hosts_tmp
fi

# add the gathered hosts
echo "# Distributing /etc/hosts file across the nodes...";
for SL in $HADOOP_SLAVES
do
        $SSH$SL "cat > /etc/hosts" < nodes_hosts_tmp
done
rm -f nodes_hosts_tmp

# iterate through all the slaves and add the configuration
echo "# Updating Hadoop configuration at each node...";
for SL in $HADOOP_SLAVES
do
	$SSH$SL "cat > /opt/hadoop/scripts/hadoop-cc.conf" < hadoop-cc.conf
	$SSH$SL "/opt/hadoop/scripts/update-hadoop.sh"
done

# ready to run!
echo "# Hadoop instances connected ! ";

exit 0
