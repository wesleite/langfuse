# ==============================================================================
# ClickHouse Server - armazenamento analítico do Langfuse
# ------------------------------------------------------------------------------
# Base confirmada via `helm template` no chart oficial langfuse/langfuse
# (2.1.0): o chart renderiza um CR ClickHouseCluster (clickhouse.com/v1alpha1)
# via ClickHouse Kubernetes Operator, usando a imagem oficial
# clickhouse/clickhouse-server, não Bitnami.
# ==============================================================================
FROM clickhouse/clickhouse-server:26.4

# Customizações de configuração (ex: config.d/*.xml) podem ser copiadas assim:
# COPY ./config.d /etc/clickhouse-server/config.d/
#
# Senha do usuário "default" NÃO é embutida na imagem — vem em runtime do
# Secret "langfuse" (secrets.yaml), via clickhouse.auth.existingSecret. Ver clickhouse.yaml.
