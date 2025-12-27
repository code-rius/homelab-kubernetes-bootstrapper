.PHONY: ping hostnames install init status clean setup deploy-all deploy-firefly-tailscale

# Full automated setup - run everything in sequence
setup:
	@echo "🚀 Starting full cluster setup..."
	@echo ""
	@$(MAKE) hostnames
	@echo ""
	@$(MAKE) install
	@echo ""
	@$(MAKE) init
	@echo ""
	@$(MAKE) storage
	@echo ""
	@$(MAKE) cleanup-tailscale-device
	@echo ""
	@$(MAKE) tailscale
	@echo ""
	@echo "✅ Cluster setup complete!"
	@echo "Run 'make deploy-firefly-tailscale' to deploy Firefly III"

# Deploy all applications
deploy-all: deploy-firefly-tailscale deploy-radicale

# Quick setup commands
ping:
	ansible all -m ping

hostnames:
	cd ansible && ansible-playbook playbooks/1-set-hostnames.yml

install:
	cd ansible && ansible-playbook playbooks/2-install-kubeadm.yml

init:
	cd ansible && ansible-playbook playbooks/3-init-cluster.yml

storage:
	cd ansible && ansible-playbook playbooks/4-setup-nfs-storage.yml

tailscale:
	cd ansible && ansible-playbook playbooks/5-setup-tailscale.yml

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

# Application deployments
cleanup-tailscale-device:
	@echo "🧹 Cleaning up old Tailscale devices..."
	@./scripts/cleanup-tailscale-device.sh

deploy-firefly-tailscale:
	@cd apps/firefly-iii && \
	if [ ! -f secrets.env ] || [ ! -f postgres-secrets.env ]; then \
		echo "❌ Error: secrets.env or postgres-secrets.env not found!"; \
		echo "Copy the .example files and fill in your values:"; \
		echo "  cp secrets.env.example secrets.env"; \
		echo "  cp postgres-secrets.env.example postgres-secrets.env"; \
		exit 1; \
	fi
	kubectl apply -f apps/firefly-iii/namespace.yml
	@echo "Recreating PVs to ensure clean binding..."
	@kubectl delete pv firefly-postgres-pv firefly-upload-pv --ignore-not-found=true
	kubectl apply -f apps/firefly-iii/postgres-pv.yml
	kubectl apply -f apps/firefly-iii/firefly-upload-pv.yml
	kubectl create secret generic postgres-secret --from-env-file=apps/firefly-iii/postgres-secrets.env -n firefly-iii --dry-run=client -o yaml | kubectl apply -f -
	kubectl create secret generic firefly-secret --from-env-file=apps/firefly-iii/secrets.env -n firefly-iii --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f apps/firefly-iii/postgres.yml
	kubectl apply -f apps/firefly-iii/firefly-tailscale.yml
	@echo ""
	@echo "Waiting for Firefly III to be ready..."
	@kubectl wait --for=condition=ready pod -l app=postgres -n firefly-iii --timeout=300s || true
	@kubectl wait --for=condition=ready pod -l app=firefly-iii -n firefly-iii --timeout=300s || true
	@echo ""
	@echo "✅ Firefly III deployed!"
	@echo "Access at: http://firefly.tail060ef.ts.net"

deploy-firefly:
	@cd apps/firefly-iii && \
	if [ ! -f secrets.env ] || [ ! -f postgres-secrets.env ]; then \
		echo "❌ Error: secrets.env or postgres-secrets.env not found!"; \
		echo "Copy the .example files and fill in your values:"; \
		echo "  cp secrets.env.example secrets.env"; \
		echo "  cp postgres-secrets.env.example postgres-secrets.env"; \
		exit 1; \
	fi
	kubectl apply -f apps/firefly-iii/namespace.yml
	kubectl create secret generic postgres-secret --from-env-file=apps/firefly-iii/postgres-secrets.env -n firefly-iii --dry-run=client -o yaml | kubectl apply -f -
	kubectl create secret generic firefly-secret --from-env-file=apps/firefly-iii/secrets.env -n firefly-iii --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f apps/firefly-iii/postgres.yml
	kubectl apply -f apps/firefly-iii/firefly.yml
	@echo ""
	@echo "Waiting for Firefly III to be ready..."
	@kubectl wait --for=condition=ready pod -l app=postgres -n firefly-iii --timeout=300s
	@kubectl wait --for=condition=ready pod -l app=firefly-iii -n firefly-iii --timeout=300s
	@echo ""
	@echo "✅ Firefly III is ready!"
	@echo "Access at: http://192.168.1.201:30080"

deploy-radicale:
	kubectl apply -f apps/radicale/namespace.yml
	@echo "Recreating PV to ensure clean binding..."
	@kubectl delete pv radicale-data-pv --ignore-not-found=true
	kubectl apply -f apps/radicale/radicale-pv.yml
	kubectl apply -f apps/radicale/radicale.yml
	@echo ""
	@echo "Waiting for Radicale to be ready..."
	@kubectl wait --for=condition=ready pod -l app=radicale -n radicale --timeout=300s || true
	@echo ""
	@echo "✅ Radicale deployed!"
	@echo "Access at: http://radicale.tail060ef.ts.net"
	@echo ""
	@echo "Create a user with:"
	@echo "  kubectl exec -n radicale -it deployment/radicale -- htpasswd -B -c /data/users myusername"

# The hard way (manual setup)
certificates:
	cd ansible && ansible-playbook playbooks/manual-setup/2-ssl-authority.yml

kubeconfigs:
	cd ansible && ansible-playbook playbooks/manual-setup/4-generate-kubeconfigs.yml
