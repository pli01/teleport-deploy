# teleport docker-compose stack

## Stacks

- all-in-one: (simple and easiest)
  - nginx container (stream ssl)
  - configure container : generate teleport.yaml based on teleport.yaml.template with envsubst, if teleport.yaml does not exists
  - teleport container : all-in-one teleport container (proxy, auth, node) with acme

- multi: (split components)
  - nginx container (stream ssl)
  - certbot container : generate cert from letsencrypt
  - teleport proxy container
  - teleport auth container

- multi-etcd: (split components)
  - nginx container (stream ssl)
  - certbot container : generate cert from letsencrypt
  - teleport proxy container
  - teleport auth container
  - etcd cluster container (storage backend)

## PreReq
In this configuration, teleport use acme or certbot to generate certificate.
You need your dns name pointing to public ip
Port 80 and 443 must be open to public ip

## Deploy all in one (easiest)

Set your environment variables in `.env`
```bash
TELEPORT_EXTERNAL_HOSTNAME=teleport.mydomain.test
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

## Deploy multi components

Set your environment variables in `.env`
```bash
TELEPORT_EXTERNAL_HOSTNAME=teleport.mydomain.test
TELEPORT_CLUSTER_NAME=teleport.mydomain.test
TELEPORT_ACME_EMAIL_DOMAIN=sample@mydomain.test
NODE_LABELS="env=test cloud=docker role=proxy"
# generate random proxy token with openssl
TELEPORT_PROXY_TOKEN=$(openssl rand -hex  20)
```

Generate certificate with certbot/letsencrypt.
File are generated in certbot/data/archive and certbot/data/live

```
docker-compose -f docker-compose-certbot.yml up -d
```

```
docker-compose -f docker-compose-multi.yml up -d
```


## Deploy multi components + etcd

Set your environment variables in `.env`
```bash
TELEPORT_EXTERNAL_HOSTNAME=teleport.mydomain.test
TELEPORT_CLUSTER_NAME=teleport.mydomain.test
TELEPORT_ACME_EMAIL_DOMAIN=sample@mydomain.test
NODE_LABELS="env=test cloud=docker role=proxy"
ETCD_URL=http://ETCD_LB:2379
# generate random proxy token with openssl
TELEPORT_PROXY_TOKEN=$(openssl rand -hex  20)
```

Start etcd cluster and lb
```
docker-compose -f etcd/docker-compose.yml up -d
```
set ETCD_URL=http://ETCD_IP:2379 in .env

Generate certificate with certbot/letsencrypt.
File are generated in certbot/data/archive and certbot/data/live

```
docker-compose -f docker-compose-certbot.yml up -d
```

Start all component
```
docker-compose -f docker-compose-multi-etcd.yml up -d
```

Scale teleport-proxy or teleport-auth
```
docker-compose -f docker-compose-multi-etcd.yml up --scale teleport-proxy=2 teleport-auth=2
```
