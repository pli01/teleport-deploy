#!/bin/bash
set -euo pipefail
# docker
http_proxy="${http_proxy:-}"
no_proxy="${no_proxy:-}"
IP=$(hostname -I)

apt-get -qy update
apt-get -qy install ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod 644 /etc/apt/keyrings/docker.gpg

echo   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |   tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get -qy update
apt-get -qy install docker-ce

mkdir -p /etc/docker
cat <<EOF | tee  /etc/docker/daemon.json
{
  "log-driver": "journald",
  "mtu": 1400,
  "dns": ["$IP"]
}
EOF
chmod 600  /etc/docker/daemon.json

mkdir -p /etc/systemd/system/docker.service.d/
chmod 755 /etc/systemd/system/docker.service.d/
cat <<EOF |tee /etc/systemd/system/docker.service.d/http_proxy.conf
[Service]
Environment=HTTP_PROXY=$http_proxy
Environment=HTTPS_PROXY=$https_proxy
Environment=NO_PROXY=$no_proxy
EOF
chmod 644 /etc/systemd/system/docker.service.d/http_proxy.conf

systemctl enable docker
systemctl daemon-reload
systemctl restart docker

# docker-compose
DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_VERSION:-1.29.2}"
curl -OL https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-linux-x86_64
chmod +x docker-compose-linux-x86_64 
mv ./docker-compose-linux-x86_64 /usr/local/bin/docker-compose
