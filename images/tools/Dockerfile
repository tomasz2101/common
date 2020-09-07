FROM alpine


RUN apk add --update --no-cache \
    make \
    bash \
    docker \
    git \
    curl
ADD https://releases.hashicorp.com/vault/1.4.3/vault_1.4.3_linux_amd64.zip /tmp/vault.zip

RUN unzip /tmp/vault.zip  -d /usr/local/bin