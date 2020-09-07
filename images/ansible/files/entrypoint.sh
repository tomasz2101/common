#!/bin/bash

export ANSIBLE_USER="${ANSIBLE_USER:-ansible}"

function fail() {
    
    echo ERROR: $1
    exit 1
}

function warning() {

    echo WARNING: $1
}

function create_ansible_ssh_config() {
    
    if [[ -n "${ANSIBLE_SSH_PRIVATE_KEY}" ]]; then
        echo "Creating Jenkins ssh key"
        if [[ -z "${ANSIBLE_SSH_PUBLIC_KEY}" ]]; then
            fail 'Need both public and private ssh key variables'
        fi
        echo "${ANSIBLE_SSH_PRIVATE_KEY}" > /home/"${ANSIBLE_USER}"/.ssh/id_rsa ||
            fail 'Failed to create ssh private key'
        
        echo "${ANSIBLE_SSH_PUBLIC_KEY}" > /home/"${ANSIBLE_USER}"/.ssh/id_rsa.pub ||
            fail 'Failed to create ssh public key'
    fi
}

function create_ansible_user() {

    echo "Creating ${ANSIBLE_USER} user"
    adduser --home /home/"${ANSIBLE_USER}" --uid 1000 --disabled-password "${ANSIBLE_USER}"

}

function create_vault_token() {
    if [[ -n "${ANSIBLE_VAULT_TOKEN}" ]]; then
        echo "Creating vault token"
        echo "${ANSIBLE_VAULT_TOKEN}" > /home/"${ANSIBLE_USER}"/.vault-token ||
            fail 'Failed to create vault token'
    fi
}

create_ansible_user
create_ansible_ssh_config
create_vault_token

su "${ANSIBLE_USER}"

exec "$@"