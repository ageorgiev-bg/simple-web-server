<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.11.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.28.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.28.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_security_group.asg_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.elb_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.rds_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.asg_allow_egress_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.elb_allow_all_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.rds_allow_egress_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.asg_allow_http_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.asg_allow_https_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.elb_allow_http_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.elb_allow_https_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.rds_allow_app_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Application name. | `string` | `null` | no |
| <a name="input_db_admin_creds"></a> [db\_admin\_creds](#input\_db\_admin\_creds) | Database admin credentials. | `string` | n/a | yes |
| <a name="input_db_instance_type"></a> [db\_instance\_type](#input\_db\_instance\_type) | RDS DB instance type. | `string` | `null` | no |
| <a name="input_enable_internet_gateway"></a> [enable\_internet\_gateway](#input\_enable\_internet\_gateway) | A boolean flag to enable/disable the internet gateway. | `bool` | n/a | yes |
| <a name="input_enable_s3_interface_endpoint"></a> [enable\_s3\_interface\_endpoint](#input\_enable\_s3\_interface\_endpoint) | A boolean flag to enable/disable the S3 interface endpoint. | `bool` | n/a | yes |
| <a name="input_enable_single_nat_gateway"></a> [enable\_single\_nat\_gateway](#input\_enable\_single\_nat\_gateway) | A boolean flag to enable/disable the NAT gateway. | `bool` | n/a | yes |
| <a name="input_enable_ssm_interface_endpoint"></a> [enable\_ssm\_interface\_endpoint](#input\_enable\_ssm\_interface\_endpoint) | A boolean flag to enable/disable the SSM interface endpoint. | `bool` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name. | `string` | n/a | yes |
| <a name="input_instance_tenancy"></a> [instance\_tenancy](#input\_instance\_tenancy) | A tenancy option for instances launched into the VPC. | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type. | `string` | `null` | no |
| <a name="input_ipv4_main_cidr_block"></a> [ipv4\_main\_cidr\_block](#input\_ipv4\_main\_cidr\_block) | Primary VPC CIDR block. | `any` | n/a | yes |
| <a name="input_private_subnets_config"></a> [private\_subnets\_config](#input\_private\_subnets\_config) | Private Subnets Config. | `map(any)` | n/a | yes |
| <a name="input_public_subnets_config"></a> [public\_subnets\_config](#input\_public\_subnets\_config) | Public Subnets Config. | `map(any)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->