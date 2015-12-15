#!/bin/bash
. /opt/farm/scripts/functions.uid
# skrypt tworzy konto użytkownika z dostępem rsync i kluczem ssh, gotowe do
# podpięcia Windows z cwRsync i wykonywania backupu w ramach sieci biurowej
# Tomasz Klim, sierpień 2014


MINUID=1200
MAXUID=1299


if [ "$1" = "" ]; then
	echo "usage: $0 <user>"
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

groupadd -g $uid rsync-$1
useradd -u $uid -d /srv/rsync/$1 -m -g rsync-$1 rsync-$1
chmod 0700 /srv/rsync/$1

path=/srv/rsync/$1/.ssh
sudo -u rsync-$1 ssh-keygen -f $path/id_rsa -P ""
cp -a $path/id_rsa.pub $path/authorized_keys

usermod -s /usr/bin/rssh rsync-$1

echo "rsync/ssh target: rsync-$1@`hostname`:/srv/rsync/$1"
cat $path/id_rsa
