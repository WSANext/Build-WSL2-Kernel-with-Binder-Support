#!/bin/bash
# scripts/build_kernel.sh - 编译内核并打包

set -e

echo "🚀 开始编译 WSL2 自定义内核"
echo "========================================"

# 进入内核目录
cd WSL2-Linux-Kernel

# 记录开始时间
START_TIME=$(date +%s)

# 获取核心数，加速编译
CORE_COUNT=$(nproc)
echo "使用 $CORE_COUNT 个线程进行编译..."

# 清理之前的编译（可选，首次可注释掉）
# echo "执行清理..."
# make clean

# 开始编译
echo "开始编译内核 (vmlinux)..."
make -j$CORE_COUNT 2>&1 | tee build.log

# 检查编译结果
if [ ! -f "vmlinux" ]; then
    echo "❌ 编译失败，未找到 vmlinux 文件！"
    exit 1
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
echo "✅ 编译成功！耗时: $((DURATION / 60))分$((DURATION % 60))秒"

# 准备产出物目录
cd ..
echo "📦 打包产出物..."
OUTPUT_DIR="kernel_output"
mkdir -p "$OUTPUT_DIR"

# 复制关键文件
cp WSL2-Linux-Kernel/vmlinux "$OUTPUT_DIR/"
cp WSL2-Linux-Kernel/.config "$OUTPUT_DIR/kernel.config"
cp WSL2-Linux-Kernel/Module.symvers "$OUTPUT_DIR/" 2>/dev/null || true
cp WSL2-Linux-Kernel/build.log "$OUTPUT_DIR/" 2>/dev/null || true

# 生成版本信息
echo "生成部署说明..."
cat > "$OUTPUT_DIR/README.md" << 'EOF'
# WSL2 自定义内核

**编译日期**: $(date)
**内核版本**: $(grep "Linux/.*" WSL2-Linux-Kernel/include/config/kernel.release 2>/dev/null || echo "未知")
**源码分支**: linux-msft-wsl-6.1.y

## 包含特性
- ✅ Android Binder IPC 驱动 (CONFIG_ANDROID_BINDER_IPC)
- ✅ Ashmem 共享内存 (CONFIG_ASHMEM)
- ✅ 基于微软官方 WSL2 内核

## 使用方法
1. 下载 `vmlinux` 文件到 Windows，例如保存至 `C:\wsl_kernel\vmlinux`
2. 在用户目录 (`%USERPROFILE%`) 创建或修改 `.wslconfig` 文件：
   [wsl2]
   kernel=C:\\wsl_kernel\\vmlinux
3. 重启 WSL: `wsl --shutdown`

## 验证命令
在 WSL2 中运行：
\`\`\`bash
uname -a
lsmod | grep binder
ls /dev/ashmem 2>/dev/null && echo "Ashmem 设备存在"
\`\`\`
EOF

echo "🎉 所有流程完成！产出物位于: $OUTPUT_DIR/"
ls -la $OUTPUT_DIR/