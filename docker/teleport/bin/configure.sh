#!/bin/sh
set -x

export TELEPORT_NODE_LABELS="$( for i in ${NODE_LABELS}; do KEY=${i%=*}; VAL=${i#*=}; echo "    $KEY: $VAL"; done)"

envsubst '${TELEPORT_CLUSTER_NAME} ${TELEPORT_ACME_EMAIL_DOMAIN} ${TELEPORT_NODE_LABELS}' < /etc/teleport/teleport.yaml.template > /etc/teleport/teleport.yaml
