# teleport docker-compose stack

## Stack
- nginx container (stream ssl)
- configure container : generate teleport.yaml based on teleport.yaml.template with envsubst, if teleport.yaml does not exists
- teleport container : all-in-one teleport container (proxy, auth, node) with acme

## PreReq
- in this configuration, teleport use acme to generate certificate. You need your dns name pointing to ip

## Deploy

Set your environment variables
```bash
TELEPORT_EXTERNAL_DOMAIN=teleport.mydomain.test
TELEPORT_CLUSTER_NAME=teleport.mydomain.test
TELEPORT_ACME_EMAIL_DOMAIN=sample@mydomain.test
NODE_LABELS="env=test cloud=docker role=proxy"
```

Run

```
docker-compose up -d
```

Check status and logs:

```
docker-compose ps
docker-compose logs
```

Test:
```
# check api ok
curl -L https://${TELEPORT_EXTERNAL_DOMAIN}/webapi/ping
# or connect to https://${TELEPORT_EXTERNAL_DOMAIN/
```
Destroy
```
docker-compose down
```
