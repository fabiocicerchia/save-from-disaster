# SETUP

Before running any command you need to adjust some values to your scenario:

 - Replace everywhere `email@example.com` and `example.com`
 - Replace everywhere `xxx.xxx.xxx.xxx`, `yyy.yyy.yyy.yyy`, `zzz.zzz.zzz.zzz` with the IP addresses of your machines.
 - Replace everywhere `LOGZIO_TOKEN` with the API Token provided by logz.io
 - Change `USER` and `PASSWORD` in `./ansible/scripts/mysql-backup.sh`
 - Change `DOMAINS` in `./ansible/scripts/statify.sh`
 - Change `NAMESPACE` in `./ansible/scripts/storage-backup.sh`
 - Change `BUCKET` in `./ansible/configs/logrotate/mysql-backup`
 - Change `namespace` in `./terraform/default.tfvars`
 - Adjust values in `./ansible/configs/docker-swarm/.env.dist` and `./ansible/configs/kubernetes/.env.dist`
 - Adjust values in `ansible/secrets.enc.dist`
 - Adjust values in `./ansible/vars/*.yml` and `./ansible/inventory/*`
 - Adjust values in `./Makefile`
 - Set the SSH key in `./terraform/cloud-init`

NOTE: The file `./ansible/playbooks/mysql.yml` is not fully working yet (it contains all the correct commands, in the right order, but need to handle different vm connections). I'm refactoring it, I'll publish the new changes ASAP.

## Terraform

```shell
make init-terraform
```

## Ansible

### Secrets

```shell
mv ansible/secrets.enc.dist ansible/secrets.enc
```

### Init Galaxy

```shell
make init-ansible
```

### Linting

```shell
docker run -h toolset -v $PWD/ansible:/app -w /app -it quay.io/ansible/toolset ansible-lint
```

### Init VMs

```shell
make setup-init
ansible-playbook -K -i ansible/inventory/digitalocean ansible/playbooks/init.yml
ansible-playbook -K -i ansible/inventory/hetzner ansible/playbooks/init.yml
ansible-playbook -K -i ansible/inventory/scaleway ansible/playbooks/init.yml
```

In order to run on one VM run this:

```shell
ansible-playbook -K -i ansible/inventory/hetzner ansible/playbooks/init.yml -e "ansible_user=manager" -l web-1
```

### Init MySQL

```shell
make init-mysql
NEW_NODE_NAME=xxx make add-mysql-node
```

### Init Storage

```shell
make init-storage
```

### Init Docker

```shell
make init-docker
```

### Init Kubernetes (WIP)

```shell
make setup-kubernetes
```
