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

http_proxy="${http_proxy:-}"
https_proxy="${https_proxy:-}"
no_proxy="${no_proxy:-}"

export ALIVE_CHECK_DELAY=${ALIVE_CHECK_DELAY:-5}
export TELEPORT_VERSION=${TELEPORT_VERSION:-12.3.2}
export TELEPORT_PACKAGE_NAME="teleport=${TELEPORT_VERSION}"
# LABELS="env=test foo=bar"
export REPO_CHANNEL="${REPO_CHANNEL:-}"
if [[ "${REPO_CHANNEL}" == "" ]]; then
        # By default, use the current version's channel.
        REPO_CHANNEL=stable/v"${TELEPORT_VERSION//.*/}"
fi

export TELEPORT_ARGS="${TELEPORT_ARGS:-}"

export TELEPORT_NODENAME="${TELEPORT_NODENAME:?TELEPORT_NODENAME}"
export TELEPORT_CLUSTER_NAME="${TELEPORT_CLUSTER_NAME:?TELEPORT_CLUSTER_NAME}"
export TELEPORT_EXTERNAL_HOSTNAME="${TELEPORT_EXTERNAL_HOSTNAME:?TELEPORT_EXTERNAL_HOSTNAME}"
export TELEPORT_ACME_EMAIL_DOMAIN="${TELEPORT_ACME_EMAIL_DOMAIN:?TELEPORT_ACME_EMAIL_DOMAIN}"

export LABELS="${LABELS:-}"

export NODE_LABELS="$( for i in $LABELS; do
   KEY=${i%=*};
  VAL=${i#*=};
  echo "    $KEY: $VAL";
done)"

# install nginx
apt-get update -qy
apt-get install -qy nginx

cp -f /etc/nginx/nginx.conf /etc/nginx/nginx.conf.back
( envsubst '${TELEPORT_EXTERNAL_HOSTNAME}' | tee /etc/nginx/nginx.conf ) <<'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
events {
	worker_connections 1024;
}
stream {
    log_format log_stream '$remote_addr [$time_local] $protocol [$ssl_preread_server_name] [$ssl_preread_alpn_protocols] '
    '$status $bytes_sent $bytes_received $session_time';
    access_log syslog:server=unix:/dev/log log_stream;
    upstream teleport {
        server 127.0.0.1:3080;
    }
    upstream caddy {
        server 127.0.0.1:8443;
    }
    map $ssl_preread_server_name $upstream {
        hostnames;
        .${TELEPORT_EXTERNAL_HOSTNAME} teleport;
        .teleport.cluster.local teleport;
        default caddy;
    }
    server {
        listen 443;
        ssl_preread on;
        proxy_pass $upstream;
        proxy_protocol on;
    }
}
EOF
service nginx stop
service nginx start

# install teleport
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

[ -f /etc/teleport.yaml ] && cp -f /etc/teleport.yaml /etc/teleport.yaml.back
( envsubst '${TELEPORT_EXTERNAL_HOSTNAME} \
    ${TELEPORT_NODENAME} ${TELEPORT_CLUSTER_NAME} ${TELEPORT_ACME_EMAIL_DOMAIN} \
    ${NODE_LABELS} \
' | tee /etc/teleport.yaml ) <<'EOF'
version: v3
teleport:
  nodename: ${TELEPORT_NODENAME}
  data_dir: /var/lib/teleport
  log:
    output: stderr
    severity: INFO
    format:
      output: text
  ca_pin: ""
  diag_addr: ""
auth_service:
  enabled: "yes"
  listen_addr: 127.0.0.1:3025
  cluster_name: ${TELEPORT_CLUSTER_NAME}
  proxy_listener_mode: multiplex
proxy_service:
  enabled: "yes"
  web_listen_addr: 127.0.0.1:3080
  public_addr: ${TELEPORT_EXTERNAL_HOSTNAME}:443
  https_keypairs: []
  https_keypairs_reload_interval: 0s
  acme:
    enabled: "yes"
    email: ${TELEPORT_ACME_EMAIL_DOMAIN}
ssh_service:
  enabled: "yes"
  labels:
${NODE_LABELS}
  commands:
  - name: hostname
    command: [hostname]
    period: 1m0s
EOF

chmod 600 /etc/teleport.yaml

if [ -n "$http_proxy" ] ; then
  cat <<EOF > /etc/default/teleport
HTTP_PROXY=$http_proxy
HTTPS_PROXY=$http_proxy
NO_PROXY=localhost,127.0.0.1,$no_proxy
EOF
fi

echo "Start teleport"
sudo systemctl enable teleport
sudo systemctl start teleport
sleep ${ALIVE_CHECK_DELAY}
systemctl status teleport

echo "Create initial user"
tctl users add teleport-admin --roles=editor,access --logins=root,debian,cloudadm,ubuntu
