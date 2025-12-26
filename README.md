# bindplane-terraform

Production-ready Terraform configuration to deploy a BindPlane server on GCP.

Features
- GCE instance (Ubuntu 22.04)
- Startup script to install PostgreSQL and BindPlane, create DB/user
- systemd service for BindPlane
- Firewall rules (SSH, BindPlane UI 3001, PostgreSQL 5432)
- Instance metadata used to deliver DB password securely to the startup script

WARNING: Instance metadata is viewable by anyone with compute.instance.get permissions on the project. For production, consider using Secret Manager and granting minimal access.

## Files
- main.tf - GCP resources
- variables.tf - variables
- outputs.tf - outputs
- startup.sh - startup script read by instance metadata
- terraform.tfvars.example - sample var file

## Quick deploy (local)
1. Install and authenticate gcloud and enable the Compute Engine API.
2. Install Terraform (>=1.3) and initialize.
3. Create a terraform.tfvars or pass -var values.

Example:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your-service-account.json"
terraform init
terraform apply -var="project_id=your-gcp-project" -var="db_password=StrongPasswordHere"
```

After apply, get the UI URL:
```bash
terraform output bindplane_ui_url
# then open http://<EXTERNAL-IP>:3001
```

## Create a GitHub repo and push (optional)
If you want to host this on GitHub:
```bash
git init
git add .
git commit -m "Initial bindplane terraform"
# Using GitHub CLI (authenticated)
gh repo create yourusername/bindplane-terraform --public --source=. --remote=origin --push
```

## Next steps / improvements
- Use Cloud SQL instead of local Postgres for HA
- Store DB credentials in Secret Manager and mount them at startup
- Add HTTPS via Load Balancer and managed certs
- Use a managed instance group (MIG) and autoscaling for HA