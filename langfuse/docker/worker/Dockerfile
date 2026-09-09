# ==============================================================================
# Langfuse Worker
# ------------------------------------------------------------------------------
# Assim como o web, o worker é distribuído pela imagem oficial do projeto
# (fonte em https://github.com/langfuse/langfuse). Imagem/tag confirmados via
# `helm template` no chart oficial (2.1.0 / appVersion 4.24.0): registry
# próprio docker.langfuse.com, não Docker Hub.
# ==============================================================================
FROM docker.langfuse.com/langfuse/langfuse-worker:4.24.0

# Customizações específicas da stack (ex: CA certs internos, timezone) entram aqui.
# Credenciais (SALT, ENCRYPTION_KEY, NEXTAUTH_SECRET, DATABASE_URL etc.) NÃO são
# embutidas na imagem — são injetadas em runtime via o Secret "langfuse"
# (secrets.yaml) referenciado pelo Helm chart. Ver worker.yaml e DEPLOY.md.
