#!/bin/bash
set -euo pipefail

TARGET_HOSTNAME="${TARGET_HOSTNAME:?TARGET_HOSTNAME}"
http_proxy="${http_proxy:-}"
no_proxy="${no_proxy:-}"

curl -sL "https://${TARGET_HOSTNAME}/webapi/auth/export?type=user" | sed 's/^cert-authority //g' | tee /etc/ssh/user_ca.pub
chmod 644 /etc/ssh/user_ca.pub

if ! grep TrustedUserCAKeys  /etc/ssh/sshd_config ; then
  echo "TrustedUserCAKeys /etc/ssh/user_ca.pub" | tee -a /etc/ssh/sshd_config
fi

service sshd restart
