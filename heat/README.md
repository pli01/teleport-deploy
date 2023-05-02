# Bootstrap teleport proxy/auth or node
Prereq:
- openstack cli
- python-heatclient
- make
- Openstack credentials
- heat parameters file


## Deploy teleport proxy and auth server
```
# source openstack credentials (OS_*)
# git clone repo
# set your parameter file in param/mycloud.yaml
# deploy
cd heat
make HEAT_PARAM=param/mycloud.yaml
```

## Register node against a teleport proxy
- Generate token on teleport proxy, and get the `join_token`
- set node parameter in file param/mycloud-node.yaml, and add teleport configuration
```
  target_hostname: "proxy.teleport.mydomain"
  ca_pins: "sha256:0e2XXXXXXXX"
  teleport_args: "--insecure"
  labels: "env=test cloud=mycloud"
```

```
# to deploy teleport node with a join_token
make create HEAT_PARAM=param/mycloud-node.yaml HEAT_STACK_NAME=node HEAT_TEMPLATE=node.yaml HEAT_OPT="--parameter join_token=$JOIN_TOKEN"
```
