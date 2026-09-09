# ==============================================================================
# PostgreSQL - banco de dados do Langfuse
# ------------------------------------------------------------------------------
# Base confirmada via `helm template` no chart oficial langfuse/langfuse
# (2.1.0): o subchart "postgresql" (groundhog2k/postgres) usa a imagem
# oficial do Docker Hub, não Bitnami.
# ==============================================================================
FROM postgres:18

# Scripts de inicialização adicionais (ex: extensões) podem ser copiados assim:
# COPY ./initdb /docker-entrypoint-initdb.d/
#
# POSTGRES_USER/POSTGRES_PASSWORD/POSTGRES_DB NÃO são embutidos na imagem — vêm
# em runtime do Secret "langfuse" (secrets.yaml), via
# postgresql.settings.existingSecret/userDatabase.existingSecret. Ver postgres.yaml.
