#!/bin/sh

bash /opt/farm/scripts/setup/role.sh sf-rssh

mkdir -p /srv/rsync

ln -sf /opt/sf-rsync-server/add-rsync-user.sh /usr/local/bin/add-rsync-user
