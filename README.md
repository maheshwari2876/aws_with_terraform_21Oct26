# Initial repo structure :

Note: Document and update below tree upon any changes to repo structure.  
```
├── .github/
│   └── workflows/
│       ├── terraform-dev.yml      # CI/CD Pipeline for Development
│       └── terraform-prod.yml     # CI/CD Pipeline for Production
├── modules/                      # Reusable local infrastructure blueprints
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── compute/
│       ├── main.tf
│       └── variables.tf
└── environments/                 # Live infrastructure installations
    ├── dev/
    │   ├── backend.tf            # Points to Dev S3 State Bucket
    │   ├── providers.tf          # Configures OIDC Dev Role Assumption
    │   ├── main.tf               # Calls local modules with Dev values
    │   ├── variables.tf
    │   └── terraform.tfvars
    └── prod/
        ├── backend.tf            # Points to Prod S3 State Bucket
        ├── providers.tf          # Configures OIDC Prod Role Assumption
        ├── main.tf               # Calls local modules with Prod values
        ├── variables.tf
        └── terraform.tfvars
```





# Core Structure Guidelines


1. Keep Modules Raw & Generic (/modules)

Your /modules directory should act as a library of blueprints. Do not hardcode resource names, environment strings, or IP ranges inside them. Instead, use generic variables.tf files.
• Example: The networking module defines how a generic VPC is built. It doesn't know or care if it's running in Dev or Prod.

2. Isolate Settings Inside Environments (/environments)

The /environments/dev and /environments/prod folders are your concrete implementations. Each folder maintains its own isolated .tfstate file. Inside environments/dev/main.tf, you instantiate your module block by referencing it locally:
```hcl
module "network" {
  source   = "../../modules/networking"
  vpc_cidr = "10.0.0.0/16" # Specific to Dev
  env      = "dev"
}
```


3. Match Providers to Your Roles

Inside environments/dev/providers.tf and environments/prod/providers.tf, configure your AWS provider block to assume the specific OIDC execution role created for that targeted environment.
• The Dev provider should assume arn:aws:iam::111111111111:role/github-actions-dev-role
• The Prod provider should assume arn:aws:iam::222222222222:role/github-actions-prod-role


# Managing the Git Branch & Pipeline Workflow

To tie your repository layout securely to your GitHub Actions configuration, implement path-filtering to ensure workflows only execute when relevant changes occur:
1. The Dev Pipeline (terraform-dev.yml): Configure the workflow to trigger automatically on Pull Requests or Pushes targeting your main branch, but restrict it strictly to changes made inside the development directory:
```yaml
on:
  push:
    paths:
      - 'environments/dev/**'
      - 'modules/**'
```
2. The Prod Pipeline (terraform-prod.yml): Secure your production deployments by requiring a strict gate—such as a manual Workflow Dispatch approval or a formal Git Tag release (e.g., v1.0.0)—preventing untested code from altering your production state instantly.
