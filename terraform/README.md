# Terraform infrastructure (AWS)

This directory provisions the full-stack app with reusable Terraform modules:

- A VPC with public subnets for the application EC2 instance and private subnets for RDS.
- An EC2 instance that builds and runs the existing Docker Compose frontend and backend.
- A private MySQL RDS instance.
- Security groups that expose the Streamlit frontend on port 8501 and allow MySQL only from the application instance.
- Systems Manager Parameter Store for the database credentials; the EC2 role can read only this app environment's parameters. SSH is not opened by default.

## Cost and Free Tier warning

The account was created in 2025, so do not assume the legacy 12-month EC2/RDS offers apply. The selected EC2/RDS instance classes are small defaults, not a guarantee of Free Tier eligibility or zero cost. Pricing depends on your account plan, region, run time, storage, data transfer, and current AWS offers. RDS, EBS, public IPv4 addresses, snapshots, and data transfer can incur charges. Check the AWS Billing console and Free Tier page before applying; destroy resources when you no longer need them. `terraform destroy` removes billable resources but may leave a final RDS snapshot in `prod`.

## Environment isolation

Use a separate Terraform workspace for each environment (`main`, `dev`, `test`, `prod`) and its matching `.tfvars` file. Workspaces isolate state, but they do not prevent costs; each environment creates separate AWS resources. Avoid creating all four environments unless you need all of them.

```bash
cd terraform
terraform init
terraform workspace new dev  # run once per environment; use `terraform workspace select dev` later
```

Set database credentials without committing them to Git:

```bash
read -r -p "RDS username: " TF_VAR_db_username
read -r -s -p "RDS password: " TF_VAR_db_password; echo
export TF_VAR_db_username TF_VAR_db_password
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

For other environments, create/select the corresponding workspace and replace `dev` with `main`, `test`, or `prod` in both commands. The Terraform state contains the RDS password even though the variable is marked sensitive. Keep local state private; for shared or production use, configure an encrypted remote backend with restricted access and versioning.

After apply, use the `frontend_url` output to access the app. The backend is reachable by the frontend over the Docker network, and RDS is not publicly accessible. To manage the instance, use AWS Systems Manager Session Manager after confirming the instance is online.

Run `terraform destroy -var-file=environments/dev.tfvars` while in the matching workspace to remove that environment when finished.
