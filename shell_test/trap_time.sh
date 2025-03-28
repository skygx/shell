#!/bin/bash

# 设置脚本遇到错误时立即退出
set -e

start_time=$(date +%s.%3N)

# 定义退出时执行的函数
on_exit() {
  elapsed=$(echo "scale=3;$(date +%s.%3N)-${start_time}"|bc)
  echo "执行耗时 $elapsed 秒"
}
# 设置退出时执行的函数
trap on_exit EXIT
