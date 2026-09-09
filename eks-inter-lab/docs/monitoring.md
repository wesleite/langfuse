# Arquitetura de Monitoramento

A estratégia de monitoramento do projeto é híbrida e focada em alta disponibilidade e retenção de longo prazo.

## Componentes

### 1. Kube-Prometheus-Stack (AWS & AKS)
Instalado via `k8s_commons` em todos os clusters. Coleta métricas locais e fornece o Grafana para visualização.

### 2. Thanos (AWS & AKS)
Utilizado para agregar métricas de múltiplos clusters e garantir persistência.
- **Sidecar**: Roda junto ao Prometheus em cada cluster.
- **Object Storage**: Independentemente da nuvem do cluster (AWS ou Azure), os dados de longa retenção são armazenados no bucket S3 **`thanos-monitoring-infrastructure`** na conta AWS de infraestrutura da Sólides.

### 3. Fluentbit (AWS & AKS)
Responsável pela coleta de logs e envio para o Elasticsearch (Slogger) centralizado na conta de infraestrutura da Sólides.

## Fluxo de Dados (Métricas)

1. `Prometheus` coleta métricas do cluster.
2. `Thanos Sidecar` envia blocos de métricas para o `AWS S3`.
3. No caso de clusters **AKS (Azure)**, o `Thanos` utiliza um `IAM Role` via `OIDC Provider` configurado no módulo `aks` para autenticar no S3 de forma segura.
