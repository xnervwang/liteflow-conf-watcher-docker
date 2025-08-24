#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2025, Xnerv Wang <xnervwang@gmail.com>
# This file is part of liteflow-conf-watcher-docker and is licensed under the BSD-3-Clause license.

set -eu

# 必填
: "${DOCKER_API:?DOCKER_API is required}"

# 可选（带默认值）
: "${TARGET:=liteflow}"
: "${CONF_FILE:=/app/etc/liteflow.conf}"
: "${SIGNAL:=SIGUSR1}"
: "${INOTIFY_EVENTS:=close_write,create,moved_to}"

# 运行时（best-effort）根据 TZ 同步时区；失败不影响主流程
if [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
  cp "/usr/share/zoneinfo/${TZ}" /etc/localtime 2>/dev/null || true
  echo "${TZ}" > /etc/timezone 2>/dev/null || true
fi

DIR=$(dirname "$CONF_FILE")
BASE=$(basename "$CONF_FILE")

_now() { date '+%F %T'; }
log()  { printf '[%s] [watch] %s\n' "$(_now)" "$*"; }
elog() { printf '[%s] [watch] %s\n' "$(_now)" "$*" >&2; }

log "watching $CONF_FILE (via parent dir $DIR) ..."
log "events=$INOTIFY_EVENTS, target=$TARGET, signal=$SIGNAL"

# 将 INOTIFY_EVENTS 规范化为多个 -e 参数，兼容逗号/空格分隔
INOTIFY_ARGS=""
set -- $(printf '%s' "$INOTIFY_EVENTS" | tr ',' ' ')
for ev in "$@"; do
  [ -n "$ev" ] && INOTIFY_ARGS="$INOTIFY_ARGS -e $ev"
done

# shellcheck disable=SC2086  # 故意展开 $INOTIFY_ARGS
inotifywait -m $INOTIFY_ARGS --format '%e %w%f' "$DIR" \
| while read -r ev path; do
  [ "$path" = "$CONF_FILE" ] || continue
  sleep 0.3
  log "$ev -> sending $SIGNAL to $TARGET"
  if curl -fsS -X POST "$DOCKER_API/containers/$TARGET/kill?signal=$SIGNAL" >/dev/null; then
    log "signal sent."
  else
    elog "failed to signal $TARGET"
  fi
done
