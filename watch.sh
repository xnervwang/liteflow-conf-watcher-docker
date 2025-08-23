#!/bin/sh
set -eu

# 必填
: "${DOCKER_API:?DOCKER_API is required}"

# 可选（带默认值）
: "${TARGET:=liteflow}"
: "${CONF_FILE:=/app/etc/liteflow.conf}"
: "${SIGNAL:=SIGUSR1}"
: "${INOTIFY_EVENTS:=close_write,create,moved_to}"

DIR=$(dirname "$CONF_FILE")
BASE=$(basename "$CONF_FILE")

# 简单的时间戳日志函数
_now() { date '+%F %T'; }
log()  { printf '[%s] [watch] %s\n' "$(_now)" "$*"; }
elog() { printf '[%s] [watch] %s\n' "$(_now)" "$*" >&2; }

# 说明：
# - 监听父目录 + 文件名过滤，避免“原子替换”导致 inode 变化而漏事件
# - 事件默认：close_write,create,moved_to（可通过 INOTIFY_EVENTS 覆盖）
# - 信号默认：SIGUSR1（可通过 SIGNAL 覆盖）

log "watching $CONF_FILE (via parent dir $DIR) ..."
log "events=$INOTIFY_EVENTS, target=$TARGET, signal=$SIGNAL"

# 传入 -e "$INOTIFY_EVENTS"（逗号分隔或多个 -e 都可）
inotifywait -m -e "$INOTIFY_EVENTS" --format '%e %w%f' "$DIR" \
| while read -r ev path; do
  # 只响应目标文件
  [ "$path" = "$CONF_FILE" ] || continue

  # 轻微防抖，合并瞬时多次事件
  sleep 0.3

  log "$ev -> sending $SIGNAL to $TARGET"
  if curl -fsS -X POST "$DOCKER_API/containers/$TARGET/kill?signal=$SIGNAL" >/dev/null; then
    log "signal sent."
  else
    elog "failed to signal $TARGET"
  fi
done
