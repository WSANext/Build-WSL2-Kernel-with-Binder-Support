#!/bin/bash
# scripts/setup_config.sh - 自动配置内核 (修正强制版)

set -e

echo "🔧 开始配置内核 (修正版)..."

cd WSL2-Linux-Kernel

# 1. 使用WSL基础配置
cp Microsoft/config-wsl .config

# 2. 【核心修正】使用 --set-val 强制启用选项为 y (内置)，而非 --enable
# 这确保选项被明确设置为"是"，避免被后续步骤覆盖
./scripts/config --set-val ANDROID y
./scripts/config --set-val ANDROID_BINDER_IPC y
./scripts/config --set-val ANDROID_BINDERFS y
# 设置 Binder 设备节点列表
./scripts/config --set-str ANDROID_BINDER_DEVICES "binder,hwbinder,vndbinder"
# 【最关键】强制启用 ASHMEM 为 y
./scripts/config --set-val ASHMEM y

# 3. (保留)处理其他可选选项
./scripts/config --enable DEBUG_INFO
# ./scripts/config --enable KGDB
# ./scripts/config --enable PROFILING

# 4. 生成最终配置(接受新选项的默认值)
make olddefconfig

# 5. 【新增：关键验证步骤】立即检查配置是否真正写入
echo "✅ 内核配置完成！正在验证关键驱动..."
echo "----------------------------------------"
if grep -q "CONFIG_ANDROID_BINDER_IPC=y" .config && \
   grep -q "CONFIG_ASHMEM=y" .config; then
    echo "✅ 验证通过！Binder 与 Ashmem 驱动已成功启用为内置。"
    echo "关键配置状态："
    grep -E "^CONFIG_ANDROID_BINDER_IPC=|^CONFIG_ASHMEM=" .config
else
    echo "❌ 验证失败！配置未正确应用。请检查以上步骤。"
    echo "当前找到的相关配置："
    grep -E "CONFIG_ANDROID_BINDER_IPC|CONFIG_ASHMEM" .config || echo "  (未找到)"
    exit 1 # 主动失败，阻止后续编译
fi
echo "----------------------------------------"