## 1. Architecture Diagram

```text
                    ┌──────────────────────────┐
                    │        Internet          │
                    │   (Users / Browsers)     │
                    └─────────────┬────────────┘
                                  │
                                  │ HTTP/S :80/443
                                  ▼
                    ┌──────────────────────────┐
                    │   AWS ALB (SG)           │
                    │   Inbound: TCP 80/443    │
                    └─────────────┬────────────┘
                                  │
                                  ▼            
                    ┌──────────────────────────┐
                    │      AWS EC2 (SG)        │
                    │ Inbound: TCP 80 - ALB SG │
                    │          ...             │
                    │  (Amazon Linux / Ubuntu) │
                    │                          │
                    │  ┌────────────────────┐  │
                    │  │  Gunicorn (WSGI)   │  │
                    │  │  Bind: 0.0.0.0:80  │  │
                    │  └─────────┬──────────┘  │
                    │            │             │
                    │  ┌─────────▼──────────┐  │
                    │  │  Flask Application │  │
                    │  │   app.py / wsgi.py │  │
                    │  └─────────┬──────────┘  │
                    │            │ SQLAlchemy  │
                    │            ▼             │
                    └──────────────────────────┘
                    ┌──────────────────────────┐
                    │  ┌────────────────────┐  │
                    │  │  MySQL Database    │  │
                    │  │  (AWS RDS) (SG)    │  │
                    │  │  Inbound: TCP 3306 │  │
                    │  └────────────────────┘  │
                    │                          │
                    └──────────────────────────┘


```
## 2. Git Repository Contents
- `.github` - reserved for GitHub Actions workflo used to deploy the architecture  
- `modules` - contains VPC module used to deploy networking part of the architecture  
- `scripts` - contain EC2 instance bootstrap configuration passed thru "EC2 user data"  
- `environments` - holds 1+ environment specific infrastructure configurations  

## 3. Github CI-CD Actions (workflow)  
Must create a single Github environment secrets containing 3 variables:  
- **Environment**: `staging`  
- **Secrets**:  
  - `AWS_REGION` - environment region  
  - `AWS_ROLE_OIDC` - Terraform deployment (AWS) role  
  - `TF_VAR_DB_ADMIN_CREDS` - AWS RDS DB cluster password  

**Pipeline trigger:** manual trigger with 2 variable choice selections:  
- **AWS environment** - select deployment environment, currently only: "staging"  
- **Terraform Management actions selection:**  
  - `terraform-deploy`  - Terraform resource deployment via plan file  
  - `terraform-destroy` - Terraform resource destruction  

## 3. Infrastructure deployment
### VPC module
There is a simple VPC module responsible for the VPC networking layer including:
- Public/Private subnets, (private) DB subnet group  
- NAT & Internet gateways
- Subnet routing configuration  
- VPCEs if needed (for SSM/S3/EC2) if privately deployed resources are used without NAT GW
 
### Application infrastructure deployment 
0. S3 bucket for Terraform state!! (must create it separately)  
  - Must have valid SSL/TLS cerificate available to use (must create it separately)  
1. **EC2 Autoscaling Group** to support HA and DR scenarios 
  - Uses Launch Template  
    - Flask application is deployed via EC2 user data templated script inside `scripts/user_data_v2.sh`  
  - ASG is deployed across several AZs  
2. **Elastic Load Balancer** - Application Load Balancer with 2 listeners (HTTP/S)   
  - HTTP listener (TCP: 80)  
  - HTTPS listener - (self-signed certificate is excluded) (TCP: 443)  
  - Single ALB target group for EC2 instance(s) (via ASG)  
  - Private access S3 bucket for ALB access logs  
3. **RDS Aurora DB cluster** running MySQL 8.0 - single DB instance, no Multi-AZ  


## 4. Application Deploment Configuration Considerations
>Note:
The Flask application using DB as store, is deployed under `/var/app` inside Python virtual environment on the EC2 instance. There are several python files used to hold application configuration as well as SQLAlchemy configuration related to the Database storage.  

1. Host OS application-related environment variables (see `user_data_v2.sh` bootstrap configuration script):  
  - `ADMIN_PWD` - contain RDS DB admin user password, must be passed as OS environment variable, i.e `export TF_VAR_db_admin_creds` via CI/etc thru Terraform to the template 
  - `DB_EP` - RDS Aurora DB cluster writer endpoint is passed by Terraform (from DB cluster resource) to the template  
  - `ENVIRONMENT` - environment name passed by Terraform to the template  
  - `FLASK_USR_PWD` - can be used to pass application user password (its hardcoded atm)  
  - `MYSQL_DB` - can be used to pass application DB name (its hardcoded atm)  
2. Flask app has several application compoents, saved as files under `/var/app`:  
- `app.py` - holds the code of the actual application itself  
- `config.py` - config class responsible for SQLAlchemy configuration  
- `models.py` - SQLAlchemy DB schema configuration  
- `wsgi.py` - WSGI server configuration  
- `init_db.py` - bootstraps application database using 
- `bootstrap.sql`- SQL script used to bootstrap the application DB  
- `requirements.txt` - Python packages used to configure virtual environment  

3. Flask app is deployed via EC2 user data in Pythong venv, with:
  - **flask DB user**: `flaskuser`
  - **flask DB user password**: `flaskPWD`
  - **Gunicorn** server listens on all EC2 network interfaces, on port 80
  - **RDS DB bootstrap script**: `bootstrap_sql.sh`
4. Bootstrap script function to provide partial application recovery - If either application user or application DB are not available they get re-created, with fail-safe clause to prevent failures. Check `user_data_v2.sh` for details  
5. After the application is deployed, try to reach it via ALB DNS name:  
`http://<ALB_DNS_NAME:80/443>/`  
OR:  
use AWS SSM Session Manager session  
For inter VPC connectivity check, you must add your security group as a source to allow connectivity!  

## 5. (Optional) Infrastructure Provisioning Runbook

### CI/CD Automated Deployment via GitHub Actions 
1. Go to Actions, select **"TF Infra Manage AWS infra (OIDC)"** worfklow
2. Click **"Run Workflow"** and choose environment as well as job type
3. Click **"Run Workflow"** button
4. Verify the deployment finished successfully
5. Hit the ALB DNS Name to check the application
6. Destroy the environment - repeat step 1, on step 2. choose job to run: `terraform-destroy` and follow the rest of the steps


### Manual Deployment
>Note: Terraform should be run at the root of the app repository. Environment variables must be passed to Terraform via: `--var-file=environments/staging-vars.tf`

1. Must pass RDS DB admin password as an OS environment variable using Terraform  
`export TF_VAR_db_admin_creds=<DB-ADMIN-PASSWORD>`
2. Initialize Terraform/Tofu inside repository dir root (/), where the cloned repo is  
`terraform init`
3. Terraform plan the infrastructure to be provisioned, pass environment vars file  
`terraform plan --var-file=environments/staging-vars.tf -out=.terraform.plan
rm.plan`
4. Apply Terraform plan
`terraform apply ".terraform.plan"`
5. Verify the deployment finished successfully
6. Destroy/Cleanup infra if/when needed
`terraform apply --var-file=environments/staging-vars.tf -destroy`
