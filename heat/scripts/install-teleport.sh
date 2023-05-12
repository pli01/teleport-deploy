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

export cluster_name="${cluster_name:-private.local}"
export floating_ip="${floating_ip:-}"

TELEPORT_VERSION=${TELEPORT_VERSION:-12.3.1}
TELEPORT_PACKAGE_NAME="teleport=${TELEPORT_VERSION}"
REPO_CHANNEL="${REPO_CHANNEL:-}"

if [[ "${REPO_CHANNEL}" == "" ]]; then
        # By default, use the current version's channel.
        REPO_CHANNEL=stable/v"${TELEPORT_VERSION//.*/}"
fi

# install
umask 0022
apt-get -qy update
apt-get -qy install apt-transport-https gnupg -y
curl https://apt.releases.teleport.dev/gpg \
  -o /usr/share/keyrings/teleport-archive-keyring.asc
source /etc/os-release
echo "deb [signed-by=/usr/share/keyrings/teleport-archive-keyring.asc] \
  https://apt.releases.teleport.dev/${ID?} ${VERSION_CODENAME?} ${REPO_CHANNEL}" \
  | tee /etc/apt/sources.list.d/teleport.list > /dev/null

apt-get -qy update
apt-get -qy install ${TELEPORT_PACKAGE_NAME}

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
sudo systemctl enable teleport
sudo systemctl start teleport
sleep 10
#
echo "Add role"
#TODO
echo "Add user"
sudo tctl users add teleport-admin --roles=editor,access --logins=root,debian,cloudadm,ubuntu
