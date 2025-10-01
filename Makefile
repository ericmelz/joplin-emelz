.PHONY: k3d deploy deploy-encrypted setup-secrets edit-secrets

# Traditional cluster setup
k3d:
	bash scripts/k3d.sh

destroy-k3d:
	bash scripts/destroy-k3d.sh

# New encrypted secrets workflow
setup-secrets:
	bash scripts/setup-secrets.sh

edit-secrets:
	bash scripts/edit-secrets.sh

deploy-encrypted:
	bash scripts/k3d.sh
	bash scripts/deploy.sh

# Legacy deploy (will be deprecated)
deploy: k3d

