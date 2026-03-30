# --- Terraform ---
tf-init:
	cd infra/terraform/yandex && terraform init

tf-plan:
	cd infra/terraform/yandex && terraform plan

tf-apply:
	cd infra/terraform/yandex && terraform apply

# --- Ansible ---
ansible-ping:
	cd infra/ansible && ansible all -m ping

ansible-configure:
	cd infra/ansible && ansible-playbook playbook.yml
