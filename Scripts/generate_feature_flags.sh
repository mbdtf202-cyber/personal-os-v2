#!/bin/bash
# 从 JSON 配置生成编译器 Feature Flags
# 用于 CI/CD 动态控制功能模块

set -e

CONFIG_FILE="${1:-feature-flags.json}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

echo "🔧 从配置文件生成 Feature Flags: $CONFIG_FILE"

# 读取 JSON 并生成编译器标志
FLAGS=""

# 使用 jq 解析 JSON（如果可用）
if command -v jq &> /dev/null; then
    DASHBOARD=$(jq -r '.dashboard' "$CONFIG_FILE")
    TRADING=$(jq -r '.trading' "$CONFIG_FILE")
    SOCIAL=$(jq -r '.social' "$CONFIG_FILE")
    NEWS=$(jq -r '.news' "$CONFIG_FILE")
    HEALTH=$(jq -r '.health' "$CONFIG_FILE")
    PROJECT_HUB=$(jq -r '.projectHub' "$CONFIG_FILE")
    TRAINING=$(jq -r '.training' "$CONFIG_FILE")
    TOOLS=$(jq -r '.tools' "$CONFIG_FILE")
    
    [ "$DASHBOARD" = "true" ] && FLAGS="$FLAGS -DFEATURE_DASHBOARD"
    [ "$TRADING" = "true" ] && FLAGS="$FLAGS -DFEATURE_TRADING"
    [ "$SOCIAL" = "true" ] && FLAGS="$FLAGS -DFEATURE_SOCIAL"
    [ "$NEWS" = "true" ] && FLAGS="$FLAGS -DFEATURE_NEWS"
    [ "$HEALTH" = "true" ] && FLAGS="$FLAGS -DFEATURE_HEALTH"
    [ "$PROJECT_HUB" = "true" ] && FLAGS="$FLAGS -DFEATURE_PROJECT_HUB"
    [ "$TRAINING" = "true" ] && FLAGS="$FLAGS -DFEATURE_TRAINING"
    [ "$TOOLS" = "true" ] && FLAGS="$FLAGS -DFEATURE_TOOLS"
else
    echo "⚠️  jq 未安装，使用默认配置（所有功能启用）"
    FLAGS="-DFEATURE_DASHBOARD -DFEATURE_TRADING -DFEATURE_SOCIAL -DFEATURE_NEWS -DFEATURE_HEALTH -DFEATURE_PROJECT_HUB -DFEATURE_TRAINING -DFEATURE_TOOLS"
fi

echo "✅ 生成的编译器标志:"
echo "$FLAGS"

# 输出到环境变量文件（用于 CI）
if [ -n "$GITHUB_ENV" ]; then
    echo "FEATURE_FLAGS=$FLAGS" >> "$GITHUB_ENV"
fi

# 输出到 xcconfig 文件
XCCONFIG_FILE=".xcconfig/FeatureFlags.xcconfig"
mkdir -p "$(dirname "$XCCONFIG_FILE")"
cat > "$XCCONFIG_FILE" << EOF
// 自动生成的 Feature Flags 配置
// 来源: $CONFIG_FILE
// 生成时间: $(date)

OTHER_SWIFT_FLAGS = \$(inherited) $FLAGS
EOF

echo "📝 已写入: $XCCONFIG_FILE"
