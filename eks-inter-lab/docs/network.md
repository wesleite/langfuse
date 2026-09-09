# Rede e DNS

## Estrutura de Domínios

O projeto utiliza uma hierarquia de domínios baseada no ambiente e produto:
- **AWS (EKS)**: Utiliza `Route53` com certificados **ACM** gerenciados via Terraform e associados ao Load Balancer do Istio.
- **Azure (AKS)**: Utiliza `Azure DNS Zones` e certificados via **Cert-Manager** (Let's Encrypt).

Exemplo: `rhgestor-staging.solides.com.br`

## Gerenciamento de Tráfego de Entrada

### Istio (AWS & AKS)
Utilizamos o Istio para gerenciar o tráfego de entrada (North-South). Não utilizamos o recurso padrão de `Ingress` do Kubernetes, adotando exclusivamente:
- **Istio Gateway**: Define os hosts e portas expostas (públicas ou privadas).
- **Istio VirtualService**: Gerencia as rotas e o encaminhamento do tráfego para os Services da aplicação.

**Nota:** O Istio não é utilizado atualmente como Service Mesh completo para tráfego entre serviços (East-West) com mTLS obrigatório.

### ExternalDNS (AWS & AKS)
O `ExternalDNS` (configurado via `k8s_commons`) monitora os `VirtualServices` do Istio e cria automaticamente os registros A/CNAME no **Route53 (AWS)** ou **Azure DNS (Azure)**.

### Cert-Manager (AKS Only)
Gerencia a emissão e renovação automática de certificados TLS via Let's Encrypt apenas nos clusters **AKS (Azure)**, utilizando o desafio de DNS (DNS-01) integrado ao Azure DNS.
