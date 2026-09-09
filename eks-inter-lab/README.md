# Terraform K8S

Este repositório contém as definições de infraestrutura como código (IaC) para os clusters de Kubernetes da Sólides, abrangendo **AWS (EKS)** e **Azure (AKS)**.

O projeto utiliza uma estrutura modular para facilitar a reutilização de código e a padronização de componentes comuns (add-ons) entre diferentes provedores de nuvem.

## 📂 Estrutura do Projeto

```text
.
├── modules/                  # Módulos reutilizáveis
│   ├── eks/                  # Módulo principal para AWS EKS (Cluster e Add-ons)
│   ├── aks/                  # Módulo principal para Azure AKS (Cluster e Add-ons)
│   ├── k8s_commons/          # Componentes comuns (Istio, CertManager, etc)
│   ├── eks_application/      # Configurações de apps p/ EKS (IAM, Vault)
│   ├── aks_application/      # Configurações de apps p/ AKS (Workload Identity, Vault)
│   └── k8s_vault_config/     # Bootstrapping de políticas e auth no Vault
├── aws-*/                    # Implementações de clusters na AWS (Prod/Staging)
├── azure-*/                  # Implementações de clusters na Azure (Prod/Staging)
├── terraform.sh              # Script auxiliar para automação de comandos
└── docs/                     # Documentação detalhada (Arquitetura, Onboarding)
```

## 🚀 Como Utilizar

### Pré-requisitos

- Terraform >= 1.14.5
- AWS CLI & Azure CLI configurados
- [terraform-docs](https://terraform-docs.io/) (para atualização da documentação dos módulos)

### Script de Automação (`terraform.sh`)

O projeto inclui um script `terraform.sh` que automatiza a formatação, inicialização e execução de `plan`/`apply` em múltiplos ambientes simultaneamente, utilizando abas do terminal para isolamento.

```bash
# Para visualizar o plano em todos os ambientes
./terraform.sh . plan

# Para aplicar as mudanças (use com cautela!)
./terraform.sh . apply
```

## 🛠 Módulos Principais

- **[EKS Module](./modules/eks/README.md)**: Gerencia o ciclo de vida de clusters EKS.
- **[AKS Module](./modules/aks/README.md)**: Gerencia o ciclo de vida de clusters AKS.
- **[Kubernetes Commons](./modules/k8s_commons/README.md)**: O "coração" dos add-ons. Instala Istio, ExternalDNS, Cert-Manager, Prometheus/Thanos, Fluentbit e KEDA de forma agnóstica à nuvem.

## 🔐 Segurança e Segredos

- **HashiCorp Vault**: Centralizador de segredos para todas as aplicações.
- **AWS IRSA / Azure Workload Identity**: Utilizados para acesso seguro a recursos da nuvem sem a necessidade de chaves estáticas.

## 📖 Documentação Adicional

Para mais detalhes sobre arquitetura e fluxos específicos, consulte a pasta [docs/](./docs/):

- [Arquitetura de Monitoramento](./docs/monitoring.md)
- [Guia de Deploy de Novas Aplicações](./docs/app-deployment.md)
- [Padrões de Rede e DNS](./docs/network.md)

---
*Mantido pelo time de Cloud Platform - Sólides.*
