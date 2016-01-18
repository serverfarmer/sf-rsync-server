#!/bin/bash
. /opt/farm/scripts/functions.uid
. /opt/farm/scripts/functions.custom
# create local account with rsync access and ssh key, ready to connect Windows
# computer(s) with cwRsync and backup them inside local (eg. office) network
# Tomasz Klim, Aug 2014, Jan 2016


MINUID=1200
MAXUID=1299


if [ "$1" = "" ]; then
	echo "usage: $0 <user> [remote-server[:port]]"
	exit 1
elif ! [[ $1 =~ ^[a-z0-9]+$ ]]; then
	echo "error: parameter $1 not conforming user name format"
	exit 1
elif [ -d /srv/rsync/$1 ]; then
	echo "error: user $1 exists"
	exit 1
fi

uid=`get_free_uid $MINUID $MAXUID`

if [ $uid -lt 0 ]; then
	echo "error: no free UIDs"
	exit 1
fi

if [ "$2" != "" ]; then
	server=$2

	if ! [[ $server =~ ^[a-z0-9.-]+[.][a-z0-9]+([:][0-9]+)?$ ]]; then
		echo "error: parameter 2 not conforming host name format"
		exit 1
	fi

	if [ -z "${server##*:*}" ]; then
		host="${server%:*}"
		port="${server##*:}"
	else
		host=$server
		port=22
	fi

	if [ "`getent hosts $host`" = "" ]; then
		echo "error: host $host not found"
		exit 1
	fi
fi

groupadd -g $uid rsync-$1
useradd -u $uid -d /srv/rsync/$1 -m -g rsync-$1 rsync-$1
chmod 0700 /srv/rsync/$1

path=/srv/rsync/$1/.ssh
sudo -u rsync-$1 ssh-keygen -f $path/id_rsa -P ""
cp -a $path/id_rsa.pub $path/authorized_keys

if [ "$2" = "" ]; then
	usermod -s /usr/bin/rssh rsync-$1
	echo "rsync/ssh target: rsync-$1@`hostname`:/srv/rsync/$1"
else
	usermod -s /bin/false rsync-$1
	sshkey=`ssh_management_key_storage_filename $host`

	ssh -i $sshkey -p $port root@$host "groupadd -g $uid rsync-$1"
	ssh -i $sshkey -p $port root@$host "useradd -u $uid -d /srv/rsync/$1 -M -g rsync-$1 rsync-$1"
	rsync -e "ssh -i $sshkey -p $port" -av /srv/rsync/$1 root@$host:/srv/rsync
	ssh -i $sshkey -p $port root@$host "usermod -s /usr/bin/rssh rsync-$1"
	echo "rsync/ssh target: rsync-$1@$host:/srv/rsync/$1"
fi

cat $path/id_rsa
