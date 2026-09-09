# ==============================================================================
# ClickHouse Keeper - coordenação/consenso do cluster ClickHouse
# ------------------------------------------------------------------------------
# Base confirmada via `helm template` no chart oficial langfuse/langfuse
# (2.1.0): o chart renderiza um CR KeeperCluster (clickhouse.com/v1alpha1)
# usando a imagem oficial clickhouse/clickhouse-keeper.
# ==============================================================================
FROM clickhouse/clickhouse-keeper:26.4

# Customizações de configuração podem ser copiadas assim:
# COPY ./keeper_config.d /etc/clickhouse-keeper/config.d/
