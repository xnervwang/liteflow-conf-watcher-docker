# Dockerfile
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2025, Xnerv Wang <xnervwang@gmail.com>
# This file is part of liteflow-conf-watcher-docker and is licensed under the BSD-3-Clause license.

# syntax=docker/dockerfile:1
FROM alpine:3.20

LABEL org.opencontainers.image.title="liteflow-watcher" \
      org.opencontainers.image.description="Directory/file watcher that signals a Docker container via Docker Engine API" \
      org.opencontainers.image.source="https://github.com/xnervwang/liteflow-conf-watcher-docker" \
      org.opencontainers.image.licenses="BSD-3-Clause"

# ---- Runtime deps ----
RUN apk add --no-cache inotify-tools curl tzdata

# ---- Defaults (可被运行时环境变量覆盖) ----
# Don't monitor `create` event, otherwise may send multiple signals when puller
# updates the conf file.
ENV TZ=Asia/Shanghai \
    TARGET=liteflow \
    CONF_FILE=/app/etc/liteflow.conf \
    SIGNAL=SIGUSR1 \
    INOTIFY_EVENTS=close_write,moved_to

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
