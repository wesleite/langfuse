# Kubernetes Vault Configuration Module

This Terraform module automates the initial configuration of a HashiCorp Vault server deployed within a Kubernetes cluster. It sets up authentication backends, secret engines, and global policies.

## Features

- **Kubernetes Auth Backend:** 
  - Enables and configures the `kubernetes` auth backend, allowing cluster-native authentication for pods via Service Accounts.
- **OIDC Integration:** 
  - Configures OIDC authentication (e.g., Google OAuth) to allow human users to log into the Vault UI using their organizational accounts.
- **Secrets Management:** 
  - Initializes a KV-V2 secret engine mounted at `k8s/` for storing application-specific secrets.
- **Global Policies:** 
  - Defines baseline RBAC policies:
    - `admin`: Full access to all paths.
    - `editor`: Read/Update access to Kubernetes secrets.
    - `reader`: Read-only access to Kubernetes secrets.
    - `limited`: List-only access to Kubernetes secrets.

## Prerequisites

This module assumes a Vault server is already running and accessible. It requires a root token to perform the initial bootstrapping of auth backends and policies.

## Architecture

This module operates after the Vault infrastructure and Kubernetes connectivity already exist. It focuses on bootstrapping logical Vault configuration rather than provisioning cluster or cloud infrastructure.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | ~> 5.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_vault"></a> [vault](#provider\_vault) | ~> 5.7 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [vault_auth_backend.kubernetes](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/auth_backend) | resource |
| [vault_jwt_auth_backend.oidc](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend) | resource |
| [vault_jwt_auth_backend_role.gmail_role](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend_role) | resource |
| [vault_kubernetes_auth_backend_config.kubernetes](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_config) | resource |
| [vault_kubernetes_auth_backend_role.gitlab_runner](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_mount.cicd](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount) | resource |
| [vault_mount.k8s](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount) | resource |
| [vault_policy.admin](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [vault_policy.editor](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [vault_policy.gitlab_runner](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [vault_policy.limited](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [vault_policy.reader](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kubernetes_ca_cert"></a> [kubernetes\_ca\_cert](#input\_kubernetes\_ca\_cert) | The CA certificate (PEM format) used by the Kubernetes cluster for Vault to verify connections. | `string` | n/a | yes |
| <a name="input_vault_address"></a> [vault\_address](#input\_vault\_address) | The public URL of the HashiCorp Vault server (e.g., https://vault.example.com). | `string` | n/a | yes |
| <a name="input_vault_oidc_bound_audiences"></a> [vault\_oidc\_bound\_audiences](#input\_vault\_oidc\_bound\_audiences) | A list of allowed audiences for OIDC authentication. | `list(string)` | n/a | yes |
| <a name="input_vault_oidc_client_id"></a> [vault\_oidc\_client\_id](#input\_vault\_oidc\_client\_id) | Client ID for the OIDC provider integration. | `string` | n/a | yes |
| <a name="input_vault_oidc_client_secret"></a> [vault\_oidc\_client\_secret](#input\_vault\_oidc\_client\_secret) | Client secret for the OIDC provider integration (e.g., Google OAuth client secret). | `string` | n/a | yes |
| <a name="input_vault_root_token"></a> [vault\_root\_token](#input\_vault\_root\_token) | Initial root token for Vault authentication. Used to configure backend auth and roles. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
