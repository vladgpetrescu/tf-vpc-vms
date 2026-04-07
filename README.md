This Terraform configuration is used to create the following configuration on AWS:
- ⁠A VPC with at least one Private and one Public subnet
- ⁠Two VMs, one in the Private subnet, one in the Public subnet
- ⁠Restrict access to the VM in the Public subnet to a single IP address
- Restrict access to the VM in the Private subnet to only from the VM in the Public subnet
- ⁠Both VMs should be able to reach the internet (either directly or indirectly)
- ⁠VMs can be Windows or Linux

In order to highlight Terraform knowledge and experience, the configuration was hand-crafted instead of chosing an out-of-the-box configuration, such as the official AWS Terraform VPC module

# Assumptions

The configuration can be extended to support other requirements, such as a multi-environment setup or High-Availability setup (multiple subnets, multiple availability zones, auto-scaling groups, etc).

For simplicity and cost-saving, the following assumptions have been made in this configuration:
- a single availability zone is needed (as a result, the NAT Gateway is zonal)
- a single public subnet and a single private subnet are needed
- the public and private VMs are using the latest Amazon Linux (AL2023) or Windows Server 2025 image AMIs
- connecting to the VMs uses SSH, but this can also be achived via the AWS Console SSM
- further input configuration can be added for instance setup if required, eg instance types, userdata, resources etc
- the configuration uses a local terraform state
- there is no CI/CD setup needed, but this can be added (must be paired with a remote state backend for Terraform)

# Setup

- have access to an AWS account and permissions to create a VPC, Subnets, EC2 instances, Internet Gateway, NAT Gateway
- setup the [provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) section in [versions.tf](versions.tf) with your AWS credentials
- generate a SSH private-public key pair (ED25519 type) - you can use [this guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) for further info (you do not need to add this to Github)
- save the keys as `aws.pem` and `aws.pub` under your user's `~/.ssh` folder. 

# Usage:

- create a `terraform.tfvars` file in the root of the repo with values for the name of the configuration and the IPv4 CIDR range allowed to connect to the public instance, eg:
```hcl
name                     = "test-vpc"
public_ingress_cidr      = "1.2.3.4/32"
```
- in the `terraform.tfvars` file, override as needed any other inputs from the `variables.tf` file to adjust the configuration
- run `terraform init`
- run `terraform apply`, investigate the output plan and then allow the execution by tiping `yes` if you're happy with the plan
- note the IP addressed from the output `private_vm_ip_address` and `public_vm_ip_address` or display them by running `terraform output`
- connect to the public VM by running `ssh -i <path to your local private key .pem file> ec2-user@<public_vm_ip_address>` in your terminal eg `ssh -i ~/.ssh/aws.pem ec2-user@1.2.3.4`
- connect to the private VM by running `ssh -i ~/.ssh/<var.name / var.ssh_key_name>.pem ec2-user@<private_vm_ip_address>` on the public VM after you have connected to it, eg `ssh -i ~/.ssh/test-vpc.pem ec2-user@1.2.3.4`
- in order to remove the resources, run `terraform apply -destroy`

# Updates
- run `terraform fmt` before pushing changes
- update the docs using [terraform-docs](https://github.com/terraform-docs/terraform-docs): `terraform-docs markdown table --output-file README.md --output-mode inject .`

# Documentation
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.14.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.39.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.39.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ebs_volume.private](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.public](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/ebs_volume) | resource |
| [aws_eip.nat_eip](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/eip) | resource |
| [aws_eip.public_vm_eip](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/eip) | resource |
| [aws_instance.private](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/instance) | resource |
| [aws_instance.public](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/instance) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/internet_gateway) | resource |
| [aws_key_pair.main](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/key_pair) | resource |
| [aws_nat_gateway.nat](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/nat_gateway) | resource |
| [aws_route_table.private_rt](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/route_table) | resource |
| [aws_route_table.public_rt](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/route_table) | resource |
| [aws_route_table_association.private_assoc](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_assoc](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/route_table_association) | resource |
| [aws_security_group.private_sg](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/security_group) | resource |
| [aws_security_group.public_sg](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/security_group) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/subnet) | resource |
| [aws_volume_attachment.private_ebs_att](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.public_ebs_att](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/volume_attachment) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/vpc) | resource |
| [aws_vpc_security_group_egress_rule.private_sg_egress](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.public_sg_egress](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.private_sg_ingress](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.public_sg_ingress](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_ami.linux](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/data-sources/ami) | data source |
| [aws_ami.windows](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/6.39.0/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | The IPv4 CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_create_private_resources"></a> [create\_private\_resources](#input\_create\_private\_resources) | Enables the creation of the private resources such as private subnet, private VM, NAT Gateway, etc - to be used in testing | `bool` | `true` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The OS type to be used for the VMs: linux or windows | `string` | `"linux"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to be used on all the resources as an identifier | `string` | n/a | yes |
| <a name="input_private_subnet_cidr"></a> [private\_subnet\_cidr](#input\_private\_subnet\_cidr) | IPv4 CIDRs to be used for the public subnet | `string` | `"10.0.32.0/24"` | no |
| <a name="input_public_ingress_cidr"></a> [public\_ingress\_cidr](#input\_public\_ingress\_cidr) | IPv4 CIDR to allow on the public VM ingress | `string` | n/a | yes |
| <a name="input_public_subnet_cidr"></a> [public\_subnet\_cidr](#input\_public\_subnet\_cidr) | IPv4 CIDRs to be used for the public subnet | `string` | `"10.0.0.0/24"` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | The name to be used for the AWS key pair - must be unique on the AWS region used | `string` | `null` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | Path to the public key (.pub) to be used when creating the VMs - you must present the private key when connecting | `string` | `"~/.ssh/aws.pub"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of additional key-value tags to set on all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_vm_ip_address"></a> [private\_vm\_ip\_address](#output\_private\_vm\_ip\_address) | The AWS private IP address for the private VM |
| <a name="output_public_vm_ip_address"></a> [public\_vm\_ip\_address](#output\_public\_vm\_ip\_address) | Elastic IP attached to the public VM |
<!-- END_TF_DOCS -->