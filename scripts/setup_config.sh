#!/bin/bash
# scripts/setup_config.sh - 自动配置内核

set -e

echo "🔧 开始配置内核..."

cd WSL2-Linux-Kernel

# 1. 使用WSL基础配置
cp Microsoft/config-wsl .config

# 2. 使用scripts/config工具自动化启用所需选项
# 确保能搜索到开发驱动选项
./scripts/config --enable DEBUG_INFO
./scripts/config --enable ANDROID
./scripts/config --enable ANDROID_BINDER_IPC
./scripts/config --enable ANDROID_BINDERFS
./scripts/config --enable ANDROID_BINDER_DEVICES=\"binder,hwbinder,vndbinder\"
./scripts/config --enable ASHMEM

# 3. 可选的调试和性能选项（按需启用）
# ./scripts/config --enable KGDB
# ./scripts/config --enable PROFILING

# 4. 生成最终配置
make olddefconfig

echo "✅ 内核配置完成！"