# docker-nexus-nginx
Docker image with Sonatype Nexus 3 OSS and NGINX

## Build
```bash
sudo docker build -t stolho/nexus-nginx .
```

## Run
Before you can start the container you need to have certificates for nginx, which should be placed to `\certs`
There are couple of options running nexus:

### Running via docker

```bash
sudo docker run \
-p 80:80 \
-v $(pwd)/conf/nginx/conf.d:/etc/nginx/conf.d \
-v $(pwd)/certs:/certs \
stolho/nexus-nginx
```

### Running via docker-compose

TBD