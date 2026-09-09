FROM docker.langfuse.com/langfuse/langfuse:4.24.0

USER root

RUN apk add --no-cache curl

USER nextjs

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/api/public/health || exit 1