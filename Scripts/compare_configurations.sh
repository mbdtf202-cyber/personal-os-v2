#!/bin/bash
# 对比 Debug 和 Release 配置差异

set -e

echo "🔍 配置对比：Debug vs Release"
echo "================================"
echo ""

# 定义配置项
configs=(
    "SWIFT_OPTIMIZATION_LEVEL"
    "GCC_OPTIMIZATION_LEVEL"
    "LLVM_LTO"
    "SWIFT_REFLECTION_METADATA_LEVEL"
    "STRIP_INSTALLED_PRODUCT"
    "SWIFT_COMPILATION_MODE"
    "DEAD_CODE_STRIPPING"
)

# 打印表头
printf "%-35s | %-15s | %-15s\n" "配置项" "Debug" "Release"
printf "%-35s-+-%-15s-+-%-15s\n" "-----------------------------------" "---------------" "---------------"

# 读取并对比配置
for config in "${configs[@]}"; do
    debug_value=$(grep "^$config" .xcconfig/Debug.xcconfig 2>/dev/null | cut -d'=' -f2 | xargs || echo "未设置")
    release_value=$(grep "^$config" .xcconfig/Release.xcconfig 2>/dev/null | cut -d'=' -f2 | xargs || echo "未设置")
    
    printf "%-35s | %-15s | %-15s\n" "$config" "$debug_value" "$release_value"
done

echo ""
echo "📊 预期效果："
echo "  Debug 模式："
echo "    ✅ 编译速度快（增量编译）"
echo "    ✅ 调试信息完整"
echo "    ✅ 所有功能启用"
echo "    ❌ 包体积大"
echo ""
echo "  Release 模式："
echo "    ✅ 包体积小（30-40% 减少）"
echo "    ✅ 运行性能高"
echo "    ✅ 逆向难度大"
echo "    ❌ 编译时间长（20-50% 增加）"
