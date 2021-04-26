LOCAL_PUBLIC_IP=$(shell curl ifconfig.me)
NODE_IP_1="0.0.0.0"
NODE_IP_2="0.0.0.0"
TOKEN_HCLOUD=$(shell cat hcloud.token)

# INIT ###

init: init-terraform init-ansible

init-terraform:
#cd digitalocean && terraform apply -var="local_public_ip=$LOCAL_PUBLIC_IP" -var="mysql_nodes=['$NODE_IP_1','$NODE_IP_2']" -var="do_token=$TOKEN_DO"
#cd ../scaleway  && terraform apply -var="local_public_ip=$LOCAL_PUBLIC_IP" -var="mysql_nodes=['$NODE_IP_1','$NODE_IP_2']" -var="scw_accesskey=$SCW_ACCESS_KEY" -var="scw_secretkey=$SCW_SECRET_KEY"
	cd terraform/hetzner   && \
		terraform apply -var="local_public_ip=$(LOCAL_PUBLIC_IP)" -var="mysql_nodes=['$(NODE_IP_1)','$(NODE_IP_2)']" -var="hcloud_token=$(TOKEN_HCLOUD)"

init-ansible:
	ansible-galaxy install -r ansible/requirements.yml
	ansible-vault encrypt ansible/secrets.enc

# SETUP ###

setup-all: setup-init setup-mysql setup-storage setup-docker

setup-init:
	ansible-playbook -K -i ansible/inventory ansible/playbooks/init.yml

setup-mysql:
	ansible-playbook -K -e ansible/secrets.enc --ask-vault-pass -i ansible/inventory ansible/playbooks/mysql.yml

add-mysql-node:
	ansible-playbook -K -i ansible/inventory ansible/playbooks/mysql-addnode.yml -e "new_node=$(NEW_NODE_NAME)"

setup-storage:
	ansible-playbook -K -i ansible/inventory ansible/playbooks/storage.yml

setup-docker:
	ansible-playbook -K -i ansible/inventory ansible/playbooks/docker.yml

setup-kubernetes:
	./ansible/config/kubernetes/setup/sh
