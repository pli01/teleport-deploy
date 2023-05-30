#!/bin/sh
set -x

export TELEPORT_NODE_LABELS="$( for i in ${NODE_LABELS}; do KEY=${i%=*}; VAL=${i#*=}; echo "    $KEY: $VAL"; done)"
export TELEPORT_CONFIG_TEMPLATE=${TELEPORT_CONFIG_TEMPLATE:-teleport.yaml.template}
export TELEPORT_CONFIG_FILE=$(basename $TELEPORT_CONFIG_TEMPLATE .template)
[ -f /etc/teleport/${TELEPORT_CONFIG_TEMPLATE} ] || exit 1
envsubst '${TELEPORT_CLUSTER_NAME} ${TELEPORT_ACME_EMAIL_DOMAIN} ${TELEPORT_NODE_LABELS} ${TELEPORT_PROXY_TOKEN}' < /etc/teleport/${TELEPORT_CONFIG_TEMPLATE} > /etc/teleport/${TELEPORT_CONFIG_FILE}
