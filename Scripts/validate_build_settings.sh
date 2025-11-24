#!/bin/bash
# 编译时构建设置验证脚本
# 确保 Release 模式下所有优化都已启用

set -e

echo "🔍 验证 Release 构建优化设置..."

# 检查是否为 Release 模式
if [ "${CONFIGURATION}" != "Release" ]; then
    echo "⚠️  非 Release 模式，跳过验证"
    exit 0
fi

# 验证 LTO 是否启用
if [ "${LLVM_LTO}" != "YES" ] && [ "${LLVM_LTO}" != "YES_THIN" ]; then
    echo "❌ 错误: LTO 未启用"
    exit 1
fi

# 验证反射元数据级别
if [ "${SWIFT_REFLECTION_METADATA_LEVEL}" != "none" ]; then
    echo "⚠️  警告: Swift 反射元数据未设置为 none，包体积可能较大"
fi

# 验证代码剥离
if [ "${STRIP_INSTALLED_PRODUCT}" != "YES" ]; then
    echo "❌ 错误: 符号剥离未启用"
    exit 1
fi

# 验证全模块优化
if [ "${SWIFT_COMPILATION_MODE}" != "wholemodule" ]; then
    echo "❌ 错误: Swift 全模块优化未启用"
    exit 1
fi

# 验证死代码剥离
if [ "${DEAD_CODE_STRIPPING}" != "YES" ]; then
    echo "⚠️  警告: 死代码剥离未启用"
fi

echo "✅ Release 构建优化设置验证通过"
echo ""
echo "📊 优化配置摘要:"
echo "  - LTO: ${LLVM_LTO}"
echo "  - Swift 优化: ${SWIFT_OPTIMIZATION_LEVEL}"
echo "  - 反射元数据: ${SWIFT_REFLECTION_METADATA_LEVEL}"
echo "  - 符号剥离: ${STRIP_INSTALLED_PRODUCT}"
echo "  - 编译模式: ${SWIFT_COMPILATION_MODE}"
