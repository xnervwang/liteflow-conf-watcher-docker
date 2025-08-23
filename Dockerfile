# syntax=docker/dockerfile:1
FROM alpine:3.20

LABEL org.opencontainers.image.title="liteflow-watcher" \
      org.opencontainers.image.description="Directory/file watcher that signals a Docker container via Docker Engine API" \
      org.opencontainers.image.source="https://github.com/yourname/liteflow-watcher" \
      org.opencontainers.image.licenses="MIT"

# ---- Runtime deps ----
RUN apk add --no-cache inotify-tools curl tzdata

# ---- Defaults (可被运行时环境变量覆盖) ----
ENV TZ=Asia/Shanghai \
    TARGET=liteflow \
    CONF_FILE=/app/etc/liteflow.conf \
    SIGNAL=SIGUSR1 \
    INOTIFY_EVENTS=close_write,create,moved_to

# ---- Prepare fs layout ----
RUN mkdir -p /app/etc /app/scripts

# ---- Add script ----
COPY watch.sh /app/scripts/watch.sh
RUN chmod +x /app/scripts/watch.sh

# ---- Set timezone (best effort) ----
RUN (cp "/usr/share/zoneinfo/${TZ}" /etc/localtime 2>/dev/null || true) \
    && echo "${TZ}" > /etc/timezone || true

# ---- Entrypoint ----
ENTRYPOINT ["/app/scripts/watch.sh"]
