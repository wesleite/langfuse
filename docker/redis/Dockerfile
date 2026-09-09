# ==============================================================================
# Redis/Valkey - cache e filas do Langfuse
# ------------------------------------------------------------------------------
# Base confirmada via `helm template` no chart oficial langfuse/langfuse
# (2.1.0): o subchart "redis" (valkey-io/valkey) usa a imagem oficial
# docker.io/valkey/valkey, não Bitnami. Compatível com auth em redis.yaml.
# ==============================================================================
FROM valkey/valkey:8.0

# Customizações (ex: valkey.conf próprio) podem ser copiadas assim:
# COPY ./valkey.conf /usr/local/etc/valkey/valkey.conf
#
# Senha ACL do usuário "default" NÃO é embutida na imagem — vem em runtime do
# Secret "langfuse" (secrets.yaml), via redis.auth.usersExistingSecret. Ver redis.yaml.
