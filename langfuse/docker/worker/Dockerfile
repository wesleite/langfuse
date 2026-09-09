FROM docker.langfuse.com/langfuse/langfuse-worker:4.24.0

USER root

RUN apk update && apk upgrade --no-cache libcrypto3 libssl3 libc6-compat busybox ssl_client zlib \
    && apk add --no-cache dumb-init curl

USER expressjs

ENTRYPOINT ["dumb-init", "--", "./worker/entrypoint.sh"]
CMD ["node", "worker/dist/index.js"]
