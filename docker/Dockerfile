# Build com --target web|worker (ver DEPLOY.md, seção 0.6):
#   docker build --target web    -t <ECR>/langfuse-web:4.24.0    -f docker/Dockerfile docker
#   docker build --target worker -t <ECR>/langfuse-worker:4.24.0 -f docker/Dockerfile docker

FROM docker.langfuse.com/langfuse/langfuse:4.24.0 AS web

USER root

RUN apk add --no-cache curl

USER nextjs

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/api/public/health || exit 1

FROM docker.langfuse.com/langfuse/langfuse-worker:4.24.0 AS worker

USER root

RUN apk update && apk upgrade --no-cache libcrypto3 libssl3 libc6-compat busybox ssl_client zlib \
    && apk add --no-cache dumb-init curl

USER expressjs

ENTRYPOINT ["dumb-init", "--", "./worker/entrypoint.sh"]
CMD ["node", "worker/dist/index.js"]
