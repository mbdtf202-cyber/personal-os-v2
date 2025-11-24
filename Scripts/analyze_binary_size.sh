#!/bin/bash
# 二进制包体积分析脚本
# 分析各个模块对最终包体积的贡献

set -e

APP_PATH="${1:-build/Release-iphoneos/personalos-ios-v2.app}"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ 找不到 App: $APP_PATH"
    echo "用法: $0 [app路径]"
    exit 1
fi

echo "📦 分析包体积: $APP_PATH"
echo ""

# 1. 总体积
TOTAL_SIZE=$(du -sh "$APP_PATH" | awk '{print $1}')
echo "📊 总包体积: $TOTAL_SIZE"
echo ""

# 2. 可执行文件大小
BINARY_PATH="$APP_PATH/personalos-ios-v2"
if [ -f "$BINARY_PATH" ]; then
    BINARY_SIZE=$(ls -lh "$BINARY_PATH" | awk '{print $5}')
    echo "🔧 可执行文件: $BINARY_SIZE"
    
    # 3. 符号表分析
    echo ""
    echo "🔍 符号表分析:"
    nm -size-sort "$BINARY_PATH" | tail -20 | while read size type name; do
        printf "  %10s  %s\n" "$size" "$name"
    done
fi

# 4. 资源文件大小
echo ""
echo "📁 资源文件 Top 10:"
find "$APP_PATH" -type f ! -name "personalos-ios-v2" -exec ls -lh {} \; | \
    sort -k5 -hr | head -10 | awk '{printf "  %10s  %s\n", $5, $9}'

# 5. Framework 大小
echo ""
echo "📚 Frameworks:"
if [ -d "$APP_PATH/Frameworks" ]; then
    du -sh "$APP_PATH/Frameworks"/* | sort -hr
else
    echo "  无嵌入式 Frameworks"
fi

# 6. 优化建议
echo ""
echo "💡 优化建议:"
echo "  1. 检查是否有未使用的资源文件"
echo "  2. 压缩图片资源（使用 Asset Catalog）"
echo "  3. 启用 App Thinning"
echo "  4. 移除未使用的 Framework"
echo "  5. 使用 LTO 和符号剥离"

# 7. 与上次构建对比（如果存在）
HISTORY_FILE=".build_size_history"
if [ -f "$HISTORY_FILE" ]; then
    LAST_SIZE=$(tail -1 "$HISTORY_FILE" | awk '{print $2}')
    echo ""
    echo "📈 与上次构建对比:"
    echo "  上次: $LAST_SIZE"
    echo "  本次: $TOTAL_SIZE"
fi

# 记录本次构建
echo "$(date +%Y-%m-%d) $TOTAL_SIZE" >> "$HISTORY_FILE"
