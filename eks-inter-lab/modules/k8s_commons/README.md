# Kubernetes Commons Module

This Terraform module manages common infrastructure components (add-ons) for Kubernetes clusters across multiple cloud providers (AWS, Azure, Oracle, and Huawei). It automates the deployment of essential services such as Service Mesh, DNS management, Certificate management, Monitoring, and Logging.

## Features

- **Service Mesh:** Deploys Istio with separate public and private gateways.
- **DNS Management:** Configures ExternalDNS for automatic DNS record synchronization.
- **Certificate Management:** Installs Cert-Manager with support for Let's Encrypt and cloud-native integrations (ACM/Azure Key Vault).
- **Monitoring:** Sets up the Kube-Prometheus-Stack for comprehensive cluster observability.
- **Logging:** Deploys Fluentbit for log collection and shipping (compatible with Elasticsearch/Slogger).
- **Autoscaling:** Includes KEDA for event-driven horizontal pod autoscaling.
- **Secrets Management:** Integrates with HashiCorp Vault.
- **CI/CD:** Optionally deploys GitLab Runners with node isolation support.

## Supported Cloud Providers

- **AWS (EKS):** Uses IAM Roles for Service Accounts (IRSA) and NLB integration.
- **Azure (AKS):** Uses Workload Identity and Azure Load Balancer.
- **Oracle (OKE):** Basic support for resource deployment.
- **Huawei (CCE):** Basic support for resource deployment.

## Architecture

This module standardizes the Kubernetes add-on layer across cluster providers. It is intended to be consumed by cluster infrastructure modules such as `eks` and `aks`, which remain responsible for provider-specific infrastructure like VPCs, subnets, managed identities, IAM roles, KMS keys, and DNS zones.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14.5 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.1.1 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | = 2.2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 3.0.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 3.1.1 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | = 2.2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 3.0.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.argocd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.aws_iam_role_injector](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.azure_workload_identify_system](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.blue_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.external_dns](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.fluentbit_collector](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.fluentbit_gateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.gitlab_runner](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_base](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_gateway_private](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_gateway_public](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istiod](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.keda](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.kube_prometheus_stack](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.metrics_server](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.vault](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.vault_secrets_webhook](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.argocd_istio_gateway](https://registry.terraform.io/providers/alekc/kubectl/2.2.0/docs/resources/manifest) | resource |
| [kubectl_manifest.argocd_istio_virtualservice](https://registry.terraform.io/providers/alekc/kubectl/2.2.0/docs/resources/manifest) | resource |
| [kubectl_manifest.istio_wildcard_cert](https://registry.terraform.io/providers/alekc/kubectl/2.2.0/docs/resources/manifest) | resource |
| [kubectl_manifest.kube_prometheus_stack_istio_gateway](https://registry.terraform.io/providers/alekc/kubectl/2.2.0/docs/resources/manifest) | resource |
| [kubectl_manifest.kube_prometheus_stack_istio_virtualservice](https://registry.terraform.io/providers/alekc/kubectl/2.2.0/docs/resources/manifest) | resource |
| [kubectl_manifest.letsencrypt_wildcard](https://registry.terraform.io/providers/alekc/kubectl/2.2.0/docs/resources/manifest) | resource |
| [kubectl_manifest.vault_istio_gateway](https://registry.terraform.io/providers/alekc/kubectl/2.2.0/docs/resources/manifest) | resource |
| [kubectl_manifest.vault_istio_virtualservice](https://registry.terraform.io/providers/alekc/kubectl/2.2.0/docs/resources/manifest) | resource |
| [kubernetes_cluster_role_binding_v1.blue_agent_binding](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding_v1) | resource |
| [kubernetes_cluster_role_v1.blue_agent_role](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_namespace_v1.cert_manager](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_namespace_v1.cicd](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_namespace_v1.external_dns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_namespace_v1.logs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_namespace_v1.monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.argocd_dex_google_sso](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.blue_agent](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.external_dns_azure](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.fluentbit_elastic](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.thanos_sidecar_object_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_service_account_v1.gitlab_runner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_argocd_azure_password"></a> [argocd\_azure\_password](#input\_argocd\_azure\_password) | Password for the Azure repository credential template configured in ArgoCD. | `string` | `""` | no |
| <a name="input_argocd_dex_google_sso_client_id"></a> [argocd\_dex\_google\_sso\_client\_id](#input\_argocd\_dex\_google\_sso\_client\_id) | Google OAuth client ID stored in the ArgoCD Dex SSO secret. | `string` | `""` | no |
| <a name="input_argocd_dex_google_sso_client_secret"></a> [argocd\_dex\_google\_sso\_client\_secret](#input\_argocd\_dex\_google\_sso\_client\_secret) | Google OAuth client secret stored in the ArgoCD Dex SSO secret. | `string` | `""` | no |
| <a name="input_argocd_enabled"></a> [argocd\_enabled](#input\_argocd\_enabled) | Whether to deploy ArgoCD. This addon is currently used only for AWS clusters. | `bool` | `true` | no |
| <a name="input_argocd_gitlab_password"></a> [argocd\_gitlab\_password](#input\_argocd\_gitlab\_password) | Password for the GitLab repository credential template configured in ArgoCD. | `string` | `""` | no |
| <a name="input_aws_acm_certificate_arn"></a> [aws\_acm\_certificate\_arn](#input\_aws\_acm\_certificate\_arn) | ACM certificate ARN used by AWS-facing ingress and load balancer addons. | `string` | `""` | no |
| <a name="input_aws_load_balancer_controller_identifier"></a> [aws\_load\_balancer\_controller\_identifier](#input\_aws\_load\_balancer\_controller\_identifier) | IAM role ARN used by the AWS Load Balancer Controller service account. | `string` | `""` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS CLI profile used by Terraform exec-based Kubernetes authentication. | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region used by AWS-specific addons such as cluster-autoscaler. | `string` | `""` | no |
| <a name="input_aws_vpc_id"></a> [aws\_vpc\_id](#input\_aws\_vpc\_id) | AWS VPC ID consumed by AWS-specific addons such as the AWS Load Balancer Controller. | `string` | `""` | no |
| <a name="input_azure_resource_group_name"></a> [azure\_resource\_group\_name](#input\_azure\_resource\_group\_name) | Azure resource group name used by Azure-specific addons and workload identities. | `string` | `""` | no |
| <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id) | Azure subscription ID used by Azure-specific addons. | `string` | `""` | no |
| <a name="input_azure_tenant_id"></a> [azure\_tenant\_id](#input\_azure\_tenant\_id) | Azure tenant ID used by Azure-specific addons. | `string` | `""` | no |
| <a name="input_blue_agent_enabled"></a> [blue\_agent\_enabled](#input\_blue\_agent\_enabled) | Whether to deploy Blue Agent. This addon is currently used only for AWS clusters. | `bool` | `true` | no |
| <a name="input_blue_agent_organization_url"></a> [blue\_agent\_organization\_url](#input\_blue\_agent\_organization\_url) | Azure DevOps organization URL used by the Blue Agent chart. | `string` | `""` | no |
| <a name="input_blue_agent_personal_access_token"></a> [blue\_agent\_personal\_access\_token](#input\_blue\_agent\_personal\_access\_token) | Azure DevOps personal access token used by the Blue Agent chart. | `string` | `""` | no |
| <a name="input_cert_manager_identifier"></a> [cert\_manager\_identifier](#input\_cert\_manager\_identifier) | Cloud identity identifier used by cert-manager. Use an IAM role ARN on AWS or a managed identity client ID on Azure. | `string` | `""` | no |
| <a name="input_cloud_provider"></a> [cloud\_provider](#input\_cloud\_provider) | Target cloud provider for the cluster addons. Supported values are aws, azure, oracle, and huawei. | `string` | n/a | yes |
| <a name="input_cluster_autoscaler_identifier"></a> [cluster\_autoscaler\_identifier](#input\_cluster\_autoscaler\_identifier) | IAM role ARN used by the cluster-autoscaler service account. | `string` | `""` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name used by Helm releases, DNS ownership, and addon-specific identifiers. | `string` | n/a | yes |
| <a name="input_dns_domain"></a> [dns\_domain](#input\_dns\_domain) | Base DNS domain used by ingress, ExternalDNS, cert-manager, and addon hostnames. | `string` | n/a | yes |
| <a name="input_external_dns_identifier"></a> [external\_dns\_identifier](#input\_external\_dns\_identifier) | Cloud identity identifier used by ExternalDNS. Use an IAM role ARN on AWS or a managed identity client ID on Azure. | `string` | `""` | no |
| <a name="input_fluentbit_elastic_password"></a> [fluentbit\_elastic\_password](#input\_fluentbit\_elastic\_password) | Password used by Fluent Bit when authenticating to Elasticsearch/OpenSearch. | `string` | n/a | yes |
| <a name="input_fluentbit_elastic_user"></a> [fluentbit\_elastic\_user](#input\_fluentbit\_elastic\_user) | Username used by Fluent Bit when authenticating to Elasticsearch/OpenSearch. | `string` | n/a | yes |
| <a name="input_gitlab_runner_enabled"></a> [gitlab\_runner\_enabled](#input\_gitlab\_runner\_enabled) | Whether to deploy GitLab Runner releases and their shared service account. | `bool` | `true` | no |
| <a name="input_gitlab_runner_identifier"></a> [gitlab\_runner\_identifier](#input\_gitlab\_runner\_identifier) | Cloud identity identifier used by GitLab Runner. Use an IAM role ARN on AWS or a managed identity client ID on Azure. | `string` | `""` | no |
| <a name="input_gitlab_runner_node_isolation_enabled"></a> [gitlab\_runner\_node\_isolation\_enabled](#input\_gitlab\_runner\_node\_isolation\_enabled) | Whether GitLab Runner pods should use the dedicated node selector and tolerations. | `bool` | `true` | no |
| <a name="input_gitlab_runner_tokens"></a> [gitlab\_runner\_tokens](#input\_gitlab\_runner\_tokens) | Map of GitLab Runner registration tokens keyed by runner suffix. Each key becomes part of the Helm release name. | `map(string)` | `{}` | no |
| <a name="input_huawei_cluster_id"></a> [huawei\_cluster\_id](#input\_huawei\_cluster\_id) | Huawei CCE cluster ID used by Huawei-specific integrations. | `string` | `null` | no |
| <a name="input_huawei_region"></a> [huawei\_region](#input\_huawei\_region) | Huawei region used by Huawei-specific integrations. | `string` | `null` | no |
| <a name="input_oracle_cluster_id"></a> [oracle\_cluster\_id](#input\_oracle\_cluster\_id) | Oracle OKE cluster OCID used by Oracle-specific integrations. | `string` | `null` | no |
| <a name="input_oracle_region"></a> [oracle\_region](#input\_oracle\_region) | Oracle region used by Oracle-specific integrations. | `string` | `null` | no |
| <a name="input_prometheus_aws_iam_role_arn"></a> [prometheus\_aws\_iam\_role\_arn](#input\_prometheus\_aws\_iam\_role\_arn) | IAM role ARN used by Prometheus/Thanos when AWS access is required. | `string` | `""` | no |
| <a name="input_prometheus_disk_size_gb"></a> [prometheus\_disk\_size\_gb](#input\_prometheus\_disk\_size\_gb) | Persistent volume size requested by Prometheus, for example `100Gi`. | `string` | `"100Gi"` | no |
| <a name="input_prometheus_enabled"></a> [prometheus\_enabled](#input\_prometheus\_enabled) | Whether to deploy the kube-prometheus-stack addon. | `bool` | `true` | no |
| <a name="input_slogger_context"></a> [slogger\_context](#input\_slogger\_context) | Context suffix used in log routing metadata and slogger index prefixes. | `string` | n/a | yes |
| <a name="input_slogger_environment"></a> [slogger\_environment](#input\_slogger\_environment) | Environment label used in log routing metadata and slogger index prefixes. | `string` | n/a | yes |
| <a name="input_vault_aws_kms_key_arn"></a> [vault\_aws\_kms\_key\_arn](#input\_vault\_aws\_kms\_key\_arn) | AWS KMS key ARN used by Vault auto-unseal on AWS clusters. | `string` | `""` | no |
| <a name="input_vault_enabled"></a> [vault\_enabled](#input\_vault\_enabled) | Whether to deploy HashiCorp Vault and its companion resources. | `bool` | `true` | no |
| <a name="input_vault_identifier"></a> [vault\_identifier](#input\_vault\_identifier) | Cloud identity identifier used by Vault. On AWS this should be the IRSA IAM role ARN. | `string` | `""` | no |
| <a name="input_vault_node_isolation_enabled"></a> [vault\_node\_isolation\_enabled](#input\_vault\_node\_isolation\_enabled) | Whether Vault pods should use dedicated node selector and toleration settings. | `bool` | `true` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
