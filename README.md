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

修改宿主机`./etc/liteflow.conf`后，容器会向TARGET容器发送SIGNAL（默认`SIGUSR1`）。
