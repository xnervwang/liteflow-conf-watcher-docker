# README.md

# liteflow-conf-watcher-docker

监听配置文件（默认 `/app/etc/liteflow.conf`），在文件更新时通过 **Docker Engine API** 向目标容器发送信号（默认 `SIGUSR1`），用于优雅地触发应用重载（如 liteflow）。

## 特性
- 可靠监听：**父目录监听 + 文件名过滤**，兼容“原子替换”（`rename` 落位）与就地写入（`close_write`）。
- 可配置：事件集合、信号、目标容器名、时区、配置文件路径均可通过环境变量覆盖。
- 轻量：基于 `alpine`，仅安装 `inotify-tools` 与 `curl`。

## 快速开始

### 1) 构建镜像
```bash
docker build -t liteflow-conf-watcher:latest .
```

### 2) 运行（最小示例）
```bash
docker run --rm \
  -e DOCKER_API=http://dockerproxy:2375 \
  -v "$PWD/etc":/app/etc:ro \
  liteflow-conf-watcher:latest
```

修改宿主机 `./etc/liteflow.conf` 后，容器会向 `TARGET` 容器发送 `SIGNAL`（默认 `SIGUSR1`）。

## docker compose 示例
```yaml
services:
  dockerproxy:
    image: tecnativa/docker-socket-proxy:latest
    environment:
      CONTAINERS: 1
      PING: 1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "2375:2375"
    restart: unless-stopped

  liteflow:
    image: your/liteflow:latest
    container_name: liteflow
    # ...

  liteflow-conf-watcher:
    image: liteflow-conf-watcher:latest   # 或推送到仓库后的镜像名
    container_name: liteflow-conf-watcher
    environment:
      DOCKER_API: http://dockerproxy:2375         # 必填：Docker Engine API
      # 可选覆盖：
      # TARGET: liteflow
      # CONF_FILE: /app/etc/liteflow.conf
      # SIGNAL: SIGUSR1
      # INOTIFY_EVENTS: close_write,create,moved_to
      # TZ: Asia/Shanghai
    volumes:
      - ./etc:/app/etc:ro
    depends_on:
      - dockerproxy
    restart: unless-stopped
```

## 环境变量
| 变量名           | 必填 | 默认值                        | 说明 |
|------------------|------|-------------------------------|------|
| `DOCKER_API`     | 是   | —                             | Docker Engine API 根地址，如 `http://dockerproxy:2375` |
| `TARGET`         | 否   | `liteflow`                    | 需要接收信号的容器名 |
| `CONF_FILE`      | 否   | `/app/etc/liteflow.conf`      | 监听的目标配置文件路径 |
| `SIGNAL`         | 否   | `SIGUSR1`                     | 发送给目标容器的信号（如 `SIGHUP`） |
| `INOTIFY_EVENTS` | 否   | `close_write,create,moved_to` | 监听事件集合（逗号或空格分隔均可） |
| `TZ`             | 否   | `Asia/Shanghai`               | 容器时区；构建期与运行期都会尽力同步到 `/etc/localtime` |

## 工作原理
- 通过 `inotifywait` 监听 **父目录** 的事件，再按文件名过滤到 `CONF_FILE`。
- 捕获事件后，向 `DOCKER_API/containers/$TARGET/kill?signal=$SIGNAL` 发起 `POST`，等价于向容器发送该信号。

## 许可
本项目采用 **BSD-3-Clause** 协议，详见仓库内 `LICENSE`。

---
© 2025 Xnerv Wang <xnervwang@gmail.com>
