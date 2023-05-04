#!/bin/bash
set -euo pipefail

HOSTNAME="$(hostname -s)"
MACHINE_ID="$(cat /etc/machine-id)"
ALIVE_CHECK_DELAY=${ALIVE_CHECK_DELAY:-3}
TELEPORT_VERSION=${TELEPORT_VERSION:-12.3.1}
TELEPORT_PACKAGE_NAME="teleport=${TELEPORT_VERSION}"
TARGET_HOSTNAME="${TARGET_HOSTNAME:?TARGET_HOSTNAME}"
TARGET_PORT="${TARGET_PORT:-443}"
JOIN_TOKEN="${JOIN_TOKEN:?JOIN_TOKEN}"
CA_PINS="${CA_PINS:?CA_PINS}"
# LABELS="env=test foo=bar"
LABELS="${LABELS:-}"
REPO_CHANNEL="${REPO_CHANNEL:-}"
TELEPORT_ARGS="${TELEPORT_ARGS:-}"

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

systemctl stop teleport.service || true

# configure
cat <<EOF | tee /etc/teleport.yaml
version: v3
teleport:
  nodename: ${HOSTNAME}
  data_dir: /var/lib/teleport
  join_params:
    token_name: ${JOIN_TOKEN}
    method: token
  proxy_server: ${TARGET_HOSTNAME}:${TARGET_PORT}
  log:
    output: stderr
    severity: INFO
    format:
      output: text
  ca_pin: ${CA_PINS}
  diag_addr: ""
auth_service:
  enabled: "no"
ssh_service:
  enabled: "yes"
  labels:
    teleport.internal/resource-id: ${MACHINE_ID}
$( for i in $LABELS; do
  KEY=${i%=*};
  VAL=${i#*=};
  echo "    $KEY:" "$VAL";
done)
  commands:
  - name: hostname
    command: [hostname]
    period: 1m0s
proxy_service:
  enabled: "no"
  https_keypairs: []
  https_keypairs_reload_interval: 0s
  acme: {}
EOF

# enable and start
sed -i -e 's/^\(ExecStart=.*start\)/\1 $TELEPORT_ARGS /g'  /lib/systemd/system/teleport.service

if [ ! -f "/etc/default/teleport" ] || ! grep "^TELEPORT_ARGS" /etc/default/teleport ; then
   echo "TELEPORT_ARGS=\"${TELEPORT_ARGS} \"" | tee /etc/default/teleport
fi

systemctl enable teleport
systemctl start teleport
sleep ${ALIVE_CHECK_DELAY}
systemctl status teleport
