# Deploy de Novas Aplicações

Para adicionar uma nova aplicação ao cluster, seguimos um padrão que garante isolamento e segurança.

## Passos para AWS (EKS)

1. Crie um arquivo `eks_application_<nome>.tf` no diretório do ambiente.
2. Utilize o módulo `eks_application` (**AWS Only**):
   - Define a `IAM Role` necessária (IRSA).
   - Cria a política no `Vault` para o caminho `k8s/<namespace>/<app>`.
   - Configura o `Kubernetes Auth Role` no Vault.

## Passos para Azure (AKS)

1. Crie um arquivo `app_<nome>.tf` no diretório `aks_applications` do ambiente.
2. Utilize o módulo `aks_application` (**AKS Only**):
   - Provisiona a `User Assigned Identity`.
   - Configura o `Federated Identity Credential`.
   - Gerencia permissões no Vault.

## Estratégia de Deployment (CI/CD)

Anteriormente, o **ArgoCD** (AWS & AKS) era utilizado para a sincronização GitOps. No entanto, este componente está sendo **deprecado**. Atualmente, o deploy de novas aplicações deve seguir os pipelines de CI/CD padrão da empresa, integrados com os recursos de infraestrutura provisionados via Terraform.

## Padrão de Segredos

Todos os segredos devem residir no Vault sob o mount `k8s/`:
- Caminho: `k8s/data/<namespace>/<app_name>`
- As aplicações devem utilizar o `Vault Secrets Webhook` ou SDKs para consumir os valores.
