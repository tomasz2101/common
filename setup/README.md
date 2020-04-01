Ansible Vault
=============

Not distributed as part of this repository is the Ansible Vault file,
which you may put in `~/.config_home/ansible-vault.txt`, for example.
This secret file is guarded by the repo master.

Initial setup of hosts
======================

Add the host to `inventory.yml`

Create user with passwordless sudo

Run ansible with login and password as your own user:

ansible-playbook -i ./inventory/server.yml  ./playbook/server_init.yml -u tom -k -K

ansible-playbook -i ./inventory/rpi.yml  -u pi ./playbook/initial_rpi.yml -k


Install and keep up to date
==================================================


Run ansible with ansible ans local user on the target hosts, need setup from initial
for each user.

ansible-playbook -i ./envs/cluster.yaml  -u tom cluster.yaml

ansible-playbook -i envs/work.yaml  -u pi -k -K cluster.yaml


Testing
==================================================

ansible-playbook -i ./inventory/testing.yml --vault-id ~/.config_home/ansible-vault.txt -u ansible ./playbook/testing.yml

ansible-playbook -i ./inventory/rpi.yml --vault-id ~/.config_home/ansible-vault.txt -u tom ./playbook/rpi.yml


Using of lastpass with ansible as vault for all secrets
==================================================

First you need to login wiht lpass command line to your vault later you can execute ansible