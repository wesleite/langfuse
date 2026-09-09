# ==============================================================================
# Langfuse Web (App)
# ------------------------------------------------------------------------------
# Este repositório não contém o código-fonte do Langfuse (é mantido em
# https://github.com/langfuse/langfuse). Imagem/tag confirmados via `helm
# template` no chart oficial langfuse/langfuse (2.1.0 / appVersion 4.24.0):
# imagem publicada no registry próprio docker.langfuse.com, não no Docker Hub.
# ==============================================================================
FROM docker.langfuse.com/langfuse/langfuse:4.24.0

# Customizações específicas da stack (ex: CA certs internos, timezone) entram aqui.
# Credenciais (SALT, ENCRYPTION_KEY, NEXTAUTH_SECRET, DATABASE_URL etc.) NÃO são
# embutidas na imagem — são injetadas em runtime via o Secret "langfuse"
# (secrets.yaml) referenciado pelo Helm chart. Ver web.yaml e DEPLOY.md.
