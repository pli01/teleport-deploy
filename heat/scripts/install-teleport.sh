#!/bin/bash
set -e -o pipefail
function clean() {
    ret=$?
    if [ "$ret" -gt 0 ] ;then
        echo "FAILURE $0: $ret"
    else
        echo "SUCCESS $0: $ret"
    fi
    exit $ret
}
trap clean EXIT QUIT KILL

export http_proxy="${http_proxy:-}"
export https_proxy="${https_proxy:-}"
export no_proxy="${no_proxy:-}"

SYSTEM_ARCH=amd64
TELEPORT_VERSION=v12.2.5
export cluster_name="${cluster_name:-private.local}"
export floating_ip="${floating_ip:-}"

#
echo "Install teleport"
curl -LO https://get.gravitational.com/teleport-$TELEPORT_VERSION-linux-$SYSTEM_ARCH-bin.tar.gz.sha256
curl -LO https://cdn.teleport.dev/teleport-$TELEPORT_VERSION-linux-$SYSTEM_ARCH-bin.tar.gz
shasum -a 256 -c teleport-$TELEPORT_VERSION-linux-$SYSTEM_ARCH-bin.tar.gz.sha256
tar -xvf teleport-$TELEPORT_VERSION-linux-$SYSTEM_ARCH-bin.tar.gz
cd teleport
sudo ./install
#
sudo openssl req -x509 -nodes -newkey rsa:4096 \
-keyout /var/lib/teleport/teleport.key \
-out /var/lib/teleport/teleport.pem -sha256 -days 3650 \
-subj "/C=FR/ST=Paris/O=Random/OU=Org/CN=*.private.local"
#
sudo teleport configure -o /etc/teleport.yaml  \
    --cluster-name=private.local \
    --public-addr=$floating_ip:443 \
    --cert-file=/var/lib/teleport/teleport.pem \
    --key-file=/var/lib/teleport/teleport.key
#
echo "Start teleport"
sudo teleport install systemd -o /etc/systemd/system/teleport.service
sudo systemctl enable teleport
sudo systemctl start teleport
sleep 10
#
echo "Add role"
#TODO
echo "Add user"
sudo tctl users add teleport-admin --roles=editor,access --logins=root,debian,cloudadm,ubuntu
