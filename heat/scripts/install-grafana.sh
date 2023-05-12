#!/bin/bash
set -euo pipefail
http_proxy="${http_proxy:-}"
no_proxy="${no_proxy:-}"
# grafana
LOKI_VERSION="${LOKI_VERSION:-v2.8.2}"
curl -LO https://raw.githubusercontent.com/grafana/loki/${LOKI_VERSION}/production/docker-compose.yaml
# ajout environnement : http_proxy
cat <<'EOF' | tee docker-compose-env.yaml
services:
  loki:
    environment:
      - http_proxy=$http_proxy
      - https_proxy=$http_proxy
      - no_proxy=$no_proxy,loki,promtail,grafana,localhost,172.16.0.0/12
  promtail:
    environment:
      - http_proxy=$http_proxy
      - https_proxy=$http_proxy
      - no_proxy=$no_proxy,loki,promtail,grafana,localhost,172.16.0.0/12
  grafana:
    environment:
      - http_proxy=$http_proxy
      - https_proxy=$http_proxy
      - no_proxy=$no_proxy,loki,promtail,grafana,localhost,172.16.0.0/12
EOF

docker-compose -f docker-compose.yaml -f docker-compose-env.yaml up -d

