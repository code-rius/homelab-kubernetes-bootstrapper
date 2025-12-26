.PHONY: ping hostnames certificates binaries

ping:
	ansible all -m ping

hostnames:
	cd ansible && ansible-playbook playbooks/1-set-hostnames.yml

certificates:
	cd ansible && ansible-playbook playbooks/2-ssl-authority.yml

binaries:
	cd ansible && ansible-playbook playbooks/3-install-binaries.yml
