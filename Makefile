.PHONY: ping hostnames install init status clean

# Quick setup commands
ping:
	ansible all -m ping

hostnames:
	cd ansible && ansible-playbook playbooks/1-set-hostnames.yml

install:
	cd ansible && ansible-playbook playbooks/2-install-kubeadm.yml

init:
	cd ansible && ansible-playbook playbooks/3-init-cluster.yml

status:
	@echo "Checking cluster status..."
	@ssh coderius@192.168.1.201 "kubectl get nodes"
	@echo ""
	@ssh coderius@192.168.1.201 "kubectl get pods -A"

clean:
	@echo "This will reset the cluster. Press Ctrl+C to cancel, or Enter to continue..."
	@read confirm
	cd ansible && ansible all -b -m shell -a "kubeadm reset -f || true"
	cd ansible && ansible all -b -m file -a "path=/etc/kubernetes state=absent"
	cd ansible && ansible all -b -m file -a "path=/root/.kube state=absent"
	rm -f ansible/.kubeadm-join-command

# The hard way (manual setup)
certificates:
	cd ansible && ansible-playbook playbooks/manual-setup/2-ssl-authority.yml

kubeconfigs:
	cd ansible && ansible-playbook playbooks/manual-setup/4-generate-kubeconfigs.yml
