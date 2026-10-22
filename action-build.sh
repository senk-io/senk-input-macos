#!/usr/bin/env bash
# 下载 librime 预编译包和 Rime 数据，再编译 SenkWubi.app
set -e

./action-install.sh
make "${1:-release}"
