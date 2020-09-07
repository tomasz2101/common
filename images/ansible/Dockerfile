FROM alpine:3.9

ARG ANSIBLE_VERSION=2.9.6
ENV ANSIBLE_HOST_KEY_CHECKING=False

RUN apk add --no-cache \
    openssh \
    bash \
    python3 \
    python3-dev \
    gcc \
    libffi-dev \
    musl-dev \
    openssl-dev \
    perl \
    sshpass



RUN pip3 install --upgrade pip
RUN pip3 install \
    ansible==${ANSIBLE_VERSION} \
    hvac \
    pywinrm
    
COPY ansible.docker/files/ /11bits/

WORKDIR /ansible/app/setup


ENTRYPOINT ["/11bits/entrypoint.sh"]
CMD [ "ansible-playbook"]